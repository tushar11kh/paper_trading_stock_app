import pool from '../db';

interface Order {
  id: number;
  user_id: number;
  stock_id: number;
  quantity: number;
  price: number;
  order_type: 'MARKET_BUY' | 'MARKET_SELL' | 'LIMIT_BUY' | 'LIMIT_SELL';
  status: 'PENDING' | 'FILLED' | 'CANCELLED';
}

export class OrderMatchingService {
  private static instance: OrderMatchingService;
  private orderQueue: Map<number, Order[]> = new Map(); // stock_id -> orders

  private constructor() {
    this.startMatchingEngine();
  }

  public static getInstance(): OrderMatchingService {
    if (!OrderMatchingService.instance) {
      OrderMatchingService.instance = new OrderMatchingService();
    }
    return OrderMatchingService.instance;
  }

  private async startMatchingEngine() {
    setInterval(async () => {
      await this.matchOrders();
    }, 1000); // Check for matches every second
  }

  public async addOrder(order: Order) {
    if (!this.orderQueue.has(order.stock_id)) {
      this.orderQueue.set(order.stock_id, []);
    }
    this.orderQueue.get(order.stock_id)?.push(order);
    await this.matchOrders(); // Try to match immediately
  }

  public async removeOrder(orderId: number) {
    for (const [stockId, orders] of this.orderQueue.entries()) {
      const updatedOrders = orders.filter(order => order.id !== orderId);
      this.orderQueue.set(stockId, updatedOrders);
    }
  }

  private async getCurrentPrice(stockId: number): Promise<number> {
    const result = await pool.query(
      'SELECT price FROM stock_prices WHERE stock_id = $1 ORDER BY timestamp DESC LIMIT 1',
      [stockId]
    );
    return result.rows[0]?.price || 0;
  }

  public async matchOrders() {
    for (const [stockId, orders] of this.orderQueue.entries()) {
      const currentPrice = await this.getCurrentPrice(stockId);
      if (!currentPrice) continue;

      // Process market orders first
      for (const order of orders) {
        if (order.status !== 'PENDING') continue;

        // For market orders, execute immediately at current price
        if (order.order_type.startsWith('MARKET_')) {
          await this.executeMarketOrder(order, currentPrice);
        }
        // For limit orders: check price conditions
        else if (order.order_type === 'LIMIT_BUY' && currentPrice <= order.price) {
          await this.executeMarketOrder(order, currentPrice);
        }
        else if (order.order_type === 'LIMIT_SELL' && currentPrice >= order.price) {
          await this.executeMarketOrder(order, currentPrice);
        }
      }

      // Remove filled orders
      this.orderQueue.set(stockId, orders.filter(o => o.status === 'PENDING'));
    }
  }

  private async executeMarketOrder(order: Order, currentPrice: number) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Update order status first
      await client.query(
        `UPDATE orders
        SET status = 'FILLED'
        WHERE id = $1`,
        [order.id]
      );

      order.status = 'FILLED';

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

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error executing market order:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  private async executeTrade(
    buyOrder: Order,
    sellOrder: Order,
    quantity: number,
    price: number
  ) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Create trade record
      await client.query(
        `INSERT INTO trades 
        (buy_order_id, sell_order_id, stock_id, quantity, price)
        VALUES ($1, $2, $3, $4, $5)`,
        [buyOrder.id, sellOrder.id, buyOrder.stock_id, quantity, price]
      );

      // Update buyer's portfolio
      await client.query(
        `INSERT INTO portfolios (user_id, stock_id, quantity, average_price)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (user_id, stock_id) DO UPDATE
        SET quantity = portfolios.quantity + $3,
            average_price = (portfolios.quantity * portfolios.average_price + $3 * $4) / (portfolios.quantity + $3)`,
        [buyOrder.user_id, buyOrder.stock_id, quantity, price]
      );

      // Update seller's portfolio
      await client.query(
        `UPDATE portfolios
        SET quantity = quantity - $1
        WHERE user_id = $2 AND stock_id = $3`,
        [quantity, sellOrder.user_id, sellOrder.stock_id]
      );

      // Update user balances
      const totalAmount = quantity * price;
      await client.query(
        `UPDATE users
        SET balance = balance - $1
        WHERE id = $2`,
        [totalAmount, buyOrder.user_id]
      );

      await client.query(
        `UPDATE users
        SET balance = balance + $1
        WHERE id = $2`,
        [totalAmount, sellOrder.user_id]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error executing trade:', error);
      throw error;
    } finally {
      client.release();
    }
  }
} 