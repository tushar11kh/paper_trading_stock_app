import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:PaperTradeApp/common/widgets/stock_card.dart';
import 'package:PaperTradeApp/common/widgets/stock_gains_card.dart';
import 'package:PaperTradeApp/screens/stock_detail_screen.dart';
import 'package:PaperTradeApp/providers/homeScreenProvider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;

  void _navigateToStockDetail(Map<String, dynamic> stock) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockDetailScreen(
          symbol: stock['symbol'],
          company: stock['name'],
          initialPrice: stock['price'],
          initialChange: stock['change'] ?? '+0.00%',
          isPositive: stock['change']?.startsWith('+') ?? true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeScreenProvider);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _isSearchFocused = false;
        });
        ref.read(homeScreenProvider.notifier).clearSearch();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Welcome to Paper Trade",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    FocusScope(
                      onFocusChange: (hasFocus) {
                        setState(() {
                          _isSearchFocused = hasFocus;
                        });
                        if (!hasFocus) {
                          ref.read(homeScreenProvider.notifier).clearSearch();
                        }
                      },
                      child: TextField(
                        controller: _searchController,
                        onChanged: (query) => ref.read(homeScreenProvider.notifier).onSearchChanged(query),
                        decoration: InputDecoration(
                          hintText: 'Search for a stock...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const StockGainsCard(),
                    const SizedBox(height: 24),
                    const Text(
                      "Most Traded Today",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    homeState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : homeState.randomStocks.isNotEmpty
                            ? Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: StockCard(
                                          name: homeState.randomStocks[0]['symbol'],
                                          company: homeState.randomStocks[0]['name'],
                                          fallbackPrice: homeState.randomStocks[0]['price'],
                                          change: homeState.randomStocks[0]['change'] ?? "+0.00%",
                                          isPositive: homeState.randomStocks[0]['change']?.startsWith('+') ?? true,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: StockCard(
                                          name: homeState.randomStocks[1]['symbol'],
                                          company: homeState.randomStocks[1]['name'],
                                          fallbackPrice: homeState.randomStocks[1]['price'],
                                          change: homeState.randomStocks[1]['change'] ?? "+0.00%",
                                          isPositive: homeState.randomStocks[1]['change']?.startsWith('+') ?? true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: StockCard(
                                          name: homeState.randomStocks[2]['symbol'],
                                          company: homeState.randomStocks[2]['name'],
                                          fallbackPrice: (homeState.randomStocks[2]['price'] as num).toDouble(),
                                          change: homeState.randomStocks[2]['change'] ?? "+0.00%",
                                          isPositive: homeState.randomStocks[2]['change']?.startsWith('+') ?? true,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: StockCard(
                                          name: homeState.randomStocks[3]['symbol'],
                                          company: homeState.randomStocks[3]['name'],
                                          fallbackPrice: (homeState.randomStocks[3]['price'] as num).toDouble(),
                                          change: homeState.randomStocks[3]['change'] ?? "+0.00%",
                                          isPositive: homeState.randomStocks[3]['change']?.startsWith('+') ?? true,
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
                    if (!homeState.isLoading && homeState.randomStocks.length > 7)
                      StockCard(
                        name: homeState.randomStocks[7]['symbol'],
                        company: homeState.randomStocks[7]['name'],
                        fallbackPrice: homeState.randomStocks[7]['price'],
                        change: homeState.randomStocks[7]['change'] ?? "+0.00%",
                        isPositive: homeState.randomStocks[7]['change']?.startsWith('+') ?? true,
                      ),
                    const SizedBox(height: 12),
                    if (!homeState.isLoading && homeState.randomStocks.length > 9)
                      StockCard(
                        name: homeState.randomStocks[9]['symbol'],
                        company: homeState.randomStocks[9]['name'],
                        fallbackPrice: homeState.randomStocks[9]['price'],
                        change: homeState.randomStocks[9]['change'] ?? "+0.00%",
                        isPositive: homeState.randomStocks[9]['change']?.startsWith('+') ?? true,
                      ),
                  ],
                ),
              ),
              if (_isSearchFocused && homeState.searchResults.isNotEmpty)
                Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: homeState.searchResults.take(4).map((stock) => ListTile(
                              title: Text(stock['name']),
                              subtitle: Text(stock['symbol']),
                              onTap: () => _navigateToStockDetail(stock),
                            )).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
