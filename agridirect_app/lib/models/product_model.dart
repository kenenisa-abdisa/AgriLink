import 'farmer_model.dart';

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
  final List<String> tags;
  final DateTime? harvestDate;
  final DateTime createdAt;
  final double? bulkPrice;
  final double? bulkMinQuantity;
  final FarmerModel? farmer; // joined farmer data
  final String? farmerName; // from joined query

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
    this.tags = const [],
    this.harvestDate,
    DateTime? createdAt,
    this.bulkPrice,
    this.bulkMinQuantity,
    this.farmer,
    this.farmerName,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ProductModel.fromJson(Map<String, dynamic> json, {FarmerModel? farmer, String? farmerName}) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      farmerId: json['farmer_id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      unit: json['unit'] ?? 'kg',
      category: json['category'] ?? 'Other',
      location: json['location'] ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '') ?? 0.0,
      minOrder: double.tryParse(json['min_order']?.toString() ?? '') ?? 1.0,
      isOrganic: json['is_organic'] ?? false,
      deliveryAvailable: json['delivery_available'] ?? true,
      pickupAvailable: json['pickup_available'] ?? true,
      bulkAvailable: json['bulk_available'] ?? false,
      imageUrls: json['image_urls'] != null ? List<String>.from(json['image_urls']) : [],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      harvestDate: json['harvest_date'] != null
          ? DateTime.parse(json['harvest_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      bulkPrice: json['bulk_price'] != null ? double.tryParse(json['bulk_price'].toString()) : null,
      bulkMinQuantity: json['bulk_min_quantity'] != null ? double.tryParse(json['bulk_min_quantity'].toString()) : null,
      farmer: farmer,
      farmerName: farmerName,
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
      'image_urls': imageUrls,
      'tags': tags,
      'harvest_date': harvestDate?.toIso8601String(),
      'bulk_price': bulkPrice,
      'bulk_min_quantity': bulkMinQuantity,
    };
  }

  /// Get emoji for this product's category
  String get categoryEmoji {
    const Map<String, String> emojis = {
      'Vegetables & Fruits': '🥬',
      'Grains & Cereals': '🌾',
      'Dairy & Eggs': '🥛',
      'Meat & Poultry': '🍗',
    };
    return emojis[category] ?? '🌱';
  }

  /// Get emoji for specific product name
  String get productEmoji {
    final lowerName = name.toLowerCase();
    const Map<String, String> emojis = {
      'tomato': '🍅',
      'teff': '🌾',
      'coffee': '☕',
      'egg': '🥚',
      'milk': '🥛',
      'onion': '🧅',
      'avocado': '🥑',
      'pepper': '🌶️',
      'cabbage': '🥬',
      'meat': '🥩',
      'chicken': '🍗',
      'lamb': '🍖',
      'bean': '🫘',
      'lentil': '🫘',
      'banana': '🍌',
      'mango': '🥭',
    };
    for (final entry in emojis.entries) {
      if (lowerName.contains(entry.key)) return entry.value;
    }
    return categoryEmoji;
  }
}
