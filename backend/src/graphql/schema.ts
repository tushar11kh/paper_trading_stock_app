import { makeExecutableSchema } from '@graphql-tools/schema';


import { stockTypeDef } from './typeDefs/stockTypeDef';
import { stockResolvers } from './resolvers/stockResolver';
import { tradingResolvers } from './resolvers/tradingResolver';

import { authTypeDef } from './typeDefs/authTypeDef';
import { authResolvers } from './resolvers/authResolver';

export const schema = makeExecutableSchema(
    {
        typeDefs: [stockTypeDef, authTypeDef],
        resolvers: [stockResolvers, tradingResolvers, authResolvers],
    }
);
