# Paper Trading Stock App - System Architecture & Flow

## 1. System Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  Stock Price    │     │  GraphQL        │     │  PostgreSQL     │
│  API Service    │◄────┤  Server         │◄────┤  Database       │
│                 │     │                 │     │                 │
└─────────────────┘     └────────┬────────┘     └─────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │                 │
                        │  WebSocket      │
                        │  Server         │
                        │                 │
                        └─────────────────┘
```

## 2. Core Components & Their Interactions

### 2.1 Database Layer
```
┌─────────────────────────────────────────────────┐
│                  PostgreSQL                     │
├─────────────────┬─────────────────┬────────────┤
│     Users       │     Stocks      │  Orders    │
├─────────────────┼─────────────────┼────────────┤
│ - User accounts │ - Stock metadata│ - Trading  │
│ - Balances      │ - Symbols       │  orders    │
│ - Credentials   │ - Names         │ - Status   │
└─────────────────┴─────────────────┴────────────┘
```

**Key Tables:**
1. **Users**: Stores user accounts, balances, and authentication data
2. **Stocks**: Contains stock metadata (symbols, names, active status)
3. **Stock Prices**: Historical and current price data
4. **Orders**: Trading orders (market/limit, buy/sell)
5. **Trades**: Executed trades
6. **Portfolios**: User holdings and performance

### 2.2 GraphQL Layer
```
┌─────────────────────────────────────────────────┐
│                GraphQL Server                   │
├─────────────────┬─────────────────┬────────────┤
│   Queries       │  Mutations      │Subscriptions│
├─────────────────┼─────────────────┼────────────┤
│ - Get stock     │ - Place order   │- Price     │
│ - Get portfolio │ - Cancel order  │ updates    │
│ - Get orders    │ - Register      │            │
└─────────────────┴─────────────────┴────────────┘
```

**Key Operations:**
1. **Queries**:
   - Fetch stock data
   - Get user portfolio
   - View pending orders
   - Check account balance

2. **Mutations**:
   - Place trading orders
   - Cancel orders
   - User registration/login

3. **Subscriptions**:
   - Real-time price updates
   - Order status changes
   - Portfolio value updates

### 2.3 Real-time Layer
```
┌─────────────────────────────────────────────────┐
│                WebSocket Server                 │
├─────────────────┬─────────────────┬────────────┤
│  Price Updates  │  Order Updates  │Portfolio   │
├─────────────────┼─────────────────┼────────────┤
│ - Stock prices  │ - Order status  │- Value     │
│ - Market data   │ - Trade events  │changes     │
└─────────────────┴─────────────────┴────────────┘
```

## 3. System Flow

### 3.1 User Authentication Flow
```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│         │     │         │     │         │     │         │
│  User   │────►│  Login  │────►│  JWT    │────►│  Access │
│         │     │         │     │  Token  │     │         │
└─────────┘     └─────────┘     └─────────┘     └─────────┘
```

1. User provides credentials
2. System validates and generates JWT
3. Token used for subsequent requests
4. Protected routes verify token

### 3.2 Trading Flow
```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│         │     │         │     │         │     │         │
│  Place  │────►│  Order  │────►│  Order  │────►│  Update │
│  Order  │     │ Matching│     │ Execute │     │Portfolio│
└─────────┘     └─────────┘     └─────────┘     └─────────┘
```

1. User places order
2. Order matching service processes
3. Trade execution
4. Portfolio and balance updates

### 3.3 Price Update Flow
```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│         │     │         │     │         │     │         │
│  Price  │────►│  Store  │────►│  Publish│────►│  Client │
│  Fetch  │     │  Price  │     │  Update │     │ Update  │
└─────────┘     └─────────┘     └─────────┘     └─────────┘
```

1. Price service fetches data
2. Prices stored in database
3. Updates published via WebSocket
4. Clients receive real-time updates

## 4. Key Features & Their Implementation

### 4.1 Real-time Trading
- WebSocket connections for live updates
- Order matching engine for trade execution
- Portfolio value calculations
- P&L tracking

### 4.2 Security
- JWT-based authentication
- Password hashing
- Protected routes
- Input validation

### 4.3 Performance
- Database indexing
- Connection pooling
- Caching strategies
- Efficient queries

## 5. Data Flow Architecture

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│         │     │         │     │         │     │         │
│  Client │────►│GraphQL  │────►│Services │────►│Database │
│         │     │ Server  │     │         │     │         │
└─────────┘     └─────────┘     └─────────┘     └─────────┘
      ▲              ▲               ▲               ▲
      │              │               │               │
      │              │               │               │
      ▼              ▼               ▼               ▼
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│         │     │         │     │         │     │         │
│WebSocket│     │Auth     │     │Order    │     │Stock    │
│Server   │     │Service  │     │Matching │     │Service  │
└─────────┘     └─────────┘     └─────────┘     └─────────┘
```

## 6. System Scalability

### 6.1 Horizontal Scaling
- Multiple GraphQL servers
- Load balancing
- Database replication
- WebSocket clustering

### 6.2 Performance Optimization
- Query optimization
- Caching strategies
- Connection pooling
- Batch processing

This architecture provides:
1. Real-time trading capabilities
2. Secure user authentication
3. Efficient data management
4. Scalable infrastructure
5. Reliable order execution

### Flutter architecture

graph TD
UI[Widgets / Screens] -->|interact with| Provider[Riverpod Providers]
Provider -->|fetch from| Service[API/DB/Auth Service]
Service -->|return data| Model[Typed Models]
Model --> Provider --> UI


