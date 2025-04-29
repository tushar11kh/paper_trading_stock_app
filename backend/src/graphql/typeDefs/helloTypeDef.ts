import { gql } from 'graphql-tag';

export const helloTypeDef = gql`
    type Query{
        hello:String
    }
`;