import 'package:image_picker/image_picker.dart';

import '../datasources/local/local_storage.dart';
import '../datasources/remote/provider_api.dart';
import '../datasources/remote/user_api.dart';
import '../models/user_model.dart';

class ProfileRepository {
  final UserApi _userApi;
  final ProviderApi _providerApi;
  final LocalStorage _storage;

  ProfileRepository({
    required UserApi userApi,
    required ProviderApi providerApi,
    required LocalStorage storage,
  }) : _userApi = userApi,
       _providerApi = providerApi,
       _storage = storage;

  Future<UserModel> getUserProfile() async {
    final token = await _requireToken();
    final response = await _userApi.getProfile(accessToken: token);
    final payload = _unwrapData(response);
    final userJson = _extractUser(payload) ?? _extractUser(response);
    if (userJson == null) {
      throw StateError('User data missing from profile response');
    }

    return UserModel.fromJson(userJson);
  }

  Future<UserModel> updateUserProfile({
    required Map<String, dynamic> data,
  }) async {
    final token = await _requireToken();
    final response = await _userApi.updateProfile(
      accessToken: token,
      data: data,
    );
    final payload = _unwrapData(response);
    final userJson = _extractUser(payload) ?? _extractUser(response);
    if (userJson == null) {
      throw StateError('User data missing from update profile response');
    }

    return UserModel.fromJson(userJson);
  }

  Future<String> uploadAvatar(XFile file) async {
    final token = await _requireToken();
    final response = await _userApi.uploadAvatar(
      accessToken: token,
      file: file,
    );
    final payload = _unwrapData(response);
    final path = _extractFilePath(payload) ?? _extractFilePath(response);
    if (path == null || path.isEmpty) {
      throw StateError('Avatar upload did not return filePath');
    }
    return path;
  }

  Future<Map<String, dynamic>> updateProviderProfile({
    required Map<String, dynamic> data,
  }) async {
    final token = await _requireToken();
    final response = await _providerApi.updateProviderProfile(
      accessToken: token,
      data: data,
    );
    return _unwrapData(response);
  }

  Future<String> uploadPortfolio(XFile file) async {
    final token = await _requireToken();
    final response = await _providerApi.uploadPortfolio(
      accessToken: token,
      file: file,
    );
    final payload = _unwrapData(response);
    final path = _extractFilePath(payload) ?? _extractFilePath(response);
    if (path == null || path.isEmpty) {
      throw StateError('Portfolio upload did not return filePath');
    }
    return path;
  }

  Future<String> uploadCertification(XFile file) async {
    final token = await _requireToken();
    final response = await _providerApi.uploadCertification(
      accessToken: token,
      file: file,
    );
    final payload = _unwrapData(response);
    final path = _extractFilePath(payload) ?? _extractFilePath(response);
    if (path == null || path.isEmpty) {
      throw StateError('Certification upload did not return filePath');
    }
    return path;
  }

  Future<List<UserModel>> getProviders({
    String? serviceCategory,
    String? city,
    int? skip,
    int? take,
  }) async {
    final response = await _providerApi.getProviders(
      serviceCategory: serviceCategory,
      city: city,
      skip: skip,
      take: take,
    );
    final payload = _unwrapData(response);
    final list = _extractList(payload) ?? _extractList(response) ?? [];
    return list.map(UserModel.fromJson).toList();
  }

  Future<UserModel?> getProviderById(String id) async {
    final response = await _providerApi.getProviderById(id);
    final payload = _unwrapData(response);
    final userJson = _extractUser(payload) ?? _extractUser(response);
    if (userJson == null) {
      return null;
    }
    return UserModel.fromJson(userJson);
  }

  Future<String> _requireToken() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Access token not available');
    }
    return token;
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
    final user = data['user'] ?? data['profile'] ?? data['provider'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    if (user is Map) {
      return user.cast<String, dynamic>();
    }
    return null;
  }

  String? _extractFilePath(Map<String, dynamic> data) {
    final path = data['filePath'] ?? data['path'] ?? data['url'];
    if (path is String) {
      return path;
    }
    return null;
  }

  List<Map<String, dynamic>>? _extractList(Map<String, dynamic> data) {
    final list = data['items'] ?? data['providers'] ?? data['data'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    return null;
  }
}
