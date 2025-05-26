import 'dart:async';
import 'package:PaperTradeApp/core/graphql/graphql_client.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:PaperTradeApp/core/graphql/graphql_client.dart';
import 'package:fl_chart/fl_chart.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  final String company;
  final double initialPrice;
  final String initialChange;
  final bool isPositive;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.company,
    required this.initialPrice,
    required this.initialChange,
    required this.isPositive,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late double currentPrice;
  double? initialPrice;
  String priceChange = "+0.00%";
  bool isPricePositive = true;
  int quantity = 1;
  Color? flashColor;
  Timer? timer;
  String? stockId;

  final TextEditingController quantityController = TextEditingController();

  static final _subscriptionDocument = gql(r'''
    subscription($symbol: String!) {
      priceUpdate(symbol: $symbol) {
        price
      }
    }
  ''');

  static final _stockIdQuery = gql(r'''
    query($symbol: String!) {
      getStockIdBySymbol(symbol: $symbol)
    }
  ''');

  List<Map<String, dynamic>> historicalPrices = [];
  Timer? chartTimer;

  @override
  void initState() {
    super.initState();
    currentPrice = widget.initialPrice;
    initialPrice = widget.initialPrice;
    priceChange = widget.initialChange;
    isPricePositive = widget.isPositive;
    quantityController.text = quantity.toString();
    _fetchStockId();
    // Start periodic fetching of historical prices
    _fetchHistoricalPricesPeriodically();
  }

  @override
  void dispose() {
    timer?.cancel();
    chartTimer?.cancel();
    quantityController.dispose();
    super.dispose();
  }

  void _fetchHistoricalPricesPeriodically() {
    // Fetch immediately, then every 5 seconds
    _fetchHistoricalPrices();
    chartTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchHistoricalPrices();
    });
  }

  Future<void> _fetchHistoricalPrices() async {
    if (stockId == null) return;
    const String query = r'''
      query(
        $stockId: ID!
      ) {
        getHistoricalPrices(stockId: $stockId) {
          price
          timestamp
        }
      }
    ''';
    final client = await GraphQLConfig.initializeClient();
    final result = await client.query(
      QueryOptions(
        document: gql(query),
        variables: {'stockId': stockId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      debugPrint('Error fetching historical prices: \\${result.exception}');
      return;
    }
    final List<dynamic> prices = result.data?['getHistoricalPrices'] ?? [];
    setState(() {
      historicalPrices = prices.take(1000).map((e) => {
        'price': (e['price'] as num).toDouble(),
        'timestamp': e['timestamp'],
      }).toList();
    });
  }

  Future<void> _fetchStockId() async {
    final client = await GraphQLConfig.initializeClient();

    final result = await client.query(
      QueryOptions(
        document: _stockIdQuery,
        variables: {'symbol': widget.symbol},
      ),
    );

    if (result.hasException) {
      debugPrint("❌ Failed to get stockId: ${result.exception.toString()}");
      return;
    }

    final id = result.data?['getStockIdBySymbol'];
    if (id != null) {
      setState(() {
        stockId = id;
      });
      debugPrint("✅ Fetched stockId: $stockId");
    }
  }

  String _getPercentageChange() {
    if (initialPrice == null || initialPrice == 0) return "+0.00%";
    final percent = ((currentPrice - initialPrice!) / initialPrice!) * 100;
    final isPositive = percent >= 0;
    return "${isPositive ? "+" : ""}${percent.toStringAsFixed(2)}%";
  }

  void _handlePriceUpdate(Map<String, dynamic> data) {
    final newPrice = data['price']?.toDouble();
    if (newPrice != null && newPrice != currentPrice) {
      initialPrice ??= newPrice;

      setState(() {
        flashColor = newPrice > currentPrice ? Colors.green : Colors.red;
        currentPrice = newPrice;
        priceChange = _getPercentageChange();
        isPricePositive = priceChange.startsWith('+');

        timer?.cancel();
        timer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              flashColor = null;
            });
          }
        });
      });
    }
  }

  void updateQuantity(int value) {
    setState(() {
      quantity = value.clamp(1, 999999);
      quantityController.text = quantity.toString();
    });
  }

  void handleCustomQuantity(String value) {
    if (value.isEmpty) return;
    final newQuantity = int.tryParse(value);
    if (newQuantity != null) {
      updateQuantity(newQuantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = currentPrice * quantity;

    return Subscription(
      options: SubscriptionOptions(
        document: _subscriptionDocument,
        variables: {'symbol': widget.symbol},
      ),
      builder: (result) {
        if (result.data != null) {
          final priceData = result.data!['priceUpdate'] as Map<String, dynamic>;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handlePriceUpdate(priceData);
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: AppBar(
            title: Text(widget.symbol),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.company,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // --- Line Chart ---
                SizedBox(
                  height: 200,
                  child: historicalPrices.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (int i = 0; i < historicalPrices.length; i++)
                                    FlSpot(i.toDouble(), historicalPrices[i]['price'] as double),
                                ],
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 2,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Price',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\$${currentPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: flashColor ?? (isPricePositive ? Colors.green : Colors.red),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _getPercentageChange(),
                            style: TextStyle(
                              color: isPricePositive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => updateQuantity(quantity - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: handleCustomQuantity,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => updateQuantity(quantity + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: stockId == null
                            ? null
                            : () {
                                // TODO: Use stockId for buy mutation
                                debugPrint("Buy stockId: $stockId, qty: $quantity");
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Buy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: stockId == null
                            ? null
                            : () {
                                // TODO: Use stockId for sell mutation
                                debugPrint("Sell stockId: $stockId, qty: $quantity");
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Sell',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
