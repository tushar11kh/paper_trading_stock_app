import axios from 'axios';
import { pubsub } from '../graphql/pubsub';
import pool from '../db';

const BASE_URL = 'http://localhost:3000';

async function fetchAndPublishStockPrices() {
  try {
    const response = await axios.get(`${BASE_URL}/stocks`);
    const stocks = response.data;
    console.log('📡 Fetched stocks:', stocks.length);

    for (const stock of stocks) {
      if (!stock?.symbol || !stock?.price) {
        console.error('❌ Invalid stock format:', stock);
        continue;
      }

      const stockData = {
        symbol: stock.symbol,
        price: stock.price,
        name: stock.name || 'Unknown',
        isActive: stock.is_active ?? true
      };

      // Store historical price in PostgreSQL
      try {
        await pool.query(
          'INSERT INTO stock_prices (stock_id, price) ' +
          'SELECT id, $1 FROM stocks WHERE symbol = $2',
          [stock.price, stock.symbol]
        );
      } catch (error) {
        console.error('Error storing historical price:', error);
      }
      
      // Publish real-time update
      pubsub.publish(`PRICE_${stock.symbol}`, { 
        priceUpdate: stockData
      });
    }
    console.log('✅ Prices updated and published');
  } catch (error) {
    console.error('❌ Fetch error:', error);
  }
}

export function startStockPriceFetcher() {
  setInterval(fetchAndPublishStockPrices, 2000);
}
