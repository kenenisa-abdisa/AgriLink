import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/farmer_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // --- Authentication ---
  
  Future<UserModel?> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Fetch user profile from public.users to check role
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      final user = UserModel.fromJson(userData);
      
      if (user.role != 'admin') {
        await _supabase.auth.signOut();
        throw Exception('Unauthorized: Admin access only.');
      }
      return user;
    }
    return null;
  }

  Future<void> logout() => _supabase.auth.signOut();

  // --- Dashboard Stats ---

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final farmersRes = await _supabase.from('farmers').select('id');
    final farmersCount = (farmersRes as List).length;

    final buyersRes = await _supabase
        .from('users')
        .select('id')
        .eq('role', 'buyer');
    final buyersCount = (buyersRes as List).length;

    final productsRes = await _supabase.from('products').select('id');
    final productsCount = (productsRes as List).length;
    final orders = await _supabase.from('orders').select('total_amount, status, created_at');
    
    double totalRevenue = 0;
    int ordersCount = orders.length;
    int registrationsToday = 0;
    final now = DateTime.now();

    for (final order in orders) {
      if (order['status'] == 'delivered') {
        totalRevenue += (order['total_amount'] as num).toDouble();
      }
    }

    // New registrations today
    final users = await _supabase.from('users').select('created_at');
    for (final u in users) {
      final createdAt = DateTime.parse(u['created_at']);
      if (createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day) {
        registrationsToday++;
      }
    }

    return {
      'totalFarmers': farmersCount,
      'totalBuyers': buyersCount,
      'totalProducts': productsCount,
      'totalOrders': ordersCount,
      'totalRevenue': totalRevenue,
      'registrationsToday': registrationsToday,
    };
  }

  // --- Farmer Management ---

  Future<List<FarmerModel>> fetchFarmers() async {
    final data = await _supabase.from('farmers').select('*, users(*)').order('joined_date', ascending: false);
    return (data as List).map((json) => FarmerModel.fromJson(json)).toList();
  }

  Future<void> verifyFarmer(String farmerId, String userId) async {
    await _supabase.from('farmers').update({'is_verified': true}).eq('id', farmerId);
    
    // Send Notification
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': 'Account Verified! ✅',
      'body': 'Your farmer profile has been verified by the admin team.',
      'data': {'type': 'verification_success'}
    });
  }

  Future<void> suspendUser(String userId, bool suspend) async {
    await _supabase.from('users').update({
      'status': suspend ? 'suspended' : 'active'
    }).eq('id', userId);
  }

  // --- Product Management ---

  Future<List<ProductModel>> fetchProducts() async {
    final data = await _supabase.from('products').select('*, farmers(farm_name)').order('created_at', ascending: false);
    return (data as List).map((json) => ProductModel.fromJson(json)).toList();
  }

  Future<void> updateProductApproval(String productId, bool approved) async {
    await _supabase.from('products').update({'is_approved': approved}).eq('id', productId);
  }

  Future<void> deleteProduct(String productId) async {
    await _supabase.from('products').delete().eq('id', productId);
  }

  // --- Order Management ---

  Future<List<OrderModel>> fetchOrders() async {
    final data = await _supabase.from('orders').select('*, users(name), farmers(farm_name)').order('created_at', ascending: false);
    return (data as List).map((json) => OrderModel.fromJson(json)).toList();
  }

  // --- Message Moderation ---

  Future<List<Map<String, dynamic>>> fetchAllMessages() async {
    final data = await _supabase
        .from('messages')
        .select('*, sender:users!messages_sender_id_fkey(name), receiver:users!messages_receiver_id_fkey(name)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
