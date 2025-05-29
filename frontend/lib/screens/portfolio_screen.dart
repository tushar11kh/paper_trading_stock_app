import 'package:flutter/material.dart';
import 'package:PaperTradeApp/common/widgets/portfolio_stock_card.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolioStocks = [
      {
        "symbol": "AAPL",
        "company": "Apple Inc.",
        "quantity": 10,
        "avgPrice": 145.00,
        "currentPrice": 160.50,
      },
      {
        "symbol": "GOOGL",
        "company": "Alphabet Inc.",
        "quantity": 5,
        "avgPrice": 2800.00,
        "currentPrice": 2900.00,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Portfolio"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Stocks you own",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: portfolioStocks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
  final stock = portfolioStocks[index];
  return PortfolioStockCard(
    symbol: stock["symbol"] as String,
    company: stock["company"] as String,
    quantity: stock["quantity"] as int,
    avgPrice: stock["avgPrice"] as double,
    currentPrice: stock["currentPrice"] as double,
  );
},

              ),
            ),
          ],
        ),
      ),
    );
  }
}
