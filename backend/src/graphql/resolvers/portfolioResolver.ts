//backend/src/graphql/resolvers/portfolioResolver.ts

import { Context } from '../context';

export const portfolioResolvers = {
  Query: {
    getPortfolio: async (
      _: unknown,
      { userId }: { userId: string },
      { pool, redis }: Context
    ) => {
      const result = await pool.query<{
        stock_id: string;
        quantity: number;
        average_price: number;
      }>(
        `SELECT stock_id, quantity, average_price 
         FROM portfolios WHERE user_id = $1`,
        [userId]
      );

      return Promise.all(
        result.rows.map(async (row) => {
          const redisData = await redis.get(`stock:${row.stock_id}`);
          const price = redisData ? JSON.parse(redisData).price : 0;
          
          return {
            stockSymbol: row.stock_id,
            quantity: row.quantity,
            averagePrice: row.average_price,
            currentPrice: price,
            totalValue: row.quantity * price,
          };
        })
      );
    },
  },
};