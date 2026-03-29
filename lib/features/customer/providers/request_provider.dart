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
    notifyListeners();
    try {
      _requests = await repository.fetchRequests(
        category: category,
        city: city,
        status: status,
        take: take,
        skip: skip,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      _requests = await repository.fetchMyRequests();
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
      _requests = [created, ..._requests];
      return created;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ServiceRequest> getCustomerRequests(String customerId) {
    return _requests.where((r) => r.customerId == customerId).toList();
  }

  void updateStatus(String requestId, RequestStatus status) {
    final req = _requests.firstWhere((r) => r.id == requestId);
    req.status = status;
    notifyListeners();
  }
}
