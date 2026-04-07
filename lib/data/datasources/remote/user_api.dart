import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';

class UserApi {
  final Dio _dio;

  UserApi(this._dio);

  Future<Map<String, dynamic>> getProfile({required String accessToken}) async {
    final response = await _dio.get(
      ApiConstants.userProfile,
      options: Options(headers: _authHeaders(accessToken)),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.patch(
      ApiConstants.userProfile,
      data: data,
      options: Options(headers: _authHeaders(accessToken)),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> uploadAvatar({
    required String accessToken,
    required XFile file,
  }) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    final response = await _dio.post(
      ApiConstants.userProfileAvatar,
      data: formData,
      options: Options(headers: _authHeaders(accessToken)),
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    final response = await _dio.get('${ApiConstants.users}/$id');
    return _asMap(response.data);
  }

  Map<String, String> _authHeaders(String token) {
    return {'Authorization': 'Bearer $token'};
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
}
