//backend/src/graphql/schema.ts
import { makeExecutableSchema } from '@graphql-tools/schema';

import { helloTypeDef } from './typeDefs/helloTypeDef';
import { helloResolver } from './resolvers/helloResolver';

import { stockTypeDef } from './typeDefs/stockTypeDef';
import { stockResolvers } from './resolvers/stockResolver';
import { orderResolvers } from './resolvers/orderResolver';
import { orderTypeDef } from './typeDefs/orderTypeDef';
import { portfolioTypeDef } from './typeDefs/portfolioTypeDef';
import { portfolioResolvers } from './resolvers/portfolioResolver';


export const schema = makeExecutableSchema(
    {
        typeDefs: [helloTypeDef,stockTypeDef,orderTypeDef,portfolioTypeDef],
        resolvers: [helloResolver,stockResolvers,orderResolvers,portfolioResolvers],
    }
);
