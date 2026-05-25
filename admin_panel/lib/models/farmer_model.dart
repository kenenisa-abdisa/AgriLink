class FarmerModel {
  final String id;
  final String userId;
  final String farmName;
  final String? bio;
  final String? region;
  final String? town;
  final double farmSize;
  final double rating;
  final int totalReviews;
  final bool isVerified;
  final DateTime joinedDate;
  final List<String> certifications;
  // Joined user data
  final String? displayName;
  final String? email;
  final String? phone;

  FarmerModel({
    required this.id,
    required this.userId,
    required this.farmName,
    this.bio,
    this.region,
    this.town,
    this.farmSize = 0,
    this.rating = 0,
    this.totalReviews = 0,
    this.isVerified = false,
    DateTime? joinedDate,
    this.certifications = const [],
    this.displayName,
    this.email,
    this.phone,
  }) : joinedDate = joinedDate ?? DateTime.now();

  factory FarmerModel.fromJson(Map<String, dynamic> json, {String? displayName, String? email, String? phone}) {
    return FarmerModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      farmName: json['farm_name'] ?? 'Unnamed Farm',
      bio: json['bio'],
      region: json['region'],
      town: json['town'],
      farmSize: (json['farm_size'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      joinedDate: json['joined_date'] != null
          ? DateTime.parse(json['joined_date'])
          : DateTime.now(),
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'])
          : [],
      displayName: displayName ?? json['users']?['name'],
      email: email ?? json['users']?['email'],
      phone: phone ?? json['users']?['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'farm_name': farmName,
      'bio': bio,
      'region': region,
      'town': town,
      'farm_size': farmSize,
      'is_verified': isVerified,
      'certifications': certifications,
    };
  }
}
