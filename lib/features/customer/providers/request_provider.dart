import 'package:flutter/material.dart';

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

  Future<void> loadRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      _requests = await repository.fetchRequests();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRequest(ServiceRequest request) async {
    _isLoading = true;
    notifyListeners();
    try {
      await repository.createRequest(request);
      _requests = await repository.fetchRequests();
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
