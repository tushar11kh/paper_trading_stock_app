// backend/src/services/stockFetcherService.ts
import axios from 'axios';
import redis from '../db/redis';

const BASE_URL = 'http://localhost:3000';

async function fetchAndCacheStockPrices() {
  try {
    const response = await axios.get(`${BASE_URL}/stocks`);
    const stocks = response.data;

    const pipeline = redis.pipeline();

    for (const stock of stocks) {
      const redisKey = `stock:${stock.symbol}`;
      const redisValue = JSON.stringify(stock);
      pipeline.set(redisKey, redisValue);
    }

    await pipeline.exec();
    console.log(`✅ Updated ${stocks.length} stocks`);
  } catch (error) {
    console.error('❌ Price update error:', error);
  }
}

export function startStockPriceFetcher() {
  fetchAndCacheStockPrices();
  setInterval(() => fetchAndCacheStockPrices(), 1000);
}
