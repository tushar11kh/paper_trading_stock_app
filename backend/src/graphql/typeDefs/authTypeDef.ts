import { gql } from 'apollo-server';

export const authTypeDef = gql`
  type AuthPayload {
    token: String!
    user: User!
  }

  type User {
    id: ID!
    email: String!
    balance: Float!
  }

  input RegisterInput {
    email: String!
    password: String!
  }

  input LoginInput {
    email: String!
    password: String!
  }

  type Mutation {
    register(input: RegisterInput!): AuthPayload!
    login(input: LoginInput!): AuthPayload!
  }
  
  type Query {
    getUserDetails(userId: ID!): User!
  }
`; 