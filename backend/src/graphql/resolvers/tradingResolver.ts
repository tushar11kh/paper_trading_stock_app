import { Stock } from '../../types/stock';
import pool from '../../db';
import { OrderMatchingService } from '../../services/orderMatchingService';

interface GetPortfolioArgs {
  userId: string;
}

interface PlaceOrderArgs {
  input: {
    symbol: string;
    quantity: number;
    price?: number;
    orderType: 'BUY' | 'SELL';
  };
}

export const tradingResolvers = {
  Query: {
    getPortfolio: async (_: unknown, { userId }: GetPortfolioArgs) => {
      try {
        const result = await pool.query(
          `SELECT 
            s.symbol,
            s.name,
            sp.price as current_price,
            p.quantity,
            p.average_price,
            (p.quantity * sp.price) as current_value,
            (p.quantity * (sp.price - p.average_price)) as profit_loss
          FROM portfolios p
          JOIN stocks s ON p.stock_id = s.id
          JOIN (
            SELECT DISTINCT ON (stock_id) stock_id, price
            FROM stock_prices
            ORDER BY stock_id, timestamp DESC
          ) sp ON s.id = sp.stock_id
          WHERE p.user_id = $1 AND p.quantity > 0`,
          [userId]
        );

        return result.rows.map(row => ({
          stock: {
            symbol: row.symbol,
            name: row.name,
            price: Number(row.current_price)
          },
          quantity: Number(row.quantity),
          averagePrice: Number(row.average_price),
          currentValue: Number(row.current_value),
          profitLoss: Number(row.profit_loss)
        }));
      } catch (error) {
        console.error('Error fetching portfolio:', error);
        return [];
      }
    }
  },
  Mutation: {
    placeOrder: async (_: unknown, { input }: PlaceOrderArgs) => {
      const { symbol, quantity, price, orderType } = input;
      
      try {
        // Start transaction
        const client = await pool.connect();
        try {
          await client.query('BEGIN');

          // Get stock ID
          const stockResult = await client.query(
            'SELECT id FROM stocks WHERE symbol = $1 AND is_active = true',
            [symbol]
          );
          if (stockResult.rows.length === 0) {
            throw new Error('Stock not found or not active');
          }
          const stockId = stockResult.rows[0].id;

          // Get current price if not provided
          let currentPrice: number;
          if (price) {
            currentPrice = price;
          } else {
            const priceResult = await client.query(
              'SELECT price FROM stock_prices WHERE stock_id = $1 ORDER BY timestamp DESC LIMIT 1',
              [stockId]
            );
            if (priceResult.rows.length === 0) {
              throw new Error('No price data available');
            }
            currentPrice = priceResult.rows[0].price;
          }

          // Check user balance for buy orders
          if (orderType === 'BUY') {
            const userResult = await client.query(
              'SELECT balance FROM users WHERE id = $1',
              [1] // TODO: Get actual user_id from auth
            );
            if (userResult.rows.length === 0) {
              throw new Error('User not found');
            }
            const requiredAmount = quantity * currentPrice;
            if (userResult.rows[0].balance < requiredAmount) {
              throw new Error('Insufficient balance');
            }
          }

          // Check portfolio for sell orders
          if (orderType === 'SELL') {
            const portfolioResult = await client.query(
              'SELECT quantity FROM portfolios WHERE user_id = $1 AND stock_id = $2',
              [1, stockId] // TODO: Get actual user_id from auth
            );
            if (portfolioResult.rows.length === 0 || portfolioResult.rows[0].quantity < quantity) {
              throw new Error('Insufficient stock quantity');
            }
          }

          // Create order
          const orderResult = await client.query(
            `INSERT INTO orders 
            (user_id, stock_id, quantity, price, order_type, status)
            VALUES ($1, $2, $3, $4, $5, 'PENDING')
            RETURNING id`,
            [1, stockId, quantity, currentPrice, orderType] // TODO: Get actual user_id from auth
          );

          const order = {
            id: orderResult.rows[0].id,
            user_id: 1, // TODO: Get actual user_id from auth
            stock_id: stockId,
            quantity,
            price: currentPrice,
            order_type: orderType,
            status: 'PENDING' as const
          };

          // Add to order matching service
          await OrderMatchingService.getInstance().addOrder(order);

          await client.query('COMMIT');

          // Return the created order
          return {
            id: order.id,
            stock: {
              symbol,
              price: currentPrice
            },
            quantity,
            price: currentPrice,
            orderType,
            status: 'PENDING',
            createdAt: new Date().toISOString()
          };
        } catch (error) {
          await client.query('ROLLBACK');
          throw error;
        } finally {
          client.release();
        }
      } catch (error) {
        console.error('Error placing order:', error);
        throw error;
      }
    }
  }
}; 