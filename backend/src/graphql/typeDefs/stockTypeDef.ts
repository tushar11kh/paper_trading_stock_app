//backend/src/graphql/typeDefs/stockTypeDef.ts
import { gql } from 'graphql-tag';
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
