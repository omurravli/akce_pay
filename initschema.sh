#!/bin/bash

# Define the database name and user
DB_NAME="my_app_db"
DB_USER="user"

echo "🚀 Starting database schema initialization..."

# Execute all SQL in one block
docker exec -i $(docker ps -qf "name=db") psql -U $DB_USER -d $DB_NAME <<EOF
-- 1. Drop existing items if they exist (for a clean start)
DROP TABLE IF EXISTS activities;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS cards;
DROP TABLE IF EXISTS wallets;
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS activity_type;  

-- 2. Create Custom Enum for Activities
CREATE TYPE activity_type AS ENUM ('LOGIN', 'REGISTER', 'UPDATE', 'DELETE', 'TRANSFER', 'DEPOSIT', 'WALLET_CREATE');

-- 3. Create Users Table
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

-- 4. Create Wallets Table
CREATE TABLE wallets (
    wallet_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    iban VARCHAR(34) UNIQUE NOT NULL,
    wallet_type VARCHAR(50),
    balance DOUBLE PRECISION DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create Cards Table
CREATE TABLE cards (
    card_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_no VARCHAR(20) UNIQUE NOT NULL,
    wallet_id UUID REFERENCES wallets(wallet_id) ON DELETE CASCADE,
    cvv INTEGER,
    expiry_date VARCHAR(10),
    provider VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Create Transactions Table
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

-- 7. Create Activities Table (Audit Trail)
CREATE TABLE activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type activity_type NOT NULL,
    description VARCHAR(255),
    ip VARCHAR(45),
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

EOF

echo "✅ Schema built successfully!"
echo "📊 Current Tables:"
docker exec -it $(docker ps -qf "name=db") psql -U $DB_USER -d $DB_NAME -c "\dt"
