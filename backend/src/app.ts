// backend/src/app.ts
import { createYoga } from 'graphql-yoga';
import dotenv from 'dotenv';
import { schema } from './graphql/schema';
import pool from './db/';
import redis from './db/redis';
import { createContext } from './graphql/context';

dotenv.config();

export async function createYogaServer() {
  try {
    const { rows } = await pool.query('SELECT NOW()');
    await redis.ping();
    
    console.log('✅ Database connected at:', rows[0].now);
    console.log('✅ Redis connected');

    return createYoga({
      schema,
      context: ({ request }) => ({
        req: request,
        redis,
        pool
      }),
      graphiql: {
        title: 'Stock Trading API',
        subscriptionsProtocol: 'WS' // This enables WS in GraphiQL
      },
      // WebSocket is automatically enabled by default
      // No need for explicit subscriptions config
    });
  } catch (error) {
    console.error('❌ Failed to connect to services', error);
    process.exit(1);
  }
}