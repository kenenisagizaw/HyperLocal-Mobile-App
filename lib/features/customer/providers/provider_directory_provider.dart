import 'package:flutter/material.dart';

import '../../../core/utils/api_client.dart';
import '../../../data/datasources/remote/provider_api.dart';
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
      // Return null instead of making API call to avoid 404 errors
      // The provider will be loaded on-demand if needed
      return null;
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

  Future<UserModel?> fetchProviderById(String id) async {
    try {
      final dio = await ApiClient.create();
      final api = ProviderApi(dio);
      final response = await api.getProviderById(id);
      final payload = _unwrapData(response);
      final userJson = _extractUser(payload) ?? _extractUser(response);
      if (userJson == null) {
        return null;
      }
      final provider = UserModel.fromJson(userJson);
      upsertProvider(provider);
      return provider;
    } catch (e) {
      debugPrint('Error fetching provider $id: $e');
      // Don't throw error, just return null to handle missing providers gracefully
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
    final user = data['provider'] ?? data['user'] ?? data['profile'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    if (user is Map) {
      return user.cast<String, dynamic>();
    }
    return null;
  }
}
