import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _secureStorage = FlutterSecureStorage();

void saveToken(String token) async {
  await _secureStorage.write(key: 'auth_token', value: token);
}