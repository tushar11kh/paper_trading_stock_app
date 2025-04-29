//backend/src/graphql/resolvers/orderResolver.ts
import { Context } from '../context';

export const orderResolvers = {
  Mutation: {
    placeOrder: async (
      _: unknown,
      { input }: { 
        input: { 
          userId: string;
          stockSymbol: string;
          type: 'BUY' | 'SELL';
          quantity: number;
          orderType: 'MARKET' | 'LIMIT';
          limitPrice?: number;
        }
      },
      { pool, redis }: Context
    ) => {
      const { userId, stockSymbol, type, quantity, orderType, limitPrice } = input;

      // Fetch current price from Redis
      const redisData = await redis.get(`stock:${stockSymbol}`);
      if (!redisData) throw new Error('Stock not found in cache');
      const currentPrice = JSON.parse(redisData).price;

      // Market order execution
      if (orderType === 'MARKET') {
        const executionPrice = parseFloat(currentPrice);
        const total = quantity * executionPrice;

        const client = await pool.connect();
        
        try {
          await client.query('BEGIN');

          if (type === 'BUY') {
            // Buy logic
            const userResult = await client.query<{ balance: number }>(
              'SELECT balance FROM users WHERE id = $1', 
              [userId]
            );
            
            if (userResult.rows[0].balance < total) {
              throw new Error('Insufficient balance');
            }

            await client.query(
              'UPDATE users SET balance = balance - $1 WHERE id = $2',
              [total, userId]
            );

            await client.query(`
              INSERT INTO portfolios (user_id, stock_id, quantity, average_price)
              VALUES ($1, $2, $3, $4)
              ON CONFLICT (user_id, stock_id)
              DO UPDATE SET
                quantity = portfolios.quantity + EXCLUDED.quantity,
                average_price = (portfolios.quantity * portfolios.average_price + EXCLUDED.quantity * EXCLUDED.average_price)
                              / (portfolios.quantity + EXCLUDED.quantity)
            `, [userId, stockSymbol, quantity, executionPrice]);
          } 
          else {
            // Sell logic
            const holdings = await client.query<{ quantity: number }>(
              `SELECT quantity FROM portfolios WHERE user_id = $1 AND stock_id = $2`,
              [userId, stockSymbol]
            );
            
            if (holdings.rows.length === 0 || holdings.rows[0].quantity < quantity) {
              throw new Error('Not enough holdings to sell');
            }

            await client.query(
              'UPDATE users SET balance = balance + $1 WHERE id = $2',
              [total, userId]
            );

            await client.query(
              `UPDATE portfolios SET quantity = quantity - $1
               WHERE user_id = $2 AND stock_id = $3`,
              [quantity, userId, stockSymbol]
            );
          }

          // Record trade
          await client.query(
            `INSERT INTO trades (user_id, stock_id, quantity, price, type)
             VALUES ($1, $2, $3, $4, $5)`,
            [userId, stockSymbol, quantity, executionPrice, type]
          );

          await client.query('COMMIT');
          return { success: true, message: 'Order executed successfully' };
        } catch (error) {
          await client.query('ROLLBACK');
          throw error;
        } finally {
          client.release();
        }
      }

      // Limit order handling
      await pool.query(
        `INSERT INTO orders (user_id, stock_id, quantity, price, order_type, status)
         VALUES ($1, $2, $3, $4, $5, 'PENDING')`,
        [userId, stockSymbol, quantity, limitPrice, type]
      );

      return { success: true, message: 'Limit order placed' };
    }
  }
};