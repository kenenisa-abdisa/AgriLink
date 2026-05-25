class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role; // 'farmer', 'buyer', 'business'
  final String? region;
  final String? profileImage;
  final String language;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final bool isOnline;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.region,
    this.profileImage,
    this.language = 'en',
    DateTime? createdAt,
    this.lastSeenAt,
    this.isOnline = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'buyer',
      region: json['region'],
      profileImage: json['profile_image'],
      language: json['language'] ?? 'en',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
      isOnline: json['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'region': region,
      'profile_image': profileImage,
      'language': language,
      'created_at': createdAt.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'is_online': isOnline,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? region,
    String? profileImage,
    String? language,
    DateTime? lastSeenAt,
    bool? isOnline,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role,
      region: region ?? this.region,
      profileImage: profileImage ?? this.profileImage,
      language: language ?? this.language,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
