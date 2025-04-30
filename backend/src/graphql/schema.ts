import { makeExecutableSchema } from '@graphql-tools/schema';

import { helloTypeDef } from './typeDefs/helloTypeDef';
import { helloResolver } from './resolvers/helloResolver';

import { stockTypeDef } from './typeDefs/stockTypeDef';
import { stockResolvers } from './resolvers/stockResolver';
import { tradingResolvers } from './resolvers/tradingResolver';

import { authTypeDef } from './typeDefs/authTypeDef';
import { authResolvers } from './resolvers/authResolver';

export const schema = makeExecutableSchema(
    {
        typeDefs: [helloTypeDef, stockTypeDef, authTypeDef],
        resolvers: [helloResolver, stockResolvers, tradingResolvers, authResolvers],
    }
);
