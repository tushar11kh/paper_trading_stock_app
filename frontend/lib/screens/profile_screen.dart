import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String getUserDetailsQuery = """
    query GetUserDetails(
      \$userId: ID!
    ) {
      getUserDetails(userId: \$userId) {
        id
        email
        balance
      }
    }
  """;

  Future<String?> _getUserId() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'auth_user_id'); // Replace with actual key for user ID
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token'); // Clear the auth token
    await storage.delete(key: 'auth_user_id'); // Clear the user ID

    if (mounted) {
      context.go('/login'); // Navigate to the login screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('User not logged in.'));
        }

        final userId = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
          ),
          body: Column(
            children: [
              Expanded(
                child: Query(
                  options: QueryOptions(
                    document: gql(getUserDetailsQuery),
                    variables: {'userId': userId},
                  ),
                  builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
                    if (result.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (result.hasException) {
                      return Center(
                        child: Text('Error: ${result.exception.toString()}'),
                      );
                    }

                    final user = result.data?['getUserDetails'];

                    if (user == null) {
                      return const Center(child: Text('No user data available.'));
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID: ${user['id']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${user['email']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Balance: ₹${user['balance']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _logout,
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}