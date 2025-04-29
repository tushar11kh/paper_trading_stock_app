// backend/src/app.ts
import { createServer as createHttpServer } from 'http';
import { ApolloServer } from 'apollo-server-express';
import express from 'express';
import { schema } from './graphql/schema';
import { createSubscriptionServer } from './graphql/subscriptions';
import redis from './db/redis';

export async function createApolloServer() {
  const app = express();
  const httpServer = createHttpServer(app);

  const apolloServer = new ApolloServer({
    schema,
    context: ({ req }) => ({ req, redis }),
  });

  await apolloServer.start();
  apolloServer.applyMiddleware({ app });

  createSubscriptionServer(httpServer);

  return httpServer;
}