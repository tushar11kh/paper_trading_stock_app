import axios from 'axios';
import Redis from 'ioredis';
import { pubsub } from '../graphql/pubsub';

const redis = new Redis();
const BASE_URL = 'http://localhost:3000';

// In stockFetcherService.ts
async function fetchAndCacheStockPrices() {
  try {
    const response = await axios.get(`${BASE_URL}/stocks`);
    const stocks = response.data; // This is the array
    console.log('📡 Fetched stocks:', stocks.length);

    const pipeline = redis.pipeline();
    for (const stock of stocks) { // Here each item is 'stock'
      if (!stock?.symbol || !stock?.price) {
        console.error('❌ Invalid stock format:', stock);
        continue;
      }

      const redisKey = `stock:${stock.symbol}`;
      const stockData = {
        symbol: stock.symbol,
        price: stock.price,
        name: stock.name || 'Unknown'
      };

      pipeline.set(redisKey, JSON.stringify(stockData));
      
      pubsub.publish(`PRICE_${stock.symbol}`, { 
        priceUpdate: stockData // Must match GraphQL type
      });
    }
    await pipeline.exec();
    console.log('✅ Prices updated');
  } catch (error) {
    console.error('❌ Fetch error:', error);
  }
}

export function startStockPriceFetcher() {
  setInterval(fetchAndCacheStockPrices, 2000);
}
