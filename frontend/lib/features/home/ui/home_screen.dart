import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:PaperTradeApp/common/widgets/stock_card.dart';
import 'package:PaperTradeApp/features/home/logic/stock_gains_card.dart';
import 'package:PaperTradeApp/core/graphql/graphql_client.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> randomStocks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRandomStocks();
  }

  Future<void> _fetchRandomStocks() async {
  const String query = r'''
    query {
      getAllStocks {
        id
        symbol
        name
        price
        isActive
      }
    }
  ''';

  try {
    final client = await GraphQLConfig.initializeClient(); // Use your config class
    final result = await client.query(
      QueryOptions(
        document: gql(query),
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final List<dynamic> stocks = result.data?['getAllStocks'] ?? [];

    if (stocks.isNotEmpty) {
      final randomIndexes = _getUniqueRandomIndexes(stocks.length, 10);
      setState(() {
        randomStocks = randomIndexes
            .map((index) => stocks[index] as Map<String, dynamic>)
            .toList();
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching stock data: $e')),
    );
  }
}


  List<int> _getUniqueRandomIndexes(int max, int count) {
    final random = Random();
    final indexes = <int>{};
    while (indexes.length < count) {
      indexes.add(random.nextInt(max));
    }
    return indexes.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Welcome to Paper Trade",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const StockGainsCard(),
              const SizedBox(height: 24),
              const Text(
                "Most Traded Today",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : randomStocks.isNotEmpty
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StockCard(
                                name: randomStocks[0]['symbol'],
                                company: randomStocks[0]['name'],
                                fallbackPrice: randomStocks[0]['price'],
                                change: randomStocks[0]['change'] ?? "+0.00%",
                                isPositive:
                                    randomStocks[0]['change']?.startsWith(
                                      '+',
                                    ) ??
                                    true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StockCard(
                                name: randomStocks[1]['symbol'],
                                company: randomStocks[1]['name'],
                                fallbackPrice: randomStocks[1]['price'],
                                change: randomStocks[1]['change'] ?? "+0.00%",
                                isPositive:
                                    randomStocks[1]['change']?.startsWith(
                                      '+',
                                    ) ??
                                    true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: StockCard(
                                name: randomStocks[2]['symbol'],
                                company: randomStocks[2]['name'],
                                fallbackPrice: randomStocks[2]['price'],
                                change: randomStocks[2]['change'] ?? "+0.00%",
                                isPositive:
                                    randomStocks[2]['change']?.startsWith(
                                      '+',
                                    ) ??
                                    true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StockCard(
                                name: randomStocks[3]['symbol'],
                                company: randomStocks[3]['name'],
                                fallbackPrice: randomStocks[3]['price'],
                                change: randomStocks[3]['change'] ?? "+0.00%",
                                isPositive:
                                    randomStocks[3]['change']?.startsWith(
                                      '+',
                                    ) ??
                                    true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const Text("No stock data available"),
              const SizedBox(height: 24),
              const Text(
                "Watchlist",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (!isLoading && randomStocks.length > 7) 
                StockCard(
                  name: randomStocks[7]['symbol'],
                  company: randomStocks[7]['name'],
                  fallbackPrice: randomStocks[7]['price'],
                  change: randomStocks[7]['change'] ?? "+0.00%",
                  isPositive:
                      randomStocks[7]['change']?.startsWith('+') ?? true,
                ),
              const SizedBox(height: 12),
              if (!isLoading && randomStocks.length > 9)
                StockCard(
                  name: randomStocks[9]['symbol'],
                  company: randomStocks[9]['name'],
                  fallbackPrice: randomStocks[9]['price'],
                  change: randomStocks[9]['change'] ?? "+0.00%",
                  isPositive:
                      randomStocks[9]['change']?.startsWith('+') ?? true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
