import 'package:flutter/material.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? currentUser;

  void login(UserModel user) {
    currentUser = user;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  bool get isCustomer => currentUser?.role == UserRole.customer;
  bool get isProvider => currentUser?.role == UserRole.provider;
}
