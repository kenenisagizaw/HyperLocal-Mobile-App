import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/api_client.dart';
import '../../../data/datasources/local/local_storage.dart';
import '../../../data/datasources/remote/auth_api.dart';
import '../../../data/datasources/remote/provider_api.dart';
import '../../../data/datasources/remote/user_api.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_repository.dart';

///import 'package:google_maps_flutter/google_maps_flutter.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;
  int? lastStatusCode;

  AuthRepository? _repository;
  ProfileRepository? _profileRepository;
  late final Future<void> _initFuture;

  AuthProvider({this.currentUser}) {
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    final dio = await ApiClient.create();
    final storage = LocalStorage();
    final api = AuthApi(dio);
    _repository = AuthRepository(api: api, storage: storage);
    _profileRepository = ProfileRepository(
      userApi: UserApi(dio),
      providerApi: ProviderApi(dio),
      storage: storage,
    );
  }

  Future<bool> login({required String email, required String password}) async {
    return _runAuthAction(() async {
      await _ensureRepository();
      await ApiClient.clearSession();
      final user = await _repository!.login(email: email, password: password);
      await _ensureTokenStored();
      currentUser = user;
      notifyListeners();
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    XFile? idDocument,
  }) async {
    return _runAuthAction(() async {
      await _ensureRepository();
      await ApiClient.clearSession();
      final user = await _repository!.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        idDocument: idDocument,
      );
      await _ensureTokenStored();
      currentUser = user;
      notifyListeners();
    });
  }

  Future<void> logout() async {
    await _ensureRepository();
    await _repository!.logout();
    await ApiClient.clearSession();
    currentUser = null;
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    await _initFuture;
    try {
      await _ensureRepository();
      final user = await _repository!.getCurrentUser();
      currentUser = user;
      notifyListeners();
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        try {
          await _repository!.refreshToken();
          final user = await _repository!.getCurrentUser();
          currentUser = user;
          notifyListeners();
          return true;
        } catch (_) {
          await _repository!.logout();
          currentUser = null;
          notifyListeners();
          return false;
        }
      }
      return false;
    } on StateError {
      return false;
    }
  }

  Future<bool> refreshToken() async {
    return _runAuthAction(() async {
      await _ensureRepository();
      await _repository!.refreshToken();
    });
  }

  Future<bool> sendEmailVerificationCode() async {
    return _runAuthAction(() async {
      await _ensureRepository();
      await _repository!.sendEmailVerificationCode();
    });
  }

  Future<bool> verifyEmailCode({required String code}) async {
    return _runAuthAction(() async {
      await _ensureRepository();
      await _repository!.verifyEmailCode(code: code);
    });
  }

  Future<bool> forgotPassword({required String email}) async {
    return _runAuthAction(() async {
      await _ensureRepository();
      await _repository!.forgotPassword(email: email);
    });
  }

  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    return _runAuthAction(() async {
      await _ensureRepository();
      await _repository!.resetPassword(token: token, password: password);
    });
  }

  Future<bool> loginWithGoogle({required String idToken, String? role}) async {
    return _runAuthAction(() async {
      await _ensureRepository();
      await ApiClient.clearSession();
      final user = await _repository!.loginWithGoogle(
        idToken: idToken,
        role: role,
      );
      await _ensureTokenStored();
      currentUser = user;
      notifyListeners();
    });
  }

  Future<bool> uploadIdentity({
    required XFile idDocument,
    required XFile selfie,
  }) async {
    return _runAuthAction(() async {
      await _ensureRepository();
      await _repository!.uploadIdentity(idDocument: idDocument, selfie: selfie);
    });
  }

  Future<Map<String, dynamic>?> getIdentityStatus() async {
    return _runAuthValue(() async {
      await _ensureRepository();
      return _repository!.getIdentityStatus();
    });
  }

  Future<bool> loadUserProfile() async {
    return _runAuthAction(() async {
      await _ensureProfileRepository();
      final user = await _profileRepository!.getUserProfile();
      currentUser = user;
      notifyListeners();
    });
  }

  Future<bool> updateUserProfile({
    required String name,
    required String phoneNumber,
    String? city,
    String? address,
    String? bio,
    XFile? avatarFile,
  }) async {
    return _runAuthAction(() async {
      await _ensureProfileRepository();
      String? avatarPath;
      if (avatarFile != null) {
        avatarPath = await _profileRepository!.uploadAvatar(avatarFile);
      }

      final payload = <String, dynamic>{
        'name': name,
        'phoneNumber': phoneNumber,
        if (city != null && city.isNotEmpty) 'city': city,
        if (address != null && address.isNotEmpty) 'address': address,
        if (bio != null && bio.isNotEmpty) 'bio': bio,
        if (avatarPath != null) 'avatarUrl': avatarPath,
      };

      final user = await _profileRepository!.updateUserProfile(data: payload);
      currentUser = user;
      notifyListeners();
    });
  }

  Future<bool> updateProviderProfileRemote({
    String? businessName,
    String? serviceCategory,
    num? hourlyRate,
    num? serviceRadius,
    String? availabilityStatus,
    double? latitude,
    double? longitude,
    List<String>? portfolioUrls,
    List<String>? certificationsUrls,
  }) async {
    return _runAuthAction(() async {
      await _ensureProfileRepository();
      final payload = <String, dynamic>{
        if (businessName != null && businessName.isNotEmpty)
          'businessName': businessName,
        if (serviceCategory != null && serviceCategory.isNotEmpty)
          'serviceCategory': serviceCategory,
        if (hourlyRate != null) 'hourlyRate': hourlyRate,
        if (serviceRadius != null) 'serviceRadius': serviceRadius,
        if (availabilityStatus != null && availabilityStatus.isNotEmpty)
          'availabilityStatus': availabilityStatus,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (portfolioUrls != null && portfolioUrls.isNotEmpty)
          'portfolioUrls': portfolioUrls,
        if (certificationsUrls != null && certificationsUrls.isNotEmpty)
          'certificationsUrls': certificationsUrls,
      };

      await _profileRepository!.updateProviderProfile(data: payload);
    });
  }

  void setCurrentUser(UserModel user) {
    currentUser = user;
    notifyListeners();
  }

  // Update provider profile
  void updateProviderProfile({
    required String name,
    required String phone,
    String? email,
    String? profileImage,
    String? bio,
  }) {
    if (currentUser != null) {
      currentUser = currentUser!.copyWith(
        name: name,
        phone: phone,
        email: email,
        profilePicture: profileImage,
        bio: bio,
      );
      notifyListeners();
    }
  }

  void updateProviderVerification({
    required String nationalId,
    required String businessLicense,
    required String educationDoc,
    required String location,
    required double latitude,
    required double longitude,
    bool isVerified = false,
  }) {
    if (currentUser != null) {
      currentUser = currentUser!.copyWith(
        nationalId: nationalId,
        businessLicense: businessLicense,
        educationDocument: educationDoc,
        location: location,
        latitude: latitude,
        longitude: longitude,
        isVerified: isVerified,
      );
      notifyListeners();
    }
  }

  // Update customer profile
  void updateCustomerProfile({
    required String name,
    required String phone,
    String? address,
    String? profileImage,
    double? latitude,
    double? longitude,
  }) {
    if (currentUser != null) {
      currentUser = currentUser!.copyWith(
        name: name,
        phone: phone,
        address: address,
        profilePicture: profileImage,
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
    }
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    errorMessage = null;
    lastStatusCode = null;
    _setLoading(true);
    try {
      await _initFuture;
      await action();
      return true;
    } catch (error) {
      _setError(error);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<T?> _runAuthValue<T>(Future<T> Function() action) async {
    errorMessage = null;
    lastStatusCode = null;
    _setLoading(true);
    try {
      await _initFuture;
      return await action();
    } catch (error) {
      _setError(error);
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setError(Object error) {
    if (error is DioException) {
      lastStatusCode = error.response?.statusCode;
      errorMessage = _extractErrorMessage(error) ?? error.message;
      return;
    }

    errorMessage = error.toString();
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
    return null;
  }

  Future<String?> uploadPortfolio(XFile file) async {
    return _runAuthValue(() async {
      await _ensureProfileRepository();
      return _profileRepository!.uploadPortfolio(file);
    });
  }

  Future<String?> uploadCertification(XFile file) async {
    return _runAuthValue(() async {
      await _ensureProfileRepository();
      return _profileRepository!.uploadCertification(file);
    });
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> _ensureRepository() async {
    await _initFuture;
    if (_repository == null) {
      throw StateError('AuthProvider is not initialized yet');
    }
  }

  Future<void> _ensureTokenStored() async {
    final hasToken = await _repository!.hasAccessToken();
    if (!hasToken) {
      throw StateError('Access token not stored after login');
    }
  }

  Future<void> _ensureProfileRepository() async {
    await _initFuture;
    if (_profileRepository == null) {
      // Fallback: attempt to initialize again if the first init failed.
      await _initialize();
      if (_profileRepository == null) {
        throw StateError('Profile repository is not initialized yet');
      }
    }
  }
}
