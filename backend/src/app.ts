// backend/src/app.ts
import { createServer as createHttpServer } from 'http';
import { ApolloServer } from 'apollo-server-express';
import express from 'express';
import { schema } from './graphql/schema';
import { createSubscriptionServer } from './graphql/subscriptions';
import pool from './db';

export async function createApolloServer() {
  const app = express();
  const httpServer = createHttpServer(app);

  const apolloServer = new ApolloServer({
    schema,
    context: ({ req }) => ({ req, pool }),
  });

  await apolloServer.start();
  apolloServer.applyMiddleware({ app });

  createSubscriptionServer(httpServer);

  return httpServer;
}