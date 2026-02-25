import 'package:flutter/material.dart';

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
}
