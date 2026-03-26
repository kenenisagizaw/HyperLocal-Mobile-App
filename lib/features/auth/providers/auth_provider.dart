import 'package:flutter/material.dart';

import '../../../data/models/user_model.dart';

///import 'package:google_maps_flutter/google_maps_flutter.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? currentUser;

  AuthProvider({this.currentUser});

  // Example: login/mock initialization
  void login(UserModel user) {
    currentUser = user;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
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
}
