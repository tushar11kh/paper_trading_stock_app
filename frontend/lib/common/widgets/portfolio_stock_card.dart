import 'package:flutter/material.dart';

class PortfolioStockCard extends StatelessWidget {
  final String symbol;
  final String company;
  final int quantity;
  final double avgPrice;
  final double currentPrice;

  const PortfolioStockCard({
    super.key,
    required this.symbol,
    required this.company,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    final totalInvested = avgPrice * quantity;
    final totalCurrent = currentPrice * quantity;
    final profitLoss = totalCurrent - totalInvested;
    final isProfit = profitLoss >= 0;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(symbol, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(company, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Text("Qty: $quantity"),
          Text("Avg: \$${avgPrice.toStringAsFixed(2)}"),
          Text("Current: \$${currentPrice.toStringAsFixed(2)}"),
          const SizedBox(height: 10),
          Text(
            "${isProfit ? "+" : "-"}\$${profitLoss.abs().toStringAsFixed(2)}",
            style: TextStyle(
              color: isProfit ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
