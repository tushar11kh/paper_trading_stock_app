import axios from 'axios';
import Redis from 'ioredis';

const redis = new Redis();
const BASE_URL = 'http://localhost:3000';

async function fetchAndCacheStockPrices() {
  try {
    const response = await axios.get(`${BASE_URL}/stocks`);
    const stocks = response.data;

    const pipeline = redis.pipeline(); // start batching

    for (const stock of stocks) {
      const redisKey = `stock:${stock.symbol}`;
      const redisValue = JSON.stringify(stock);
      pipeline.set(redisKey, redisValue); // add to batch
    }

    await pipeline.exec(); // execute all commands in one go
    console.log(`✅ Cached ${stocks.length} stocks to Redis`);

  } catch (error) {
    console.error('❌ Error fetching stock prices:', error);
  }
}

export function startStockPriceFetcher() {
  setInterval(fetchAndCacheStockPrices, 1000);
}
