// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();

  final httpLink = HttpLink('http://localhost:4000/graphql');

  final wsLink = WebSocketLink(
    'ws://localhost:4000/graphql',
    config: const SocketClientConfig(
      autoReconnect: true,
      inactivityTimeout: Duration(seconds: 300),
    ),
  );

  // Combine HTTP and WebSocket links using split
  final link = Link.split(
    (request) => request.isSubscription,
    wsLink,
    httpLink,
  );

  final client = GraphQLClient(
    cache: GraphQLCache(store: HiveStore()),
    link: link,
  );

  runApp(
    ProviderScope(
      child: GraphQLProvider(
        client: ValueNotifier(client),
        child: const PaperTradeRoot(),
      ),
    ),
  );
}

class PaperTradeRoot extends StatelessWidget {
  const PaperTradeRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      routerConfig: router,
    );
  }
}
