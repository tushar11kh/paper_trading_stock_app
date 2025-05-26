import { Stock } from '../../types/stock';
import { pubsub } from '../pubsub';
import pool from '../../db';

interface GetStockArgs {
  symbol: string;
}

interface PriceUpdateArgs {
  symbol: string;
}

interface GetStockHistoryArgs {
  symbol: string;
  timeframe: string; // '1min', '5min', '1hr', '1day'
}

export const stockResolvers = {
  Query: {
    getStock: async (_: unknown, { symbol }: GetStockArgs): Promise<Stock | null> => {
      try {
        const result = await pool.query(
          'SELECT s.symbol, s.name, s.is_active, sp.price ' +
          'FROM stocks s ' +
          'LEFT JOIN stock_prices sp ON s.id = sp.stock_id ' +
          'WHERE s.symbol = $1 ' +
          'ORDER BY sp.timestamp DESC LIMIT 1',
          [symbol]
        );
        
        if (result.rows.length === 0) return null;
        
        return {
          symbol: result.rows[0].symbol,
          name: result.rows[0].name,
          price: Number(result.rows[0].price),
          isActive: result.rows[0].is_active
        };
      } catch (error) {
        console.error('Error fetching stock:', error);
        return null;
      }
    },

    getStockHistory: async (_: unknown, { symbol, timeframe }: GetStockHistoryArgs) => {
      try {
        let interval;
        switch (timeframe) {
          case '1min': interval = '1 minute'; break;
          case '5min': interval = '5 minutes'; break;
          case '1hr': interval = '1 hour'; break;
          case '1day': interval = '1 day'; break;
          default: interval = '1 minute';
        }

        const result = await pool.query(
          `SELECT 
            time_bucket('${interval}', timestamp) as bucket,
            first(price, timestamp) as open,
            max(price) as high,
            min(price) as low,
            last(price, timestamp) as close
          FROM stock_prices sp
          JOIN stocks s ON s.id = sp.stock_id
          WHERE s.symbol = $1
          GROUP BY bucket
          ORDER BY bucket DESC
          LIMIT 100`,
          [symbol]
        );

        return result.rows.map(row => ({
          timestamp: row.bucket,
          open: Number(row.open),
          high: Number(row.high),
          low: Number(row.low),
          close: Number(row.close)
        }));
      } catch (error) {
        console.error('Error fetching stock history:', error);
        return [];
      }
    },

    getHistoricalPrices: async (_: unknown, { stockId }: { stockId: number }) => {
      try {
        const result = await pool.query(
          `SELECT timestamp, price
           FROM stock_prices
           WHERE stock_id = $1
           ORDER BY timestamp DESC`,
          [stockId]
        );

        return result.rows.map(row => ({
          timestamp: row.timestamp,
          price: Number(row.price),
        }));
      } catch (error) {
        console.error('Error fetching historical prices:', error);
        return [];
      }
    },
  },
  Subscription: {
    priceUpdate: {
      subscribe: (_: unknown, { symbol }: PriceUpdateArgs) => {
        console.log(`[SUB] New listener for ${symbol}`);
        return pubsub.asyncIterableIterator(`PRICE_${symbol}`);
      },
    }
  }
};

