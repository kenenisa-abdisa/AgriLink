import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart';
import 'email_service.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  String get userRole {
    return _supabase.auth.currentUser?.userMetadata?['role'] ?? 'buyer';
  }

  String get userName {
    return _supabase.auth.currentUser?.userMetadata?['name'] ?? 'User';
  }

  String get userEmail {
    return _supabase.auth.currentUser?.email ?? '';
  }

  String get userPhone {
    return _supabase.auth.currentUser?.userMetadata?['phone'] ?? '';
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = UserModel(
          id: response.user!.id,
          name: response.user!.userMetadata?['name'] ?? email.split('@')[0],
          email: response.user!.email ?? '',
          phone: response.user!.userMetadata?['phone'] ?? '',
          role: response.user!.userMetadata?['role'] ?? 'buyer',
          profileImage: response.user!.userMetadata?['profile_image'],
        );
        return true;
      }
      return false;
    } catch (e) {
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
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'role': role,
        },
      );

      if (response.user != null) {
        // Insert into users table
        try {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'name': name,
            'phone': phone,
            'role': role,
          });
        } catch (_) {
          // Users table insert may fail due to RLS, continue
        }

        // Wait for sign up to complete fully
        await Future.delayed(const Duration(milliseconds: 500));

        // Proactive profile creation for Farmers/Businesses (Moved outside auto sign-in)
        if (role == 'farmer' || role == 'business') {
          try {
            await _supabase.from('farmers').insert({
              'user_id': response.user!.id,
              'farm_name': '$name\'s ${role == 'business' ? 'Enterprise' : 'Farm'}',
              'is_verified': false,
              'rating': 0.0,
              'total_reviews': 0,
              'joined_date': DateTime.now().toIso8601String(),
            });
          } catch (profileError) {
            debugPrint('Initial farmer profile creation failed: $profileError');
          }
        }

        // Auto sign in after registration
        try {
          await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
        } catch (e) {
          debugPrint('Auto sign-in failed, but registration succeeded: $e');
        }

        _currentUser = UserModel(
          id: response.user!.id,
          name: name,
          email: email,
          phone: phone,
          role: role,
          profileImage: null,
        );

        // Send Welcome Notification
        try {
          await _supabase.from('notifications').insert({
            'user_id': response.user!.id,
            'title': 'Welcome to AgriLink! 👋',
            'body': 'We\'re glad to have you here. Start exploring the marketplace or meet our farmers!',
            'data': {'type': 'welcome'}
          });
          
          // Send Welcome Email
          await EmailService().sendWelcomeEmail(email, name);
        } catch (_) {}

        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      // Clear any local cache if exists (optional but good for 'fresh start')
    } catch (_) {}
  }

  Future<void> deleteAccount() async {
    try {
      // Call the RPC function we created to delete the user from auth.users
      await _supabase.rpc('delete_user_account');
      await _supabase.auth.signOut();
      _currentUser = null;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({String? name, String? phone, String? profileImage}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (profileImage != null) data['profile_image'] = profileImage;

      await _supabase.auth.updateUser(UserAttributes(data: data));

      // Also update users table
      try {
        final updates = <String, dynamic>{};
        if (name != null) updates['name'] = name;
        if (phone != null) updates['phone'] = phone;
        if (profileImage != null) updates['profile_image'] = profileImage;
        await _supabase.from('users').update(updates).eq('id', currentUserId);
      } catch (_) {}
    } catch (e) {
      rethrow;
    }
  }

  /// Updates user role in metadata and users table
  Future<void> updateRole(String role) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(data: {'role': role}));
      try {
        await _supabase.from('users').update({'role': role}).eq('id', currentUserId);
      } catch (_) {}
      loadCurrentUser();
    } catch (e) {
      rethrow;
    }
  }

  /// Checks ground truth in the database and fixes auth metadata if misaligned
  Future<String> syncRoleWithDatabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'buyer';

    final currentMetadataRole = user.userMetadata?['role'] ?? 'buyer';

    // 1. Check 'users' table (Master Record)
    final userRecord = await _supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (userRecord != null) {
      final dbRole = userRecord['role'] as String;
      if (dbRole != currentMetadataRole) {
        await updateRole(dbRole);
        return dbRole;
      }
      return dbRole;
    }

    // 2. Fallback: Check if they have a farmer profile but role is buyer
    if (currentMetadataRole == 'buyer') {
      final farmerRecord = await _supabase
          .from('farmers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (farmerRecord != null) {
        await updateRole('farmer');
        return 'farmer';
      }
    }

    return currentMetadataRole;
  }

  /// Load current user data from metadata
  void loadCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _currentUser = UserModel(
        id: user.id,
        name: user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? '',
        email: user.email ?? '',
        phone: user.userMetadata?['phone'] ?? '',
        role: user.userMetadata?['role'] ?? 'buyer',
        profileImage: user.userMetadata?['profile_image'],
      );
    }
  }
}