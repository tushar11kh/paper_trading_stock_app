//backend/src/graphql/typeDefs/portfolioTypeDef.ts
import { gql } from 'graphql-tag';

export const portfolioTypeDef = gql`
    type PortfolioItems{
        stockSymbol:String!
        quantity:Int!
        averagePrice:Float!
        currentPrice:Float!
        totalValue:Float!
    }

    type Query{
        getPortfolio(userId:ID!):[PortfolioItems!]!
    }
`;