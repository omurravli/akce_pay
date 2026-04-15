require('dotenv').config();
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Database Connection (Matching your Docker Compose)
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
});


const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Extract token from "Bearer <token>"

    if (!token) return res.sendStatus(401); // No token? Unauthorized.

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) return res.sendStatus(403); // Bad token? Forbidden.
        req.user = user; // Add the user data (including userId) to the request object
        next(); // Move to the actual wallet logic
    });
};

// --- REGISTER ---
// Handles UUID generation automatically in Postgres
app.post('/auth/register', async (req, res) => {
    const { username, email, password, age, telephoneno } = req.body;

    try {
        const hashedPassword = await bcrypt.hash(password, 10);

        // Inserting into 'users' table using schema names
        const result = await pool.query(
            `INSERT INTO users (username, email, passwd, age, telephoneno) 
             VALUES ($1, $2, $3, $4, $5) 
             RETURNING id, username, email`,
            [username, email, hashedPassword, age, telephoneno]
        );

        const newUser = result.rows[0];

        // Automatically create a default wallet for the new user
        const ibanPlaceholder = 'TR' + Math.random().toString().slice(2, 18); // Simple random IBAN generator
        await pool.query(
            'INSERT INTO wallets (owner_id, iban, wallet_type, balance) VALUES ($1, $2, $3, $4)',
            [newUser.id, ibanPlaceholder, 'TL', 0.0]
        );



        // Audit Log: Activity Type 'REGISTER' (from our Enum)
        await pool.query(
            "INSERT INTO activities (owner_id, type, description, ip) VALUES ($1, 'REGISTER', $2, $3)",
            [newUser.id, 'Account created via mobile app', req.ip]
        );
        // Log the activity
        await pool.query(
            "INSERT INTO activities (owner_id, type, description, ip) VALUES ($1, 'WALLET_CREATE', $2, $3)",
            [newUser.id, 'User registered and default wallet created', req.ip]
        );
        res.status(201).json(newUser);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Registration failed. Email or Username may already exist." });
    }
});

// --- LOGIN ---
app.post('/auth/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        // Fetch user based on 'email'
        const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

        if (userResult.rows.length === 0) {
            return res.status(401).json({ error: "Invalid email or password" });
        }

        const user = userResult.rows[0];

        // Compare bcrypt hash with 'passwd' column from your schema
        const isMatch = await bcrypt.compare(password, user.passwd);

        if (!isMatch) {
            await pool.query(
                "INSERT INTO activities (owner_id, type, description, ip) VALUES ($1, 'UNSUCCESFULL_LOGIN', $2, $3)",
                [user.id, 'Invalid e-mail or password', req.ip]
            );
            return res.status(401).json({ error: "Invalid email or password" });
        }

        // Generate JWT for Flutter
        const token = jwt.sign(
            { userId: user.id, username: user.username },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        // Audit Log: Activity Type 'LOGIN'
        await pool.query(
            "INSERT INTO activities (owner_id, type, description, ip) VALUES ($1, 'LOGIN', $2, $3)",
            [user.id, 'Successful login', req.ip]
        );

        res.json({
            token,
            user: { id: user.id, username: user.username, email: user.email }
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Internal server error" });
    }
});

app.get('/api/wallets', authenticateToken, async (req, res) => {
    // Instead of getting it from the query, we get it from the secure token!
    const userIdFromToken = req.user.userId;

    try {
        const result = await pool.query(
            'SELECT * FROM wallets WHERE owner_id = $1',
            [userIdFromToken]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: "Could not fetch wallets" });
    }
});

// --- LOAD BALANCE ---
app.patch('/api/wallets/load', authenticateToken, async (req, res) => {
    const { wallet_id, amount, description } = req.body;
    const userIdFromToken = req.user.userId;

    if (!amount || amount <= 0) {
        return res.status(400).json({ error: "Invalid amount." });
    }

    // Start a SQL Transaction to ensure both balance update and log happen together
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // 1. Update Wallet Balance
        const updateRes = await client.query(
            'UPDATE wallets SET balance = balance + $1 WHERE wallet_id = $2 AND owner_id = $3 RETURNING *',
            [amount, wallet_id, userIdFromToken]
        );

        if (updateRes.rows.length === 0) {
            throw new Error("Wallet not found or unauthorized");
        }

        // 2. Create the Transaction Record (Load Balance)
        // sender_id and sender_wallet_id are NULL because this is an external deposit
        await client.query(
            `INSERT INTO transactions 
            (receiver_id, receiver_wallet_id, amount, description) 
            VALUES ($1, $2, $3, $4)`,
            [userIdFromToken, wallet_id, amount, description || 'Balance Load']
        );

        await client.query('COMMIT');
        res.json({ message: "Deposit successful", new_balance: updateRes.rows[0].balance });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error(err);
        res.status(500).json({ error: err.message || "Transaction failed" });
    } finally {
        client.release();
    }
});

// --- SEND MONEY (TRANSFER) ---
// --- SEND MONEY (TRANSFER) ---
app.post('/api/transactions/send', authenticateToken, async (req, res) => {
    const { sender_wallet_id, receiver_wallet_id, amount, description } = req.body;
    const senderIdFromToken = req.user.userId; // Securely identified by JWT

    if (!amount || amount <= 0) {
        return res.status(400).json({ error: "Invalid amount." });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // 1. Verify sender owns the wallet and has sufficient balance
        // We use 'FOR UPDATE' to lock the row during the transaction
        const senderWallet = await client.query(
            'SELECT balance, owner_id FROM wallets WHERE wallet_id = $1 FOR UPDATE',
            [sender_wallet_id]
        );

        if (senderWallet.rows.length === 0 || senderWallet.rows[0].owner_id !== senderIdFromToken) {
            throw new Error("Unauthorized or sender wallet not found.");
        }

        if (senderWallet.rows[0].balance < amount) {
            throw new Error("Insufficient balance.");
        }

        // 2. Verify receiver wallet exists and get their user ID
        const receiverWallet = await client.query(
            'SELECT owner_id FROM wallets WHERE wallet_id = $1',
            [receiver_wallet_id]
        );

        if (receiverWallet.rows.length === 0) {
            throw new Error("Receiver wallet does not exist.");
        }

        const receiverId = receiverWallet.rows[0].owner_id;

        // 3. Deduct from Sender
        await client.query(
            'UPDATE wallets SET balance = balance - $1 WHERE wallet_id = $2',
            [amount, sender_wallet_id]
        );

        // 4. Credit to Receiver
        await client.query(
            'UPDATE wallets SET balance = balance + $1 WHERE wallet_id = $2',
            [amount, receiver_wallet_id]
        );

        // 5. Record the Transaction (Matching your exact schema)
        const transactionResult = await client.query(
            `INSERT INTO transactions 
            (sender_id, receiver_id, sender_wallet_id, receiver_wallet_id, amount, description, type, status) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
            RETURNING *`,
            [
                senderIdFromToken,
                receiverId,
                sender_wallet_id,
                receiver_wallet_id,
                amount,
                description,
                'TRANSFER', // type column
                'SUCCESS'   // status column
            ]
        );

        await client.query('COMMIT');

        // Log to activities for audit as well
        await pool.query(
            "INSERT INTO activities (owner_id, type, description) VALUES ($1, 'TRANSFER', $2)",
            [senderIdFromToken, `Sent ${amount} to wallet ${receiver_wallet_id}`]
        );

        res.json({
            message: "Transfer completed successfully",
            transaction: transactionResult.rows[0]
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error(err);
        res.status(400).json({ error: err.message });
    } finally {
        client.release();
    }
});



// Mobile-Ready Listener: Listening on 0.0.0.0 allows network access
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Mobile API Backend running on port ${PORT}`);
    console.log(`🔗 Database: my_app_db | Table: users (UUID)`);
});