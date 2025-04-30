import { gql } from 'apollo-server';

export const stockTypeDef = gql`
  type Stock {
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
    price: Float
    orderType: String!
  }

  type Subscription {
    priceUpdate(symbol: String!): Stock!
  }

  type Query {
    getStock(symbol: String!): Stock
    getStockHistory(symbol: String!, timeframe: String!): [StockHistory!]!
    getPortfolio(userId: ID!): [Portfolio!]!
  }

  type Mutation {
    placeOrder(input: PlaceOrderInput!): Order!
  }
`;
