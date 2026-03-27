import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  static const String _accessTokenKey = 'access_token';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<void> clearAccessToken() async {
    await _secureStorage.delete(key: _accessTokenKey);
  }
}
