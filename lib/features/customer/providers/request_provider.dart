import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/service_request_model.dart';
import '../../../data/repositories/request_repository.dart';

class RequestProvider extends ChangeNotifier {
  RequestProvider({required this.repository});

  final RequestRepository repository;

  List<ServiceRequest> _requests = [];
  bool _isLoading = false;
  String? errorMessage;
  int? lastStatusCode;

  List<ServiceRequest> get requests => _requests;
  bool get isLoading => _isLoading;

  Future<void> loadRequests({
    String? category,
    String? city,
    String? status,
    int? take,
    int? skip,
  }) async {
    _isLoading = true;
    errorMessage = null;
    lastStatusCode = null;
    notifyListeners();
    try {
      _requests = await repository.fetchRequests(
        category: category,
        city: city,
        status: status,
        take: take,
        skip: skip,
      );
    } on DioException catch (error) {
      lastStatusCode = error.response?.statusCode;
      errorMessage = _extractErrorMessage(error);
      _requests = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyRequests() async {
    _isLoading = true;
    errorMessage = null;
    lastStatusCode = null;
    notifyListeners();
    try {
      _requests = await repository.fetchMyRequests();
    } on DioException catch (error) {
      lastStatusCode = error.response?.statusCode;
      errorMessage = _extractErrorMessage(error);
      _requests = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ServiceRequest?> createRequest({
    required String title,
    required String description,
    required String category,
    required String location,
    double? budget,
    double? latitude,
    double? longitude,
    List<XFile> images = const [],
  }) async {
    _isLoading = true;
    errorMessage = null;
    lastStatusCode = null;
    notifyListeners();
    try {
      final created = await repository.createRequest(
        title: title,
        description: description,
        category: category,
        location: location,
        budget: budget,
        latitude: latitude,
        longitude: longitude,
        images: images,
      );
      final resolved = (created.photoPaths.isEmpty && images.isNotEmpty)
          ? created.copyWith(
              photoPaths: images.map((file) => file.path).toList(),
            )
          : created;
      _requests = [resolved, ..._requests];
      return resolved;
    } on DioException catch (error) {
      lastStatusCode = error.response?.statusCode;
      errorMessage = _extractErrorMessage(error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ServiceRequest?> fetchRequestById(String id) async {
    if (id.isEmpty) return null;
    _isLoading = true;
    errorMessage = null;
    lastStatusCode = null;
    notifyListeners();
    try {
      final request = await repository.fetchRequestById(id);
      final index = _requests.indexWhere((r) => r.id == id);
      if (index == -1) {
        _requests = [request, ..._requests];
      } else {
        _requests[index] = request;
      }
      return request;
    } on DioException catch (error) {
      lastStatusCode = error.response?.statusCode;
      errorMessage = _extractErrorMessage(error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message.toString();
      }
    }
    return error.message;
  }

  List<ServiceRequest> getCustomerRequests(String customerId) {
    return _requests.where((r) => r.customerId == customerId).toList();
  }

  bool updateStatus(String requestId, RequestStatus status) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      return false;
    }
    _requests[index].status = status;
    notifyListeners();
    return true;
  }
}
