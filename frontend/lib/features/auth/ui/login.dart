import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final String loginMutation = """
    mutation Login(\$input: LoginInput!) {
      login(input: \$input) {
        token
        user {
          id
          email
        }
      }
    }
  """;

  final _secureStorage = const FlutterSecureStorage();

void _login(GraphQLClient client) async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all fields')),
    );
    return;
  }

  try {
    final result = await client.mutate(
      MutationOptions(
        document: gql(loginMutation),
        variables: {
          "input": {"email": email, "password": password},
        },
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final token = result.data?['login']['token'];
    final userId = result.data?['login']['user']['id'];

    if (token != null && userId != null) {
      // Save the token and userId to secure storage
      await _secureStorage.write(key: 'auth_token', value: token);
      await _secureStorage.write(key: 'auth_user_id', value: userId);

      // Navigate to the home screen
      context.go('/');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final client = GraphQLProvider.of(context).value;
                _login(client);
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}