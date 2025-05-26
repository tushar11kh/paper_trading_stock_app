import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class StockCard extends StatefulWidget {
  final String name;
  final String company;
  final double fallbackPrice;
  final String change;
  final bool isPositive;
  final bool enableLivePrice;

  const StockCard({
    super.key,
    required this.name,
    required this.company,
    required this.fallbackPrice,
    required this.change,
    required this.isPositive,
    this.enableLivePrice = true,
  });

  @override
  State<StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<StockCard> {
  double _currentPrice = 0.0;
  double? _initialPrice;
  Color? _flashColor;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentPrice = widget.fallbackPrice;
    _initialPrice = widget.fallbackPrice;
  }

  static final _subscriptionQuery = gql(r'''
    subscription($symbol: String!) {
      priceUpdate(symbol: $symbol) {
        price
      }
    }
  ''');

  void _handlePriceUpdate(double newPrice) {
    if (newPrice == _currentPrice) return;

    // Set initial price only once
    _initialPrice ??= newPrice;

    setState(() {
      _flashColor = newPrice > _currentPrice ? Colors.green : Colors.red;
      _currentPrice = newPrice;

      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _flashColor = null;
          });
        }
      });
    });
  }

  String _getPercentageChange() {
    if (_initialPrice == null || _initialPrice == 0) return "+0.00%";
    final percent = ((_currentPrice - _initialPrice!) / _initialPrice!) * 100;
    final isPositive = percent >= 0;
    return "${isPositive ? "+" : ""}${percent.toStringAsFixed(2)}%";
  }

  Widget buildCard() {
    final percentColor = _currentPrice >= (_initialPrice ?? 0) ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Symbol and Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.company,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Price and % Change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${_currentPrice.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _flashColor ?? Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getPercentageChange(),
                style: TextStyle(
                  fontSize: 12,
                  color: percentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableLivePrice) {
      return buildCard();
    }

    return Subscription(
      options: SubscriptionOptions(
        document: _subscriptionQuery,
        variables: {'symbol': widget.name},
      ),
      builder: (result) {
        if (result.data != null) {
          final newPrice = result.data!['priceUpdate']['price']?.toDouble() ?? _currentPrice;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handlePriceUpdate(newPrice);
          });
        }
        return buildCard();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
