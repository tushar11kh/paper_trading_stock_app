import { makeExecutableSchema } from '@graphql-tools/schema';
import { helloTypeDef } from './typeDefs/helloTypeDef';
import { helloResolver } from './resolvers/helloResolver';

export const schema = makeExecutableSchema(
    {
        typeDefs: [helloTypeDef],
        resolvers: [helloResolver],
    }
);
