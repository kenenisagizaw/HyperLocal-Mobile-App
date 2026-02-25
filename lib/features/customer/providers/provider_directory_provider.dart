import 'package:flutter/material.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/provider_repository.dart';

class ProviderDirectoryProvider extends ChangeNotifier {
  ProviderDirectoryProvider({required this.repository});

  final ProviderRepository repository;

  List<UserModel> _providers = [];
  bool _isLoading = false;

  List<UserModel> get providers => _providers;
  bool get isLoading => _isLoading;

  Future<void> loadProviders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _providers = await repository.fetchProviders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UserModel? getProviderById(String id) {
    try {
      return _providers.firstWhere((p) => p.id == id);
    } catch (_) {
      return repository.getProviderById(id);
    }
  }

  void upsertProvider(UserModel provider) {
    final index = _providers.indexWhere((p) => p.id == provider.id);
    if (index == -1) {
      _providers.add(provider);
    } else {
      _providers[index] = provider;
    }
    repository.upsertProvider(provider);
    notifyListeners();
  }
}
