// backend/src/types/stock.ts
export interface Stock {
    symbol: string;
    price: number;
    name: string;
    // Optional fields based on your needs
    updatedAt?: Date; 
    volume?: number;
  }