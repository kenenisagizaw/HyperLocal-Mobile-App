import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../local/local_storage.dart';
import '../../models/service_request_model.dart';

class RequestApi {
  RequestApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;
  final LocalStorage _storage = LocalStorage();

  Future<ServiceRequest> createRequest({
    required String title,
    required String description,
    required String category,
    required String location,
    double? budget,
    double? latitude,
    double? longitude,
    DateTime? preferredDate,
    DateTime? expiresAt,
    List<XFile> images = const [],
  }) async {
    final dio = await _dioFuture;
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'serviceCategory': category,
      'category': category,
      'location': location,
      if (budget != null) 'budget': budget,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (preferredDate != null)
        'preferredDate': preferredDate.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
    };

    if (images.isNotEmpty) {
      final formData = FormData.fromMap({
        ...payload,
        'images[]': [
          for (final file in images)
            await MultipartFile.fromFile(file.path, filename: file.name),
        ],
      });
      final response = await dio.post(
        ApiConstants.serviceRequests,
        data: formData,
        options: await _authOptions(),
      );
      return _parseRequest(response.data);
    }

    final response = await dio.post(
      ApiConstants.serviceRequests,
      data: payload,
      options: await _authOptions(),
    );
    return _parseRequest(response.data);
  }

  Future<List<ServiceRequest>> getRequests({
    String? category,
    String? city,
    String? status,
    int? take,
    int? skip,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      ApiConstants.serviceRequests,
      options: await _authOptions(),
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (city != null && city.isNotEmpty) 'city': city,
        if (status != null && status.isNotEmpty) 'status': status,
        if (take != null) 'take': take,
        if (skip != null) 'skip': skip,
      },
    );
    return _parseRequestList(response.data);
  }

  Future<List<ServiceRequest>> getMyRequests() async {
    final dio = await _dioFuture;
    final response = await dio.get(
      ApiConstants.serviceRequestsMine,
      options: await _authOptions(),
    );
    return _parseRequestList(response.data);
  }

  Future<ServiceRequest> getRequestById(String id) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      '${ApiConstants.serviceRequests}/$id',
      options: await _authOptions(),
    );
    return _parseRequest(response.data);
  }

  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  ServiceRequest _parseRequest(dynamic data) {
    final map = _unwrapMap(data);
    final requestData = map['data'] is Map<String, dynamic>
        ? map['data'] as Map<String, dynamic>
        : map;
    return ServiceRequest.fromJson(requestData);
  }

  List<ServiceRequest> _parseRequestList(dynamic data) {
    final map = _unwrapMap(data);
    final list = _extractList(map);
    return list
        .whereType<Map>()
        .map((item) => ServiceRequest.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  List<dynamic> _extractList(Map<String, dynamic> map) {
    final direct = map['data'] ?? map['items'] ?? map['requests'];
    if (direct is List) {
      return direct;
    }

    if (direct is Map) {
      final nested = direct['items'] ?? direct['requests'] ?? direct['data'];
      if (nested is List) {
        return nested;
      }
    }

    return const [];
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }
}
