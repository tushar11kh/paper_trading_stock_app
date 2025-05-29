import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';

final loginProvider = StateNotifierProvider<LoginNotifier, AsyncValue<void>>(
  (ref) => LoginNotifier(ref),
);

class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final _secureStorage = const FlutterSecureStorage();

  LoginNotifier(this.ref) : super(const AsyncValue.data(null));

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

  Future<void> login(
      {required GraphQLClient client,
      required String email,
      required String password,
      required BuildContext context}) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    state = const AsyncValue.loading();

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
        await _secureStorage.write(key: 'auth_token', value: token);
        await _secureStorage.write(key: 'auth_user_id', value: userId);

        // Update global state with userId
        context.go('/');
      }
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }
}