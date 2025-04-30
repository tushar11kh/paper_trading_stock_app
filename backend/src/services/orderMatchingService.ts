import pool from '../db';

interface Order {
  id: number;
  user_id: number;
  stock_id: number;
  quantity: number;
  price: number;
  order_type: 'BUY' | 'SELL';
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

  private async matchOrders() {
    for (const [stockId, orders] of this.orderQueue.entries()) {
      const buyOrders = orders.filter(o => o.order_type === 'BUY' && o.status === 'PENDING')
        .sort((a, b) => b.price - a.price); // Highest price first
      
      const sellOrders = orders.filter(o => o.order_type === 'SELL' && o.status === 'PENDING')
        .sort((a, b) => a.price - b.price); // Lowest price first

      for (const buyOrder of buyOrders) {
        for (const sellOrder of sellOrders) {
          if (buyOrder.price >= sellOrder.price) {
            const matchedQuantity = Math.min(buyOrder.quantity, sellOrder.quantity);
            
            if (matchedQuantity > 0) {
              await this.executeTrade(buyOrder, sellOrder, matchedQuantity, sellOrder.price);
              
              // Update order quantities
              buyOrder.quantity -= matchedQuantity;
              sellOrder.quantity -= matchedQuantity;
              
              // Update order statuses
              if (buyOrder.quantity === 0) {
                buyOrder.status = 'FILLED';
              }
              if (sellOrder.quantity === 0) {
                sellOrder.status = 'FILLED';
              }
            }
          }
        }
      }

      // Remove filled orders
      this.orderQueue.set(stockId, orders.filter(o => o.status === 'PENDING'));
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