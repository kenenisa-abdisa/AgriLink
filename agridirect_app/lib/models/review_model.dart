class ReviewModel {
  final String id;
  final String orderId;
  final String buyerId;
  final String farmerId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  // Joined fields
  final String? buyerName;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.farmerId,
    required this.rating,
    this.comment,
    DateTime? createdAt,
    this.buyerName,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ReviewModel.fromJson(Map<String, dynamic> json, {String? buyerName}) {
    return ReviewModel(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      buyerId: json['buyer_id'] ?? '',
      farmerId: json['farmer_id'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      buyerName: buyerName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'rating': rating,
      'comment': comment,
    };
  }
}
