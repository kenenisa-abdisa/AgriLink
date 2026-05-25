import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

class ReviewService {
  final _supabase = Supabase.instance.client;

  /// Submit a new review
  Future<void> submitReview({
    required String orderId,
    required String buyerId,
    required String farmerId,
    required double rating,
    String? comment,
  }) async {
    try {
      await _supabase.from('reviews').insert({
        'order_id': orderId,
        'buyer_id': buyerId,
        'farmer_id': farmerId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a buyer has already reviewed a specific order
  Future<bool> checkIfReviewed(String orderId, String buyerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('order_id', orderId)
          .eq('buyer_id', buyerId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false; // Safely assume not reviewed or error occurred
    }
  }

  /// Get all reviews for a specific farmer
  Future<List<ReviewModel>> getReviewsForFarmer(String farmerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, users!buyer_id(name)')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      final reviews = <ReviewModel>[];
      for (final json in response) {
        String? buyerName;
        if (json['users'] != null) {
          final usersData = json['users'];
          if (usersData is Map) {
            buyerName = usersData['name'] as String?;
          }
        }
        reviews.add(ReviewModel.fromJson(json, buyerName: buyerName));
      }
      return reviews;
    } catch (e) {
      return [];
    }
  }
}
