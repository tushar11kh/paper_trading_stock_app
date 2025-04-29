import { gql } from "apollo-server";

export const helloTypeDef = gql`
    type Query{
        hello:String
    }
`;