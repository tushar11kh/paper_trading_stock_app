import { gql } from 'apollo-server';

export const stockTypeDef = gql`
  type Stock {
    name: String!
    symbol: String!
    price: Float!
  }

  type Subscription {
  priceUpdate(symbol: String!): Stock!
}

  type Query {
    getStock(symbol: String!): Stock
    getAllStocks: [Stock!]!
  }
`;
