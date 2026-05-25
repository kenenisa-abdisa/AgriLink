import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farmer_model.dart';
import '../models/user_model.dart';
import '../services/cache_service.dart';

class FarmerProvider extends ChangeNotifier {
  List<FarmerModel> _farmers = [];
  bool _isLoading = false;
  bool _isOffline = false;

  List<FarmerModel> get farmers => _farmers;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;

  FarmerProvider() {
    fetchFarmers();
  }

  Future<void> fetchFarmers({bool refresh = false}) async {
    _isLoading = true;
    notifyListeners();

    // 1. Load from cache
    if (_farmers.isEmpty) {
      _farmers = CacheService.getCachedFarmers();
      notifyListeners();
    }

    // 2. Connectivity check
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (_isOffline) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // 1. Fetch all users who are farmers or businesses
      final usersResponse = await Supabase.instance.client
          .from('users')
          .select('id, name, email, phone, role, profile_image')
          .inFilter('role', ['farmer', 'business'])
          .order('name');

      final List usersData = usersResponse as List;
      final userIds = usersData.map((u) => u['id'] as String).toList();

      // 2. Fetch their corresponding farmer profiles (if any exist)
      List farmersData = [];
      if (userIds.isNotEmpty) {
        final farmersResponse = await Supabase.instance.client
            .from('farmers')
            .select()
            .inFilter('user_id', userIds);
        farmersData = farmersResponse as List;
      }

      // Create a map for quick lookup
      final farmersMap = {
        for (var f in farmersData) f['user_id']: f
      };

      // 3. Merge them manually
      _farmers = usersData.map((userJson) {
        final user = UserModel.fromJson(userJson);
        final profileJson = farmersMap[user.id];

        if (profileJson != null) {
          // Profile exists
          return FarmerModel.fromJson(profileJson, user: user);
        } else {
          // Fallback for farmers without a profile yet
          return FarmerModel(
            id: user.id, // Fallback ID
            userId: user.id,
            farmName: user.name.isNotEmpty ? '${user.name}\'s Farm' : 'New Farmer',
            isVerified: false,
            rating: 0.0,
            user: user,
          );
        }
      }).toList();

      // Update cache
      await CacheService.cacheFarmers(_farmers);
    } catch (e) {
      debugPrint('Error fetching farmers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
