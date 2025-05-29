import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Simulate a delay for the splash screen
    await Future.delayed(const Duration(seconds: 3));

    // Check if the token exists
    final token = await _secureStorage.read(key: 'auth_token');
    final userId = await _secureStorage.read(key: 'auth_user_id');

    if (!mounted) return; // Safety check if the widget is disposed

    if (token != null && token.isNotEmpty && userId != null && userId.isNotEmpty) {
      // Validate the token with the backend
      final isValid = await _validateToken(token, userId);

      if (isValid) {
        context.go('/'); // Navigate to the home screen
        return;
      }
    }

    // If token or userId is missing or invalid, navigate to the login screen
    context.go('/login');
  }

  Future<bool> _validateToken(String token, String userId) async {
    try {
      final HttpLink httpLink = HttpLink('http://localhost:4000/graphql');

      final AuthLink authLink = AuthLink(
        getToken: () => 'Bearer $token',
      );

      final Link link = authLink.concat(httpLink);

      final GraphQLClient client = GraphQLClient(
        cache: GraphQLCache(),
        link: link,
      );

      final QueryOptions options = QueryOptions(
        document: gql(r'''
          query GetUserDetails($userId: ID!) {
            getUserDetails(userId: $userId) {
              id
              email
            }
          }
        '''),
        variables: {
          'userId': userId,
        },
      );

      final QueryResult result = await client.query(options);

      if (result.hasException) {
        print('Token validation error: ${result.exception}');
        return false;
      }

      return result.data?['getUserDetails'] != null;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 77, 169, 222),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Paper Trade',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Litera',
                fontSize: MediaQuery.of(context).size.width * 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}