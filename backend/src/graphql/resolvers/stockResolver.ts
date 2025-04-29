import Redis from 'ioredis';
import { Stock } from '../../types/stock';
import { pubsub } from '../pubsub';

const redis = new Redis();

interface GetStockArgs {
  symbol: string;
}

interface PriceUpdateArgs {
  symbol: string;
}

export const stockResolvers = {
  Query: {
    getStock: async (_: unknown, { symbol }: GetStockArgs): Promise<Stock | null> => {
      const data = await redis.get(`stock:${symbol}`);
      return data ? JSON.parse(data) : null;
    },
    getAllStocks: async (): Promise<Stock[]> => {
      const keys = await redis.keys('stock:*');
      if (!keys.length) return [];

      const pipeline = redis.pipeline();
      keys.forEach((key) => pipeline.get(key));
      
      const results = await pipeline.exec();
      if (!results) return [];

      return results.map(([err, value]) => {
        if (err) throw err;
        return JSON.parse(value as string) as Stock;
      });
    },
  },
  // In stockResolver.ts
Subscription: {
  priceUpdate: {
    subscribe: (_: unknown, { symbol }: PriceUpdateArgs) => {
      console.log(`[SUB] New listener for ${symbol}`);
      return pubsub.asyncIterableIterator(`PRICE_${symbol}`);
    },
  }
  
}
};

