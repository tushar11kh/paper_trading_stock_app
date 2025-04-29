import { makeExecutableSchema } from '@graphql-tools/schema';

import { helloTypeDef } from './typeDefs/helloTypeDef';
import { helloResolver } from './resolvers/helloResolver';

import { stockTypeDef } from './typeDefs/stockTypeDef';
import { stockResolvers } from './resolvers/stockResolver';

export const schema = makeExecutableSchema(
    {
        typeDefs: [helloTypeDef,stockTypeDef],
        resolvers: [helloResolver,stockResolvers],
    }
);
