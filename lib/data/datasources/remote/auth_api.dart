import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    XFile? idDocument,
  }) async {
    if (idDocument != null) {
      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'idDocument': await MultipartFile.fromFile(
          idDocument.path,
          filename: idDocument.name,
        ),
      });

      final response = await _dio.post(ApiConstants.register, data: formData);
      return _asMap(response.data);
    }

    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      },
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getCurrentUser({
    required String accessToken,
  }) async {
    final response = await _dio.get(
      ApiConstants.me,
      options: Options(headers: _authHeaders(accessToken)),
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> refreshToken() async {
    final response = await _dio.post(ApiConstants.refreshToken);
    return _asMap(response.data);
  }

  Future<void> logout({required String accessToken}) async {
    await _dio.post(
      ApiConstants.logout,
      options: Options(headers: _authHeaders(accessToken)),
    );
  }

  Future<Map<String, dynamic>> verifyEmailToken({required String token}) async {
    final response = await _dio.get(
      ApiConstants.verifyEmailToken,
      queryParameters: {'token': token},
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> sendEmailVerificationCode({
    required String accessToken,
  }) async {
    final response = await _dio.post(
      ApiConstants.sendEmailVerificationCode,
      options: Options(headers: _authHeaders(accessToken)),
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> verifyEmailCode({
    required String accessToken,
    required String code,
  }) async {
    final response = await _dio.post(
      ApiConstants.verifyEmailCode,
      options: Options(headers: _authHeaders(accessToken)),
      data: {'code': code},
    );

    return _asMap(response.data);
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _dio.post(
      ApiConstants.resetPassword,
      data: {'token': token, 'password': password},
    );
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String? role,
  }) async {
    final payload = <String, dynamic>{'token': idToken};
    if (role != null && role.isNotEmpty) {
      payload['role'] = role;
    }

    final response = await _dio.post(ApiConstants.googleLogin, data: payload);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> uploadIdentity({
    required String accessToken,
    required XFile idDocument,
    required XFile selfie,
  }) async {
    final formData = FormData.fromMap({
      'idDocument': await MultipartFile.fromFile(
        idDocument.path,
        filename: idDocument.name,
      ),
      'selfie': await MultipartFile.fromFile(
        selfie.path,
        filename: selfie.name,
      ),
    });

    final response = await _dio.post(
      ApiConstants.identityUpload,
      data: formData,
      options: Options(headers: _authHeaders(accessToken)),
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getIdentityStatus({
    required String accessToken,
  }) async {
    final response = await _dio.get(
      ApiConstants.identityStatus,
      options: Options(headers: _authHeaders(accessToken)),
    );

    return _asMap(response.data);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  Map<String, String> _authHeaders(String token) {
    return {'Authorization': 'Bearer $token'};
  }
}
