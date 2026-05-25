import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  AuthService get authService => _authService;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authService.isAuthenticated;

  UserModel? get currentUser => _authService.currentUser;
  String get userRole => _authService.userRole;
  String get userName => _authService.userName;
  String get userEmail => _authService.userEmail;
  String get userPhone => _authService.userPhone;
  String? get userProfileImage => _authService.currentUser?.profileImage;
  String get currentUserId => _authService.currentUserId;

  /// Initialize and load current user
  void init() {
    _authService.loadCurrentUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.deleteAccount();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? name, String? phone, String? profileImage}) async {
    try {
      await _authService.updateProfile(name: name, phone: phone, profileImage: profileImage);
      _authService.loadCurrentUser();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncRole() async {
    try {
      await _authService.syncRoleWithDatabase();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateRole(String role) async {
    try {
      await _authService.updateRole(role);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
