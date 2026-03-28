import 'package:image_picker/image_picker.dart';

import '../datasources/local/local_storage.dart';
import '../datasources/remote/auth_api.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthApi _api;
  final LocalStorage _storage;

  AuthRepository({required AuthApi api, required LocalStorage storage})
    : _api = api,
      _storage = storage;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.login(email: email, password: password);
    final payload = _unwrapData(response);
    final token = _extractToken(payload) ?? _extractToken(response);
    if (token == null || token.isEmpty) {
      throw StateError('Access token missing from login response');
    }

    final userJson = _extractUser(payload) ?? _extractUser(response);
    if (userJson == null) {
      throw StateError('User data missing from login response');
    }

    await _storage.saveAccessToken(token);
    return UserModel.fromJson(userJson);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    XFile? idDocument,
  }) async {
    final response = await _api.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
      idDocument: idDocument,
    );

    final payload = _unwrapData(response);
    final token = _extractToken(payload) ?? _extractToken(response);
    if (token == null || token.isEmpty) {
      throw StateError('Access token missing from register response');
    }

    final userJson = _extractUser(payload) ?? _extractUser(response);
    if (userJson == null) {
      throw StateError('User data missing from register response');
    }

    await _storage.saveAccessToken(token);
    return UserModel.fromJson(userJson);
  }

  Future<UserModel> getCurrentUser() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Access token not available');
    }

    final response = await _api.getCurrentUser(accessToken: token);
    final payload = _unwrapData(response);
    final userJson = _extractUser(payload) ?? _extractUser(response);
    if (userJson == null) {
      throw StateError('User data missing from /me response');
    }

    return UserModel.fromJson(userJson);
  }

  Future<void> refreshToken() async {
    final response = await _api.refreshToken();
    final payload = _unwrapData(response);
    final token = _extractToken(payload) ?? _extractToken(response);
    if (token == null || token.isEmpty) {
      throw StateError('Access token missing from refresh response');
    }

    await _storage.saveAccessToken(token);
  }

  Future<void> logout() async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      await _api.logout(accessToken: token);
    }
    await _storage.clearAccessToken();
  }

  Future<void> sendEmailVerificationCode() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Access token not available');
    }

    await _api.sendEmailVerificationCode(accessToken: token);
  }

  Future<void> verifyEmailCode({required String code}) async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Access token not available');
    }

    await _api.verifyEmailCode(accessToken: token, code: code);
  }

  Future<void> verifyEmailToken({required String token}) async {
    await _api.verifyEmailToken(token: token);
  }

  Future<void> forgotPassword({required String email}) async {
    await _api.forgotPassword(email: email);
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _api.resetPassword(token: token, password: password);
  }

  Future<UserModel> loginWithGoogle({
    required String idToken,
    String? role,
  }) async {
    final response = await _api.loginWithGoogle(idToken: idToken, role: role);
    final payload = _unwrapData(response);
    final token = _extractToken(payload) ?? _extractToken(response);
    if (token == null || token.isEmpty) {
      throw StateError('Access token missing from Google login response');
    }

    final userJson = _extractUser(payload) ?? _extractUser(response);
    if (userJson == null) {
      throw StateError('User data missing from Google login response');
    }

    await _storage.saveAccessToken(token);
    return UserModel.fromJson(userJson);
  }

  Future<Map<String, dynamic>> uploadIdentity({
    required XFile idDocument,
    required XFile selfie,
  }) async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Access token not available');
    }

    return _api.uploadIdentity(
      accessToken: token,
      idDocument: idDocument,
      selfie: selfie,
    );
  }

  Future<Map<String, dynamic>> getIdentityStatus() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Access token not available');
    }

    return _api.getIdentityStatus(accessToken: token);
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> data) {
    final inner = data['data'];
    if (inner is Map<String, dynamic>) {
      return inner;
    }
    if (inner is Map) {
      return inner.cast<String, dynamic>();
    }
    return data;
  }

  String? _extractToken(Map<String, dynamic> data) {
    final token = data['token'] ?? data['accessToken'];
    if (token is String) {
      return token;
    }
    return null;
  }

  Map<String, dynamic>? _extractUser(Map<String, dynamic> data) {
    final user = data['user'] ?? data['profile'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    if (user is Map) {
      return user.cast<String, dynamic>();
    }
    return null;
  }
}
