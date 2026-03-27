import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';

class ProviderApi {
  final Dio _dio;

  ProviderApi(this._dio);

  Future<Map<String, dynamic>> updateProviderProfile({
    required String accessToken,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.put(
      ApiConstants.providerProfile,
      data: data,
      options: Options(headers: _authHeaders(accessToken)),
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> uploadPortfolio({
    required String accessToken,
    required XFile file,
  }) async {
    final formData = FormData.fromMap({
      'portfolio': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    final response = await _dio.post(
      ApiConstants.providerPortfolio,
      data: formData,
      options: Options(headers: _authHeaders(accessToken)),
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> uploadCertification({
    required String accessToken,
    required XFile file,
  }) async {
    final formData = FormData.fromMap({
      'certification': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      ),
    });

    final response = await _dio.post(
      ApiConstants.providerCertifications,
      data: formData,
      options: Options(headers: _authHeaders(accessToken)),
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getProviders({
    String? serviceCategory,
    String? city,
    int? skip,
    int? take,
  }) async {
    final response = await _dio.get(
      ApiConstants.providers,
      queryParameters: {
        if (serviceCategory != null && serviceCategory.isNotEmpty)
          'serviceCategory': serviceCategory,
        if (city != null && city.isNotEmpty) 'city': city,
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
      },
    );

    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getProviderById(String id) async {
    final response = await _dio.get('${ApiConstants.providers}/$id');
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
