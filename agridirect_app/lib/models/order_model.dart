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

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'price': price,
    };
  }
}

class OrderModel {
  final String id;
  final String buyerId;
  final String farmerId;
  final double totalAmount;
  final String? paymentMethod;
  final String? deliveryAddress;
  final String status;
  final bool isBulk;
  final bool isRecurring;
  final String? recurrenceInterval;
  final String? recurrenceDay;
  final String? parentOrderId;
  final String? notes;
  final DateTime? confirmedAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final String paymentStatus;
  final String? paymentReference;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel> items;
  // Joined data
  final String? buyerName;
  final String? farmerName;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.farmerId,
    required this.totalAmount,
    this.paymentMethod,
    this.deliveryAddress,
    this.status = 'pending',
    this.isBulk = false,
    this.isRecurring = false,
    this.recurrenceInterval,
    this.recurrenceDay,
    this.parentOrderId,
    this.notes,
    this.confirmedAt,
    this.dispatchedAt,
    this.deliveredAt,
    this.paymentStatus = 'pending',
    this.paymentReference,
    this.paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.items = const [],
    this.buyerName,
    this.farmerName,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory OrderModel.fromJson(Map<String, dynamic> json,
      {List<OrderItemModel>? items}) {
    return OrderModel(
      id: json['id'] ?? '',
      buyerId: json['buyer_id'] ?? '',
      farmerId: json['farmer_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'],
      deliveryAddress: json['delivery_address'],
      status: json['status'] ?? 'pending',
      isBulk: json['is_bulk'] ?? false,
      isRecurring: json['is_recurring'] ?? false,
      recurrenceInterval: json['recurrence_interval'],
      recurrenceDay: json['recurrence_day'],
      parentOrderId: json['parent_order_id'],
      notes: json['notes'],
      confirmedAt: json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at']) : null,
      dispatchedAt: json['dispatched_at'] != null ? DateTime.parse(json['dispatched_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentReference: json['payment_reference'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      items: items ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'delivery_address': deliveryAddress,
      'status': status,
      'is_bulk': isBulk,
      'is_recurring': isRecurring,
      'recurrence_interval': recurrenceInterval,
      'recurrence_day': recurrenceDay,
      'parent_order_id': parentOrderId,
      'notes': notes,
    };
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'delivery_address': deliveryAddress,
      'status': status,
      'is_bulk': isBulk,
      'is_recurring': isRecurring,
      'recurrence_interval': recurrenceInterval,
      'recurrence_day': recurrenceDay,
      'parent_order_id': parentOrderId,
      'notes': notes,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'dispatched_at': dispatchedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'payment_status': paymentStatus,
      'payment_reference': paymentReference,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => {
        'id': item.id,
        'order_id': item.orderId,
        'product_id': item.productId,
        'product_name': item.productName,
        'quantity': item.quantity,
        'unit': item.unit,
        'price': item.price,
      }).toList(),
      'buyer_name': buyerName,
      'farmer_name': farmerName,
    };
  }

  factory OrderModel.fromCacheJson(Map<String, dynamic> json) {
    final List? itemData = json['items'];
    final List<OrderItemModel> itemsList = itemData == null
        ? []
        : itemData.map((item) => OrderItemModel.fromJson(item)).toList();
    return OrderModel.fromJson(json, items: itemsList);
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'dispatched':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'quote_requested':
        return 'Quote Requested';
      default:
        return statusDisplayProper;
    }
  }

  String get statusDisplayProper {
    // Standard capitalization
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1).replaceFirst('_', ' ');
  }
}
