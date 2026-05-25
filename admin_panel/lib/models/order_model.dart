class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double quantity;
  final String? unit;
  final double price;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unit,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'],
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

class OrderModel {
  final String id;
  final String buyerId;
  final String farmerId;
  final double totalAmount;
  final String status;
  final String? deliveryAddress;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  // Joined data
  final String? buyerName;
  final String? farmerName;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.farmerId,
    required this.totalAmount,
    this.status = 'pending',
    this.deliveryAddress,
    DateTime? createdAt,
    this.items = const [],
    this.buyerName,
    this.farmerName,
  }) : createdAt = createdAt ?? DateTime.now();

  factory OrderModel.fromJson(Map<String, dynamic> json, {List<OrderItemModel>? items}) {
    return OrderModel(
      id: json['id'] ?? '',
      buyerId: json['buyer_id'] ?? '',
      farmerId: json['farmer_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      deliveryAddress: json['delivery_address'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      items: items ?? [],
      buyerName: json['users']?['name'],
      farmerName: json['farmers']?['farm_name'],
    );
  }
}
