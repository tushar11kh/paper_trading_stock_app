import Redis from 'ioredis';

const redis = new Redis();

export const stockResolvers = {
  Query: {
    getStock: async (_: any, { symbol }: { symbol: string },context:any) => {
      const data = await context.redis.get(`stock:${symbol}`);
      return data ? JSON.parse(data) : null;
    },
    getAllStocks: async () => {
      const keys = await redis.keys('stock:*');
      if (!keys.length) return []; // Early return if no keys

      const pipeline = redis.pipeline();
      keys.forEach((key) => pipeline.get(key));
      
      const results = await pipeline.exec();
      if (!results) return []; // Handle null cases

      return results.map(([err, value]) => {
        if (err) throw err; // Handle pipeline errors
        return JSON.parse(value as string); // Assert value as string
      });
    },
  },
};