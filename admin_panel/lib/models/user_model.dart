class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role; // 'farmer', 'buyer', 'business', 'admin'
  final String? region;
  final String? profileImage;
  final String status; // 'active', 'suspended'
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.region,
    this.profileImage,
    this.status = 'active',
    DateTime? createdAt,
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
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
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
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
