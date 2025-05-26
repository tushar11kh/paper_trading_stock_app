import { gql } from 'apollo-server';

export const stockTypeDef = gql`
  type Stock {
    id: ID!
    name: String!
    symbol: String!
    price: Float!
    isActive: Boolean!
  }

  type StockHistory {
    timestamp: String!
    open: Float!
    high: Float!
    low: Float!
    close: Float!
  }

  type Portfolio {
    stock: Stock!
    quantity: Int!
    averagePrice: Float!
    currentValue: Float!
    profitLoss: Float!
  }

  type Order {
    id: ID!
    stock: Stock!
    quantity: Int!
    price: Float!
    orderType: String!
    status: String!
    createdAt: String!
  }

  input PlaceOrderInput {
    symbol: String!
    quantity: Int!
    price: Float  # Make price optional for market orders
    orderType: String!  # "MARKET" or "LIMIT"
    side: String!  # "BUY" or "SELL"
  }

  type Subscription {
    priceUpdate(symbol: String!): Stock!
  }

  type Query {
    getStock(symbol: String!): Stock
    getStockHistory(symbol: String!, timeframe: String!): [StockHistory!]!
    getPortfolio(userId: ID!): [Portfolio!]!
    getPendingOrders: [Order!]!
    getHistoricalPrices(stockId: ID!): [StockPrice!]!
    getStockIdBySymbol(symbol: String!): ID!
    getAllStocks: [Stock!]!
  }

  type StockPrice {
    timestamp: String!
    price: Float!
  }

  type Mutation {
    placeOrder(input: PlaceOrderInput!): Order!
    cancelOrder(orderId: ID!): Order!
  }
`;
