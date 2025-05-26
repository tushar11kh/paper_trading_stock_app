import 'package:flutter/material.dart';

class WatchlistSection extends StatelessWidget {
  const WatchlistSection({super.key});

  @override
  Widget build(BuildContext context) {
    final watchlist = [
      {
        "symbol": "MSFT",
        "company": "Microsoft Corp.",
        "price": "\$252.12",
        "change": "+10.03%",
        "isPositive": true,
      },
      {
        "symbol": "PYPL",
        "company": "PayPal Holdings",
        "price": "\$126.23",
        "change": "-1.42%",
        "isPositive": false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Watchlist",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...watchlist.map((stockData) {
          final stock = stockData as Map<String, dynamic>;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(child: Text(stock["symbol"]![0])),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stock["symbol"], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(stock["company"], style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(stock["price"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      stock["change"],
                      style: TextStyle(
                        color: stock["isPositive"] ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList()
      ],
    );
  }
}
