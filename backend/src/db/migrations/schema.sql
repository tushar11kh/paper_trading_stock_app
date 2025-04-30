--backend/src/db/migrations/schema.sql
-- 1. Users
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255),
  balance NUMERIC DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Stocks (Static metadata + Historical prices)
CREATE TABLE IF NOT EXISTS stocks (
  id SERIAL PRIMARY KEY,
  symbol VARCHAR(10) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT true, -- true: available for trading, false: not available (delisted/suspended)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Stock Prices (For charts and historical data)
CREATE TABLE IF NOT EXISTS stock_prices (
  id SERIAL PRIMARY KEY,
  stock_id INTEGER REFERENCES stocks(id),
  price NUMERIC NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(stock_id, timestamp)
);

-- 4. Orders
CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  stock_id INTEGER REFERENCES stocks(id),
  quantity INTEGER NOT NULL,
  price NUMERIC NOT NULL,
  order_type VARCHAR(10) NOT NULL CHECK (order_type IN ('BUY', 'SELL')),
  status VARCHAR(10) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'FILLED', 'CANCELLED')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Trades
CREATE TABLE IF NOT EXISTS trades (
  id SERIAL PRIMARY KEY,
  buy_order_id INTEGER REFERENCES orders(id),
  sell_order_id INTEGER REFERENCES orders(id),
  stock_id INTEGER REFERENCES stocks(id),
  quantity INTEGER NOT NULL,
  price NUMERIC NOT NULL,
  traded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Portfolios
CREATE TABLE IF NOT EXISTS portfolios (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  stock_id INTEGER REFERENCES stocks(id),
  quantity INTEGER DEFAULT 0,
  average_price NUMERIC DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);