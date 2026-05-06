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


// Schema migrations (safe to run every startup)
pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user'`).catch(console.error);
pool.query(`
    CREATE TABLE IF NOT EXISTS holdings (
        id           SERIAL PRIMARY KEY,
        user_id      UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        symbol       VARCHAR(20)   NOT NULL,
        name         VARCHAR(100),
        quantity     DECIMAL(18,8) NOT NULL DEFAULT 0,
        average_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
        created_at   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
        updated_at   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, symbol)
    )
`).catch(console.error);
pool.query(`
    CREATE TABLE IF NOT EXISTS tracked_stocks (
        id          SERIAL PRIMARY KEY,
        user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        symbol      VARCHAR(20) NOT NULL,
        name        VARCHAR(100),
        added_at    TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, symbol)
    )
`).catch(console.error);

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



// ==========================================================================
// BIST STOCK LIST — fetched once at startup, searched locally (0 credits)
// ==========================================================================
let _bistList = []; // [{ symbol, name }]

(async () => {
    try {
        const key = process.env.TWELVE_DATA_KEY;
        const data = await fetch(
            `https://api.twelvedata.com/stocks?exchange=BIST&apikey=${key}`
        ).then(r => r.json());
        _bistList = (data.data || []).map(s => ({ symbol: s.symbol, name: s.name }));
        console.log(`BIST list loaded: ${_bistList.length} stocks`);
    } catch (e) {
        console.error('Failed to load BIST stock list:', e.message);
    }
})();

// ==========================================================================
// UNIFIED MARKET CACHE — one Twelve Data call covers forex + all stocks
// TTL: 5 min. Promise-dedup prevents concurrent refreshes.
// ==========================================================================
const POPULAR_SYMBOLS = {
    THYAO: 'Türk Hava Yolları',   GARAN: 'Garanti BBVA',
    AKBNK: 'Akbank',               EREGL: 'Ereğli Demir Çelik',
    SISE:  'Şişecam',              ASELS: 'Aselsan',
    KCHOL: 'Koç Holding',          TUPRS: 'Tüpraş',
    BIMAS: 'BİM Mağazalar',        SAHOL: 'Sabancı Holding',
    PETKM: 'Petkim',               ARCLK: 'Arçelik',
    TOASO: 'Tofaş Oto',            FROTO: 'Ford Otosan',
    PGSUS: 'Pegasus',              EKGYO: 'Emlak Konut',
    YKBNK: 'Yapı Kredi',           VAKBN: 'Vakıfbank',
    HALKB: 'Halkbank',             ISCTR: 'İş Bankası',
    KOZAL: 'Koza Altın',           KRDMD: 'Kardemir',
    TAVHL: 'TAV Havalimanları',    TCELL: 'Turkcell',
    TTKOM: 'Türk Telekom',         SOKM:  'Şok Marketler',
    MAVI:  'Mavi Giyim',           LOGO:  'Logo Yazılım',
    ODAS:  'Odaş Elektrik',        MGROS: 'Migros',
};

const CACHE_TTL = 5 * 60_000;
let _cache    = null;   // { market: [], stocks: {} }
let _cacheAt  = 0;
let _fetching = null;   // deduplicates concurrent refreshes

async function yahooQuote(symbol) {
    try {
        const res = await fetch(
            `https://query1.finance.yahoo.com/v8/finance/chart/${symbol}?interval=1d&range=1d`,
            { headers: { 'User-Agent': 'Mozilla/5.0' } }
        );
        const meta = (await res.json())?.chart?.result?.[0]?.meta;
        if (!meta?.regularMarketPrice) return null;
        return { price: meta.regularMarketPrice, prev: meta.chartPreviousClose || meta.regularMarketPrice };
    } catch { return null; }
}

async function refreshCache() {
    const now = Date.now();
    if (_cache && now - _cacheAt < CACHE_TTL) return;
    if (_fetching) { await _fetching; return; }

    _fetching = (async () => {
        const trackedRows = await pool.query('SELECT DISTINCT symbol FROM tracked_stocks');
        const stockSyms = [...new Set([
            ...Object.keys(POPULAR_SYMBOLS),
            ...trackedRows.rows.map(r => r.symbol),
        ])];

        // Fetch everything in parallel — no API key, no rate limits
        const [usdQ, eurQ, goldQ, silverQ, ...stockQuotes] = await Promise.all([
            yahooQuote('USDTRY=X'),
            yahooQuote('EURTRY=X'),
            yahooQuote('GC=F'),
            yahooQuote('SI=F'),
            ...stockSyms.map(s => yahooQuote(`${s}.IS`)),
        ]);

        const updatedAt = new Date().toISOString();
        const market = [];

        if (usdQ) market.push({ symbol: 'USD', name: 'Dolar',
            buy_price:  +(usdQ.price * 1.003).toFixed(4),
            sell_price: +(usdQ.price * 0.997).toFixed(4),
            change_percent: +((usdQ.price - usdQ.prev) / usdQ.prev * 100).toFixed(3),
            updated_at: updatedAt });

        if (eurQ) market.push({ symbol: 'EUR', name: 'Euro',
            buy_price:  +(eurQ.price * 1.003).toFixed(4),
            sell_price: +(eurQ.price * 0.997).toFixed(4),
            change_percent: +((eurQ.price - eurQ.prev) / eurQ.prev * 100).toFixed(3),
            updated_at: updatedAt });

        const usdTry = usdQ?.price ?? 0;
        if (goldQ && usdTry > 0) {
            const g = goldQ.price * usdTry / 31.1035;
            market.push({ symbol: 'GOLD_GR', name: 'Gram Altın',
                buy_price:  +(g * 1.01).toFixed(2),
                sell_price: +(g * 0.99).toFixed(2),
                change_percent: +((goldQ.price - goldQ.prev) / goldQ.prev * 100).toFixed(3),
                updated_at: updatedAt });
        }
        if (silverQ && usdTry > 0) {
            const g = silverQ.price * usdTry / 31.1035;
            market.push({ symbol: 'SILVER_GR', name: 'Gram Gümüş',
                buy_price:  +(g * 1.01).toFixed(2),
                sell_price: +(g * 0.99).toFixed(2),
                change_percent: +((silverQ.price - silverQ.prev) / silverQ.prev * 100).toFixed(3),
                updated_at: updatedAt });
        }

        const stocks = {};
        stockSyms.forEach((sym, i) => {
            const q = stockQuotes[i];
            if (!q) return;
            stocks[sym] = { symbol: sym,
                name: POPULAR_SYMBOLS[sym] || sym,
                buy_price:  +(q.price * 1.001).toFixed(2),
                sell_price: +(q.price * 0.999).toFixed(2),
                change_percent: +((q.price - q.prev) / q.prev * 100).toFixed(3),
                updated_at: updatedAt };
        });

        _cache   = { market, stocks };
        _cacheAt = Date.now();
    })().finally(() => { _fetching = null; });

    await _fetching;
}

// Convenience getters
async function getMarketRates()  { await refreshCache(); return _cache?.market ?? []; }
async function getStockCache()   { await refreshCache(); return _cache?.stocks ?? {}; }

app.get('/api/market/rates', authenticateToken, async (req, res) => {
    try { res.json(await getMarketRates()); }
    catch (err) { console.error(err); res.status(500).json({ error: 'Could not fetch market rates' }); }
});

// GET /api/stocks/popular
app.get('/api/stocks/popular', authenticateToken, async (req, res) => {
    try {
        const stocks = await getStockCache();
        const now = new Date().toISOString();
        res.json(Object.entries(POPULAR_SYMBOLS).map(([sym, name]) =>
            stocks[sym] ?? { symbol: sym, name, buy_price: 0, sell_price: 0, change_percent: 0, updated_at: now }
        ));
    } catch (err) { console.error(err); res.status(500).json({ error: 'Could not fetch popular stocks' }); }
});

// GET /api/stocks/tracked
app.get('/api/stocks/tracked', authenticateToken, async (req, res) => {
    const userId = req.user.userId;
    try {
        const stocks = await getStockCache();
        const { rows } = await pool.query(
            'SELECT symbol, name FROM tracked_stocks WHERE user_id = $1 ORDER BY added_at',
            [userId]
        );
        const now = new Date().toISOString();
        res.json(rows.map(r =>
            stocks[r.symbol] ?? { symbol: r.symbol, name: r.name, buy_price: 0, sell_price: 0, change_percent: 0, updated_at: now }
        ));
    } catch (err) { console.error(err); res.status(500).json({ error: 'Could not fetch tracked stocks' }); }
});

// POST /api/stocks/track  body: { symbol, name }
app.post('/api/stocks/track', authenticateToken, async (req, res) => {
    const userId = req.user.userId;
    const { symbol, name } = req.body;
    if (!symbol) return res.status(400).json({ error: 'symbol required' });
    try {
        await pool.query(
            'INSERT INTO tracked_stocks (user_id, symbol, name) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING',
            [userId, symbol.toUpperCase(), name || symbol]
        );
        _cacheAt = 0; // bust cache so next /tracked call fetches price for newly tracked symbol
        res.json({ success: true });
    } catch (err) { console.error(err); res.status(500).json({ error: 'Could not track stock' }); }
});

// DELETE /api/stocks/track/:symbol
app.delete('/api/stocks/track/:symbol', authenticateToken, async (req, res) => {
    const userId = req.user.userId;
    try {
        await pool.query(
            'DELETE FROM tracked_stocks WHERE user_id = $1 AND symbol = $2',
            [userId, req.params.symbol.toUpperCase()]
        );
        res.json({ success: true });
    } catch (err) { console.error(err); res.status(500).json({ error: 'Could not untrack stock' }); }
});

// GET /api/stocks/search?q=   — local search, zero Twelve Data credits
app.get('/api/stocks/search', authenticateToken, (req, res) => {
    const q = (req.query.q || '').trim().toUpperCase();
    if (q.length < 2) return res.json([]);
    const results = _bistList
        .filter(s => s.symbol.includes(q) || s.name.toUpperCase().includes(q))
        .slice(0, 15);
    res.json(results);
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

// ==========================================================================
// PORTFOLIO & TRADING
// ==========================================================================

// GET /api/portfolio/holdings
app.get('/api/portfolio/holdings', authenticateToken, async (req, res) => {
    const userId = req.user.userId;
    try {
        const { rows } = await pool.query(
            'SELECT * FROM holdings WHERE user_id = $1 AND quantity > 0.00000001 ORDER BY created_at',
            [userId]
        );
        const stocks = await getStockCache();
        const market = await getMarketRates();
        const result = rows.map(h => {
            const s = stocks[h.symbol];
            const m = market.find(r => r.symbol === h.symbol);
            const current_price = s?.sell_price || m?.sell_price || 0;
            return {
                symbol: h.symbol,
                name: h.name,
                quantity: parseFloat(h.quantity),
                average_cost: parseFloat(h.average_cost),
                current_price,
            };
        });
        res.json(result);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Could not fetch holdings' });
    }
});

// POST /api/trade/buy  body: { symbol, amount_tl }
app.post('/api/trade/buy', authenticateToken, async (req, res) => {
    const userId = req.user.userId;
    const { symbol, amount_tl } = req.body;
    if (!symbol || !amount_tl || amount_tl <= 0)
        return res.status(400).json({ error: 'symbol ve amount_tl zorunlu' });

    const sym = symbol.toUpperCase();
    const stocks = await getStockCache();
    const market = await getMarketRates();
    const price = stocks[sym]?.sell_price || market.find(r => r.symbol === sym)?.sell_price;
    if (!price || price <= 0)
        return res.status(400).json({ error: 'Fiyat verisi alınamadı' });

    const name = stocks[sym]?.name || market.find(r => r.symbol === sym)?.name || sym;
    const quantity = amount_tl / price;

    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        const walletRes = await client.query(
            `SELECT wallet_id, balance FROM wallets WHERE owner_id = $1 AND wallet_type = 'TL' FOR UPDATE`,
            [userId]
        );
        if (!walletRes.rows.length) throw new Error('Cüzdan bulunamadı');
        const { wallet_id, balance } = walletRes.rows[0];
        if (parseFloat(balance) < amount_tl) throw new Error('Yetersiz bakiye');

        await client.query(
            'UPDATE wallets SET balance = balance - $1 WHERE wallet_id = $2',
            [amount_tl, wallet_id]
        );
        await client.query(`
            INSERT INTO holdings (user_id, symbol, name, quantity, average_cost)
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (user_id, symbol) DO UPDATE SET
                average_cost = (holdings.quantity * holdings.average_cost + $4 * $5)
                               / (holdings.quantity + $4),
                quantity     = holdings.quantity + $4,
                updated_at   = NOW()
        `, [userId, sym, name, quantity, price]);
        await client.query(
            `INSERT INTO transactions (sender_id, sender_wallet_id, amount, description, type, status)
             VALUES ($1, $2, $3, $4, 'TRADE_BUY', 'SUCCESS')`,
            [userId, wallet_id, amount_tl, `${sym} alış – ${quantity.toFixed(4)} adet @ ₺${price}`]
        );
        await client.query('COMMIT');

        pool.query(
            `INSERT INTO activities (owner_id, type, description) VALUES ($1, 'TRADE_BUY', $2)`,
            [userId, `${sym} alış – ${quantity.toFixed(4)} adet @ ₺${price}`]
        ).catch(() => {});

        res.json({ success: true, quantity, price });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error(err);
        res.status(400).json({ error: err.message });
    } finally {
        client.release();
    }
});

// POST /api/trade/sell  body: { symbol, quantity }
app.post('/api/trade/sell', authenticateToken, async (req, res) => {
    const userId = req.user.userId;
    const { symbol, quantity } = req.body;
    if (!symbol || !quantity || quantity <= 0)
        return res.status(400).json({ error: 'symbol ve quantity zorunlu' });

    const sym = symbol.toUpperCase();
    const stocks = await getStockCache();
    const market = await getMarketRates();
    const price = stocks[sym]?.buy_price || market.find(r => r.symbol === sym)?.buy_price;
    if (!price || price <= 0)
        return res.status(400).json({ error: 'Fiyat verisi alınamadı' });

    const proceeds = quantity * price;

    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        const holdingRes = await client.query(
            'SELECT id, quantity FROM holdings WHERE user_id = $1 AND symbol = $2 FOR UPDATE',
            [userId, sym]
        );
        if (!holdingRes.rows.length) throw new Error('Bu varlık portföyünüzde yok');
        const holding = holdingRes.rows[0];
        if (parseFloat(holding.quantity) < quantity - 0.000001)
            throw new Error('Yetersiz miktar');

        const newQty = parseFloat(holding.quantity) - quantity;
        if (newQty <= 0.000001) {
            await client.query('DELETE FROM holdings WHERE id = $1', [holding.id]);
        } else {
            await client.query(
                'UPDATE holdings SET quantity = $1, updated_at = NOW() WHERE id = $2',
                [newQty, holding.id]
            );
        }

        const walletRes = await client.query(
            `SELECT wallet_id FROM wallets WHERE owner_id = $1 AND wallet_type = 'TL'`,
            [userId]
        );
        if (!walletRes.rows.length) throw new Error('Cüzdan bulunamadı');
        const sellWalletId = walletRes.rows[0].wallet_id;
        await client.query(
            'UPDATE wallets SET balance = balance + $1 WHERE wallet_id = $2',
            [proceeds, sellWalletId]
        );
        await client.query(
            `INSERT INTO transactions (receiver_id, receiver_wallet_id, amount, description, type, status)
             VALUES ($1, $2, $3, $4, 'TRADE_SELL', 'SUCCESS')`,
            [userId, sellWalletId, proceeds, `${sym} satış – ${quantity} adet @ ₺${price}`]
        );
        await client.query('COMMIT');

        pool.query(
            `INSERT INTO activities (owner_id, type, description) VALUES ($1, 'TRADE_SELL', $2)`,
            [userId, `${sym} satış – ${quantity} adet @ ₺${price}`]
        ).catch(() => {});

        res.json({ success: true, proceeds, price });
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