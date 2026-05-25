import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductService {
  final _supabase = Supabase.instance.client;

  /// Fetch products with pagination (limit and offset)
  Future<List<ProductModel>> fetchProducts({int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream products for real-time updates
  Stream<List<Map<String, dynamic>>> streamProducts() {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Search products using Full-Text Search
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .textSearch('fts', query, config: 'english')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback if FTS column/index is not ready yet
      final fallback = await _supabase
          .from('products')
          .select()
          .or('name.ilike.%$query%,location.ilike.%$query%,category.ilike.%$query%')
          .order('created_at', ascending: false);
      return (fallback as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    }
  }

  /// Fetch top trending products based on order frequency
  Future<List<ProductModel>> fetchTrendingProducts() async {
    try {
      // Get product IDs from most frequent order items
      final response = await _supabase
          .from('order_items')
          .select('product_id')
          .limit(20);
      
      if ((response as List).isEmpty) return [];

      final counts = <String, int>{};
      for (var item in response) {
        final id = item['product_id'] as String;
        counts[id] = (counts[id] ?? 0) + 1;
      }

      final sortedIds = counts.keys.toList()
        ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

      if (sortedIds.isEmpty) return [];

      final products = await _supabase
          .from('products')
          .select()
          .filter('id', 'in', sortedIds.take(10).toList());

      return (products as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a new product
  Future<void> addProduct(ProductModel product) async {
    try {
      await _supabase.from('products').insert(product.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing product
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('products').update(data).eq('id', productId);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch products by farmer's user_id
  Future<List<ProductModel>> fetchFarmerProducts(String userId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }


}