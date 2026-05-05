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
    connectionString: process.env.DATABASE_URL?.replace('?sslmode=require', '').replace('&sslmode=require', ''),
    ssl: { rejectUnauthorized: false }
});


// Add role column if missing (safe to run every startup)
pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user'`).catch(console.error);

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.sendStatus(401);
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) return res.sendStatus(403);
        req.user = user;
        next();
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
                "INSERT INTO activities (owner_id, type, description, ip) VALUES ($1, 'UNSUCCESSFUL_LOGIN', $2, $3)",
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
            user: { id: user.id, username: user.username, email: user.email, role: user.role || 'user' }
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



// --- MARKET RATES (Twelve Data, cached 60s) ---
const STOCK_NAMES = {
    THYAO: 'Türk Hava Yolları',
    GARAN: 'Garanti BBVA',
    AKBNK: 'Akbank',
    EREGL: 'Ereğli Demir Çelik',
    SISE:  'Şişecam',
    ASELS: 'Aselsan',
    KCHOL: 'Koç Holding',
};

let _mktCache = null;
let _mktCacheAt = 0;

async function buildMarketRates() {
    const now = Date.now();
    if (_mktCache && now - _mktCacheAt < 60_000) return _mktCache;

    const key = process.env.TWELVE_DATA_KEY;
    const stockSym = Object.keys(STOCK_NAMES).join(',');

    const [stockData, fxData] = await Promise.all([
        fetch(`https://api.twelvedata.com/quote?symbol=${stockSym}&exchange=BIST&apikey=${key}`).then(r => r.json()),
        fetch(`https://api.twelvedata.com/quote?symbol=USD/TRY,EUR/TRY,XAU/USD,XAG/USD&apikey=${key}`).then(r => r.json()),
    ]);

    const result = [];
    const usdTry = parseFloat(fxData['USD/TRY']?.close ?? 0);

    // Currencies
    for (const [apiSym, displaySym, name] of [
        ['USD/TRY', 'USD', 'Dolar'],
        ['EUR/TRY', 'EUR', 'Euro'],
    ]) {
        const d = fxData[apiSym];
        if (!d?.close) continue;
        const price = parseFloat(d.close);
        const prev  = parseFloat(d.previous_close ?? d.close);
        result.push({
            symbol: displaySym,
            name,
            buy_price:      +(price * 1.003).toFixed(4),
            sell_price:     +(price * 0.997).toFixed(4),
            change_percent: prev > 0 ? +((price - prev) / prev * 100).toFixed(3) : 0,
            updated_at: new Date().toISOString(),
        });
    }

    // Gold (gram, TRY) — XAU/USD * USD/TRY / 31.1035 g per troy oz
    const xauUsd = parseFloat(fxData['XAU/USD']?.close ?? 0);
    if (xauUsd > 0 && usdTry > 0) {
        const gramTry = (xauUsd * usdTry) / 31.1035;
        const prev    = parseFloat(fxData['XAU/USD']?.previous_close ?? xauUsd);
        result.push({
            symbol: 'GOLD_GR',
            name: 'Gram Altın',
            buy_price:      +(gramTry * 1.01).toFixed(2),
            sell_price:     +(gramTry * 0.99).toFixed(2),
            change_percent: prev > 0 ? +((xauUsd - prev) / prev * 100).toFixed(3) : 0,
            updated_at: new Date().toISOString(),
        });
    }

    // Silver (gram, TRY)
    const xagUsd = parseFloat(fxData['XAG/USD']?.close ?? 0);
    if (xagUsd > 0 && usdTry > 0) {
        const gramTry = (xagUsd * usdTry) / 31.1035;
        const prev    = parseFloat(fxData['XAG/USD']?.previous_close ?? xagUsd);
        result.push({
            symbol: 'SILVER_GR',
            name: 'Gram Gümüş',
            buy_price:      +(gramTry * 1.01).toFixed(2),
            sell_price:     +(gramTry * 0.99).toFixed(2),
            change_percent: prev > 0 ? +((xagUsd - prev) / prev * 100).toFixed(3) : 0,
            updated_at: new Date().toISOString(),
        });
    }

    // BIST Stocks
    for (const [sym, name] of Object.entries(STOCK_NAMES)) {
        const d = stockData[sym];
        if (!d?.close) continue;
        const price = parseFloat(d.close);
        const prev  = parseFloat(d.previous_close ?? d.close);
        result.push({
            symbol: sym,
            name,
            buy_price:      +(price * 1.001).toFixed(2),
            sell_price:     +(price * 0.999).toFixed(2),
            change_percent: prev > 0 ? +((price - prev) / prev * 100).toFixed(3) : 0,
            updated_at: new Date().toISOString(),
        });
    }

    _mktCache = result;
    _mktCacheAt = now;
    return result;
}

app.get('/api/market/rates', authenticateToken, async (req, res) => {
    try {
        const data = await buildMarketRates();
        res.json(data);
    } catch (err) {
        console.error('Market rates error:', err);
        res.status(500).json({ error: 'Could not fetch market rates' });
    }
});

// --- GET TRANSACTIONS ---
app.get('/api/transactions', authenticateToken, async (req, res) => {
    const userId = req.user.userId;
    try {
        const result = await pool.query(
            `SELECT * FROM transactions
             WHERE sender_id = $1 OR receiver_id = $1
             ORDER BY date DESC
             LIMIT 50`,
            [userId]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Could not fetch transactions" });
    }
});

// --- GET ACTIVITIES (AUDIT LOG) ---
app.get('/api/activities', authenticateToken, async (req, res) => {
    const userId = req.user.userId;
    try {
        const result = await pool.query(
            `SELECT * FROM activities
             WHERE owner_id = $1
             ORDER BY date DESC
             LIMIT 50`,
            [userId]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Could not fetch activities" });
    }
});

// --- SEARCH USERS (for send money contacts) ---
app.get('/api/users/search', authenticateToken, async (req, res) => {
    const { q } = req.query;
    const currentUserId = req.user.userId;
    try {
        const result = await pool.query(
            `SELECT u.id, u.username, u.email, w.wallet_id, w.iban
             FROM users u
             LEFT JOIN wallets w ON w.owner_id = u.id AND w.wallet_type = 'TL'
             WHERE u.id != $1
               AND (u.username ILIKE $2 OR u.email ILIKE $2 OR w.iban ILIKE $2)
             ORDER BY u.username
             LIMIT 20`,
            [currentUserId, `%${q || ''}%`]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Search failed' });
    }
});

// --- ADMIN: STATS ---
app.get('/api/admin/stats', authenticateToken, async (req, res) => {
    try {
        const [users, txns, vol] = await Promise.all([
            pool.query(`SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE status = 'active') AS active FROM users`),
            pool.query(`SELECT COUNT(*) AS total, COALESCE(SUM(amount), 0) AS volume FROM transactions`),
        ]);
        res.json({
            total_users: parseInt(users.rows[0].total),
            active_users: parseInt(users.rows[0].active),
            total_transactions: parseInt(txns.rows[0].total),
            total_volume: parseFloat(txns.rows[0].volume),
            total_cashback_paid: 0,
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Could not fetch stats' });
    }
});

// --- ADMIN: USER LIST ---
app.get('/api/admin/users', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT u.id, u.username, u.email, u.role, u.status,
                   COALESCE(SUM(w.balance), 0) AS total_balance
            FROM users u
            LEFT JOIN wallets w ON w.owner_id = u.id
            GROUP BY u.id
            ORDER BY u.created_at DESC
        `);
        const rows = result.rows.map(r => ({
            id: r.id,
            username: r.username,
            email: r.email,
            role: r.role || 'user',
            total_balance: parseFloat(r.total_balance),
            is_active: r.status !== 'suspended',
        }));
        res.json(rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Could not fetch users' });
    }
});

// --- ADMIN: USER TRANSACTIONS ---
app.get('/api/admin/users/:id/transactions', authenticateToken, async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query(
            `SELECT * FROM transactions
             WHERE sender_id = $1 OR receiver_id = $1
             ORDER BY date DESC LIMIT 100`,
            [id]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Could not fetch user transactions' });
    }
});

// --- ADMIN: UPDATE USER ---
app.patch('/api/admin/users/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { is_active, role } = req.body;
    try {
        const updates = [];
        const values = [];
        let idx = 1;
        if (is_active !== undefined) {
            updates.push(`status = $${idx++}`);
            values.push(is_active ? 'active' : 'suspended');
        }
        if (role !== undefined) {
            updates.push(`role = $${idx++}`);
            values.push(role);
        }
        if (updates.length === 0) return res.status(400).json({ error: 'Nothing to update' });
        values.push(id);
        await pool.query(`UPDATE users SET ${updates.join(', ')} WHERE id = $${idx}`, values);
        res.json({ success: true });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Update failed' });
    }
});

// Mobile-Ready Listener: Listening on 0.0.0.0 allows network access
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Mobile API Backend running on port ${PORT}`);
    console.log(`🔗 Database: my_app_db | Table: users (UUID)`);
});