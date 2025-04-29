import { gql } from 'apollo-server';

export const stockTypeDef = gql`
  type Stock {
    name: String!
    symbol: String!
    price: Float!
  }

  type Query {
    getStock(symbol: String!): Stock
    getAllStocks: [Stock!]!
  }
`;
