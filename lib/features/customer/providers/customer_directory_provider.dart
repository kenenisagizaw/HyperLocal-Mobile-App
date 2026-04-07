import 'package:flutter/material.dart';

import '../../../core/utils/api_client.dart';
import '../../../data/datasources/remote/user_api.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/customer_repository.dart';

class CustomerDirectoryProvider extends ChangeNotifier {
  CustomerDirectoryProvider({required this.repository});

  final CustomerRepository repository;

  List<UserModel> _customers = [];
  bool _isLoading = false;

  List<UserModel> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _customers = await repository.fetchCustomers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UserModel? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return repository.getCustomerById(id);
    }
  }

  void upsertCustomer(UserModel customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index == -1) {
      _customers.add(customer);
    } else {
      _customers[index] = customer;
    }
    repository.upsertCustomer(customer);
    notifyListeners();
  }

  Future<UserModel?> fetchCustomerById(String id) async {
    try {
      final dio = await ApiClient.create();
      final api = UserApi(dio);
      final response = await api.getUserById(id);
      final payload = _unwrapData(response);
      final userJson = _extractUser(payload) ?? _extractUser(response);
      if (userJson == null) {
        return null;
      }
      final customer = UserModel.fromJson(userJson);
      upsertCustomer(customer);
      return customer;
    } catch (_) {
      return null;
    }
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

  Map<String, dynamic>? _extractUser(Map<String, dynamic> data) {
    final user = data['user'] ?? data['customer'] ?? data['profile'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    if (user is Map) {
      return user.cast<String, dynamic>();
    }
    return null;
  }
}
