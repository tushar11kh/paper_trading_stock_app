--backend/src/db/migrations/schema.sql
-- 1. Users
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        -- Add any new columns or constraints here
        -- Example: ALTER TABLE users ADD COLUMN IF NOT EXISTS new_column TYPE;
    ELSE
        CREATE TABLE users (
            id SERIAL PRIMARY KEY,
            email VARCHAR(255) UNIQUE NOT NULL,
            password VARCHAR(255),
            balance NUMERIC DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    END IF;
END $$;

-- 2. Stocks (Static metadata + Historical prices)
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'stocks') THEN
        -- Add any new columns or constraints here
    ELSE
        CREATE TABLE stocks (
            id SERIAL PRIMARY KEY,
            symbol VARCHAR(10) UNIQUE NOT NULL,
            name VARCHAR(255) NOT NULL,
            is_active BOOLEAN DEFAULT true, -- true: available for trading, false: not available (delisted/suspended)
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    END IF;
END $$;

-- 3. Stock Prices (For charts and historical data)
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'stock_prices') THEN
        -- Add any new columns or constraints here
    ELSE
        CREATE TABLE stock_prices (
            id SERIAL PRIMARY KEY,
            stock_id INTEGER REFERENCES stocks(id),
            price NUMERIC NOT NULL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(stock_id, timestamp)
        );
    END IF;
END $$;

-- Drop existing orders table
DROP TABLE IF EXISTS orders CASCADE;

-- Recreate orders table with new constraints
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'orders') THEN
        -- Drop old constraint if it exists
        ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_order_type_check;
        
        -- Add new constraint
        ALTER TABLE orders 
        ADD CONSTRAINT orders_order_type_check 
        CHECK (order_type IN ('MARKET_BUY', 'MARKET_SELL', 'LIMIT_BUY', 'LIMIT_SELL'));
        
        -- Update column type if needed
        ALTER TABLE orders 
        ALTER COLUMN order_type TYPE VARCHAR(20);
    ELSE
        CREATE TABLE orders (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id),
            stock_id INTEGER REFERENCES stocks(id),
            quantity INTEGER NOT NULL,
            price NUMERIC NOT NULL,
            order_type VARCHAR(20) NOT NULL CHECK (order_type IN ('MARKET_BUY', 'MARKET_SELL', 'LIMIT_BUY', 'LIMIT_SELL')),
            status VARCHAR(10) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'FILLED', 'CANCELLED')),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    END IF;
END $$;

-- 5. Trades
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trades') THEN
        -- Add any new columns or constraints here
    ELSE
        CREATE TABLE trades (
            id SERIAL PRIMARY KEY,
            buy_order_id INTEGER REFERENCES orders(id),
            sell_order_id INTEGER REFERENCES orders(id),
            stock_id INTEGER REFERENCES stocks(id),
            quantity INTEGER NOT NULL,
            price NUMERIC NOT NULL,
            traded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    END IF;
END $$;

-- 6. Portfolios
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'portfolios') THEN
        -- Add unique constraint if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint 
            WHERE conname = 'portfolios_user_stock_unique'
        ) THEN
            ALTER TABLE portfolios 
            ADD CONSTRAINT portfolios_user_stock_unique 
            UNIQUE (user_id, stock_id);
        END IF;
    ELSE
        CREATE TABLE portfolios (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id),
            stock_id INTEGER REFERENCES stocks(id),
            quantity INTEGER DEFAULT 0,
            average_price NUMERIC DEFAULT 0,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, stock_id)
        );
    END IF;
END $$;