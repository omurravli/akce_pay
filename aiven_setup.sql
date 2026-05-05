-- 1. Reset (Optional: Use only if you want to wipe the cloud DB)
DROP TABLE IF EXISTS activities CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS cards CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TYPE IF EXISTS activity_type CASCADE;

-- 2. Create Types
CREATE TYPE activity_type AS ENUM ('LOGIN', 'UNSUCCESSFUL_LOGIN', 'REGISTER', 'UPDATE', 'DELETE', 'TRANSFER', 'DEPOSIT', 'WALLET_CREATE');

-- 3. Create Tables
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    passwd VARCHAR(255) NOT NULL,
    age INTEGER,
    telephoneno VARCHAR(20),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE wallets (
    wallet_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    iban VARCHAR(34) UNIQUE NOT NULL,
    wallet_type VARCHAR(50),
    balance DOUBLE PRECISION DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cards (
    card_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_no VARCHAR(20) UNIQUE NOT NULL,
    wallet_id UUID REFERENCES wallets(wallet_id) ON DELETE CASCADE,
    cvv INTEGER,
    expiry_date VARCHAR(10),
    provider VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES users(id),
    receiver_id UUID REFERENCES users(id),
    sender_wallet_id UUID REFERENCES wallets(wallet_id),
    receiver_wallet_id UUID REFERENCES wallets(wallet_id),
    amount DOUBLE PRECISION NOT NULL,
    description VARCHAR(255),
    type VARCHAR(50),
    status VARCHAR(50),
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type activity_type NOT NULL,
    description VARCHAR(255),
    ip VARCHAR(45),
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);