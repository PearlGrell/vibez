import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static final TokenStorage instance = TokenStorage._();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
  );

  TokenStorage._();

  Future<String?> get accessToken async {
    try {
      return await _secureStorage.read(key: 'access_token');
    } on PlatformException {
      await clear();
      return null;
    }
  }

  Future<void> setAccessToken(String token) async {
    await _secureStorage.write(key: 'access_token', value: token);
  }

  Future<void> clear() async {
    await _secureStorage.deleteAll();
  }
}
