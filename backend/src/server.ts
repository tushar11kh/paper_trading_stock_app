// backend/src/server.ts
import { createApolloServer } from './app';
import { startStockPriceFetcher } from './services/stockFetcherService';

async function start() {
  try {
    const httpServer = await createApolloServer();
    
    httpServer.listen(4000, () => {
      console.log(`🚀 Server ready at http://localhost:4000/graphql`);
      console.log(`🚀 Subscriptions ready at ws://localhost:4000/graphql`);
    });
    
    startStockPriceFetcher();
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();