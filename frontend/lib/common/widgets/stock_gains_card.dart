// lib/features/home/ui/widgets/stock_gains_card.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StockGainsCard extends StatelessWidget {
  const StockGainsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 77, 169, 222),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Stock Gains", style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          const Text("\$24,320+", style: TextStyle(fontSize: 28, color: Colors.white)),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(1, 2.5),
                      FlSpot(2, 2),
                      FlSpot(3, 3),
                      FlSpot(4, 2.8),
                      FlSpot(5, 3.5),
                      FlSpot(6, 3.2),
                    ],
                    isCurved: true,
                    color: Colors.white,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
