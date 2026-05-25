import 'user_model.dart';

class FarmerModel {
  final String id;
  final String userId;
  final String? farmName;
  final String? bio;
  final String? region;
  final String? town;
  final double? farmSize;
  final double rating;
  final int totalReviews;
  final List<String> certifications;
  final bool isVerified;
  final String? paymentMethod;
  final String? paymentNumber;
  final DateTime joinedDate;
  final UserModel? user; // joined user data

  FarmerModel({
    required this.id,
    required this.userId,
    this.farmName,
    this.bio,
    this.region,
    this.town,
    this.farmSize,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.certifications = const [],
    this.isVerified = false,
    this.paymentMethod,
    this.paymentNumber,
    DateTime? joinedDate,
    this.user,
  }) : joinedDate = joinedDate ?? DateTime.now();

  factory FarmerModel.fromJson(Map<String, dynamic> json, {UserModel? user}) {
    return FarmerModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      farmName: json['farm_name'],
      bio: json['bio'],
      region: json['region'],
      town: json['town'],
      farmSize: json['farm_size']?.toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'])
          : [],
      isVerified: json['is_verified'] ?? false,
      paymentMethod: json['payment_method'],
      paymentNumber: json['payment_number'],
      joinedDate: json['joined_date'] != null
          ? DateTime.parse(json['joined_date'])
          : DateTime.now(),
      user: user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'farm_name': farmName,
      'bio': bio,
      'region': region,
      'town': town,
      'farm_size': farmSize,
      'rating': rating,
      'total_reviews': totalReviews,
      'certifications': certifications,
      'is_verified': isVerified,
      'payment_method': paymentMethod,
      'payment_number': paymentNumber,
      'joined_date': joinedDate.toIso8601String(),
    };
  }

  /// Display name: use farm name or user name
  String get displayName => farmName ?? user?.name ?? 'Unknown Farmer';

  /// Display location: "town, region"
  String get displayLocation {
    if (town != null && region != null) return '$town, $region';
    return region ?? town ?? 'Ethiopia';
  }
}
