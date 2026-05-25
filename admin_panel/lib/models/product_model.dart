class ProductModel {
  final String id;
  final String userId;
  final String? farmerId;
  final String name;
  final String? description;
  final double price;
  final String unit;
  final String category;
  final String location;
  final double quantity;
  final double minOrder;
  final bool isOrganic;
  final bool deliveryAvailable;
  final bool pickupAvailable;
  final bool bulkAvailable;
  final List<String> imageUrls;
  final bool isApproved; // Moderation field
  final DateTime createdAt;
  // Joined data
  final String? farmerName;

  ProductModel({
    required this.id,
    required this.userId,
    this.farmerId,
    required this.name,
    this.description,
    required this.price,
    this.unit = 'kg',
    required this.category,
    required this.location,
    required this.quantity,
    this.minOrder = 1,
    this.isOrganic = false,
    this.deliveryAvailable = true,
    this.pickupAvailable = true,
    this.bulkAvailable = false,
    this.imageUrls = const [],
    this.isApproved = true,
    DateTime? createdAt,
    this.farmerName,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ProductModel.fromJson(Map<String, dynamic> json, {String? farmerName}) {
    return ProductModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      farmerId: json['farmer_id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'kg',
      category: json['category'] ?? 'Other',
      location: json['location'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      minOrder: (json['min_order'] ?? 1).toDouble(),
      isOrganic: json['is_organic'] ?? false,
      deliveryAvailable: json['delivery_available'] ?? true,
      pickupAvailable: json['pickup_available'] ?? true,
      bulkAvailable: json['bulk_available'] ?? false,
      imageUrls: json['image_urls'] != null ? List<String>.from(json['image_urls']) : [],
      isApproved: json['is_approved'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      farmerName: farmerName ?? json['farmers']?['farm_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'farmer_id': farmerId,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'category': category,
      'location': location,
      'quantity': quantity,
      'min_order': minOrder,
      'is_organic': isOrganic,
      'delivery_available': deliveryAvailable,
      'pickup_available': pickupAvailable,
      'bulk_available': bulkAvailable,
      'is_approved': isApproved,
      'image_urls': imageUrls,
    };
  }
}
