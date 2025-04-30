import { Stock } from '../../types/stock';
import pool from '../../db';
import { OrderMatchingService } from '../../services/orderMatchingService';
import { AuthService } from '../../services/authService';

interface GetPortfolioArgs {
  userId: string;
}

interface PlaceOrderArgs {
  input: {
    symbol: string;
    quantity: number;
    price?: number;
    orderType: 'MARKET' | 'LIMIT';
    side: 'BUY' | 'SELL';
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
    },
    getPendingOrders: async (_: unknown, __: unknown, context: any) => {
      try {
        const token = context.req.headers.authorization?.split(' ')[1];
        if (!token) {
          throw new Error('No authentication token provided');
        }
        const user = await AuthService.verifyToken(token);

        const result = await pool.query(
          `SELECT 
            o.id,
            o.quantity,
            o.price,
            o.order_type as "orderType",
            o.status,
            o.created_at as "createdAt",
            s.symbol,
            s.name,
            s.is_active,
            sp.price as current_price
          FROM orders o
          JOIN stocks s ON o.stock_id = s.id
          LEFT JOIN (
            SELECT DISTINCT ON (stock_id) stock_id, price
            FROM stock_prices
            ORDER BY stock_id, timestamp DESC
          ) sp ON s.id = sp.stock_id
          WHERE o.user_id = $1 AND o.status = 'PENDING'
          ORDER BY o.created_at DESC`,
          [user.id]
        );

        return result.rows.map(row => ({
          id: row.id,
          stock: {
            symbol: row.symbol,
            name: row.name,
            price: Number(row.current_price),
            isActive: row.is_active
          },
          quantity: Number(row.quantity),
          price: Number(row.price),
          orderType: row.orderType,
          status: row.status,
          createdAt: row.createdAt
        }));
      } catch (error) {
        console.error('Error fetching pending orders:', error);
        return [];
      }
    }
  },
  Mutation: {
    placeOrder: async (_: unknown, { input }: PlaceOrderArgs, context: any) => {
      const { symbol, quantity, price, orderType, side } = input;
      
      try {
        // Get user from token
        const token = context.req.headers.authorization?.split(' ')[1];
        if (!token) {
          throw new Error('No authentication token provided');
        }
        const user = await AuthService.verifyToken(token);
        
        // Start transaction
        const client = await pool.connect();
        try {
          await client.query('BEGIN');

          // Get stock ID
          const stockResult = await client.query(
            'SELECT id, name, is_active FROM stocks WHERE symbol = $1 AND is_active = true',
            [symbol]
          );
          if (stockResult.rows.length === 0) {
            throw new Error('Stock not found or not active');
          }
          const stockId = stockResult.rows[0].id;

          // Get current price
          const priceResult = await client.query(
            'SELECT price FROM stock_prices WHERE stock_id = $1 ORDER BY timestamp DESC LIMIT 1',
            [stockId]
          );
          if (priceResult.rows.length === 0) {
            throw new Error('No price data available');
          }
          const currentPrice = priceResult.rows[0].price;

          // For market orders, use current price
          const orderPrice = orderType === 'MARKET' ? currentPrice : price;
          if (!orderPrice) {
            throw new Error('Price is required for limit orders');
          }

          // Check user balance for buy orders
          if (side === 'BUY') {
            const userResult = await client.query(
              'SELECT balance FROM users WHERE id = $1',
              [user.id]
            );
            if (userResult.rows.length === 0) {
              throw new Error('User not found');
            }
            const requiredAmount = quantity * orderPrice;
            if (userResult.rows[0].balance < requiredAmount) {
              throw new Error('Insufficient balance');
            }
          }

          // Check portfolio for sell orders
          if (side === 'SELL') {
            const portfolioResult = await client.query(
              'SELECT quantity FROM portfolios WHERE user_id = $1 AND stock_id = $2',
              [user.id, stockId]
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
            [user.id, stockId, quantity, orderPrice, `${orderType}_${side}` as 'MARKET_BUY' | 'MARKET_SELL' | 'LIMIT_BUY' | 'LIMIT_SELL']
          );

          const order = {
            id: orderResult.rows[0].id,
            user_id: user.id,
            stock_id: stockId,
            quantity,
            price: orderPrice,
            order_type: `${orderType}_${side}` as 'MARKET_BUY' | 'MARKET_SELL' | 'LIMIT_BUY' | 'LIMIT_SELL',
            status: 'PENDING' as 'PENDING' | 'FILLED' | 'CANCELLED'
          };

          // For market orders, execute immediately within the same transaction
          if (orderType === 'MARKET') {
            // Update order status
            await client.query(
              `UPDATE orders
              SET status = 'FILLED'
              WHERE id = $1`,
              [order.id]
            );

            // Create trade record
            await client.query(
              `INSERT INTO trades 
              (stock_id, quantity, price, ${order.order_type.endsWith('BUY') ? 'buy_order_id' : 'sell_order_id'})
              VALUES ($1, $2, $3, $4)`,
              [order.stock_id, order.quantity, currentPrice, order.id]
            );

            if (order.order_type.endsWith('BUY')) {
              // Update buyer's portfolio
              await client.query(
                `INSERT INTO portfolios (user_id, stock_id, quantity, average_price)
                VALUES ($1, $2, $3, $4)
                ON CONFLICT (user_id, stock_id) DO UPDATE
                SET quantity = portfolios.quantity + $3,
                    average_price = (portfolios.quantity * portfolios.average_price + $3 * $4) / (portfolios.quantity + $3)`,
                [order.user_id, order.stock_id, order.quantity, currentPrice]
              );

              // Update buyer's balance
              const totalAmount = order.quantity * currentPrice;
              await client.query(
                `UPDATE users
                SET balance = balance - $1
                WHERE id = $2`,
                [totalAmount, order.user_id]
              );
            } else {
              // Update seller's portfolio
              await client.query(
                `UPDATE portfolios
                SET quantity = quantity - $1
                WHERE user_id = $2 AND stock_id = $3`,
                [order.quantity, order.user_id, order.stock_id]
              );

              // Update seller's balance
              const totalAmount = order.quantity * currentPrice;
              await client.query(
                `UPDATE users
                SET balance = balance + $1
                WHERE id = $2`,
                [totalAmount, order.user_id]
              );
            }

            order.status = 'FILLED';
          } else {
            // For limit orders, add to order matching service
            await OrderMatchingService.getInstance().addOrder(order);
          }

          await client.query('COMMIT');

          // Return the created order
          return {
            id: order.id,
            stock: {
              symbol,
              name: stockResult.rows[0].name,
              price: currentPrice,
              isActive: stockResult.rows[0].is_active
            },
            quantity,
            price: orderPrice,
            orderType: `${orderType}_${side}`,
            status: order.status,
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
    },
    cancelOrder: async (_: unknown, { orderId }: { orderId: string }, context: any) => {
      try {
        const token = context.req.headers.authorization?.split(' ')[1];
        if (!token) {
          throw new Error('No authentication token provided');
        }
        const user = await AuthService.verifyToken(token);

        const client = await pool.connect();
        try {
          await client.query('BEGIN');

          // Get the order
          const orderResult = await client.query(
            `SELECT o.*, s.symbol, s.name, sp.price as current_price
            FROM orders o
            JOIN stocks s ON o.stock_id = s.id
            LEFT JOIN (
              SELECT DISTINCT ON (stock_id) stock_id, price
              FROM stock_prices
              ORDER BY stock_id, timestamp DESC
            ) sp ON s.id = sp.stock_id
            WHERE o.id = $1 AND o.user_id = $2 AND o.status = 'PENDING'`,
            [orderId, user.id]
          );

          if (orderResult.rows.length === 0) {
            throw new Error('Order not found or not cancellable');
          }

          const order = orderResult.rows[0];

          // Update order status
          await client.query(
            'UPDATE orders SET status = $1 WHERE id = $2',
            ['CANCELLED', orderId]
          );

          // Remove from order matching service
          await OrderMatchingService.getInstance().removeOrder(Number(orderId));

          await client.query('COMMIT');

          return {
            id: order.id,
            stock: {
              symbol: order.symbol,
              name: order.name,
              price: Number(order.current_price)
            },
            quantity: Number(order.quantity),
            price: Number(order.price),
            orderType: order.order_type,
            status: 'CANCELLED',
            createdAt: order.created_at
          };
        } catch (error) {
          await client.query('ROLLBACK');
          throw error;
        } finally {
          client.release();
        }
      } catch (error) {
        console.error('Error cancelling order:', error);
        throw error;
      }
    }
  }
}; 