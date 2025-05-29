import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:PaperTradeApp/graphql/graphql_client.dart';

// State class to hold all the home screen data
class HomeScreenState {
  final List<Map<String, dynamic>> randomStocks;
  final List<Map<String, dynamic>> allStocks;
  final bool isLoading;
  final List<Map<String, dynamic>> searchResults;

  HomeScreenState({
    required this.randomStocks,
    required this.allStocks,
    required this.isLoading,
    required this.searchResults,
  });

  HomeScreenState copyWith({
    List<Map<String, dynamic>>? randomStocks,
    List<Map<String, dynamic>>? allStocks,
    bool? isLoading,
    List<Map<String, dynamic>>? searchResults,
  }) {
    return HomeScreenState(
      randomStocks: randomStocks ?? this.randomStocks,
      allStocks: allStocks ?? this.allStocks,
      isLoading: isLoading ?? this.isLoading,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

final homeScreenProvider =
    StateNotifierProvider<HomescreenNotifier, HomeScreenState>(
  (ref) => HomescreenNotifier(),
);

class HomescreenNotifier extends StateNotifier<HomeScreenState> {
  HomescreenNotifier()
      : super(HomeScreenState(
          randomStocks: [],
          allStocks: [],
          isLoading: true,
          searchResults: [],
        )) {
    fetchRandomStocks();
  }

  List<int> _getUniqueRandomIndexes(int max, int count) {
    final random = Random();
    final indexes = <int>{};
    while (indexes.length < count) {
      indexes.add(random.nextInt(max));
    }
    return indexes.toList();
  }

  Future<void> fetchRandomStocks() async {
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
      final client = await GraphQLConfig.initializeClient();
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
        final allStocksList = stocks.map((stock) => stock as Map<String, dynamic>).toList();
        final randomIndexes = _getUniqueRandomIndexes(stocks.length, 10);
        final randomStocksList = randomIndexes
            .map((index) => stocks[index] as Map<String, dynamic>)
            .toList();

        state = state.copyWith(
          allStocks: allStocksList,
          randomStocks: randomStocksList,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print('Error fetching stock data: $e');
    }
  }

  void onSearchChanged(String query) {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: []);
      return;
    }

    final results = state.allStocks
        .where((stock) =>
            stock['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            stock['symbol'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();

    state = state.copyWith(searchResults: results);
  }

  void clearSearch() {
    state = state.copyWith(searchResults: []);
  }
  
}