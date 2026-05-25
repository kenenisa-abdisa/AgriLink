import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _adminService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _adminService.logout();
    _user = null;
    notifyListeners();
  }
}
