//backend/src/graphql/typeDefs/orderTypeDef.ts

import { gql } from 'graphql-tag';
export const orderTypeDef = gql`
  input PlaceOrderInput {
    userId: ID!
    stockSymbol: String!
    type: String!       # "BUY" or "SELL"
    quantity: Int!
    orderType: String!  # "MARKET" or "LIMIT"
    limitPrice: Float
  }

  type OrderResponse {
    success: Boolean!
    message: String!
  }

  type Mutation {
    placeOrder(input: PlaceOrderInput!): OrderResponse!
  }
`;
