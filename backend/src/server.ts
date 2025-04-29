// backend/src/server.ts
import { createYoga } from 'graphql-yoga';
import { createServer } from 'node:http';
import { schema } from './graphql/schema';
import { startStockPriceFetcher } from './services/stockFetcherService';
import { createContext } from './graphql/context';
import dotenv from 'dotenv';

dotenv.config();

async function initializeServer() {
  try {
    const context = await createContext();
    
    const yoga = createYoga({
      schema,
      context,
      graphiql: {
        title: 'Stock Trading API',
      },
      logging: {
        debug: (...args) => console.debug('[DEBUG]', ...args),
        info: (...args) => console.info('[INFO]', ...args),
        warn: (...args) => console.warn('[WARN]', ...args),
        error: (...args) => console.error('[ERROR]', ...args)
      }
    });

    const httpServer = createServer(yoga);

    const shutdown = async () => {
      console.log('🚦 Shutting down gracefully...');
      await context.pool.end();
      context.redis.disconnect();
      httpServer.close();
      process.exit(0);
    };

    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);

    httpServer.listen(4000, () => {
      console.log('🚀 Server ready at http://localhost:4000/graphql');
      startStockPriceFetcher(); // Start the stock price fetcher
    });

    return httpServer;
  } catch (error) {
    console.error('❌ Server initialization failed:', error);
    process.exit(1);
  }
}

initializeServer().catch(console.error);
