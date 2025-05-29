import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLConfig {
  static final HttpLink httpLink = HttpLink(
    'http://localhost:4000/graphql', // Replace with your backend URL
  );

  static final _secureStorage = FlutterSecureStorage();
  

  static Future<GraphQLClient> initializeClient() async {
    // Retrieve the token from secure storage
    final token = await _secureStorage.read(key: 'auth_token');

    // Add the token to the headers
    final AuthLink authLink = AuthLink(
      getToken: () async => token != null ? 'Bearer $token' : null,
    );

    // Combine the AuthLink with the HttpLink
    final Link link = authLink.concat(httpLink);

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }
}