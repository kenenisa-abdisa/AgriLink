import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/cache_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  /// Load cached orders immediately for smooth UX
  void loadCachedOrders() {
    _orders = CacheService.getCachedOrders();
    notifyListeners();
  }

  /// Place a new order
  Future<OrderModel?> placeOrder({
    required String buyerId,
    required String farmerId,
    required double totalAmount,
    required String paymentMethod,
    String? deliveryAddress,
    String? notes,
    bool isBulk = false,
    String paymentStatus = 'pending',
    String? paymentReference,
    required List<OrderItemModel> items,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final order = await _orderService.placeOrder(
        buyerId: buyerId,
        farmerId: farmerId,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        notes: notes,
        isBulk: isBulk,
        paymentStatus: paymentStatus,
        paymentReference: paymentReference,
        items: items,
      );
      if (order != null) {
        _orders.insert(0, order);
        await CacheService.cacheOrders(_orders);
      }
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch orders for a buyer
  Future<void> fetchBuyerOrders(String buyerId) async {
    // Load cache immediately
    if (_orders.isEmpty) {
      _orders = CacheService.getCachedOrders();
    }
    _isLoading = true;
    notifyListeners();
    try {
      final fresh = await _orderService.fetchBuyerOrders(buyerId);
      _orders = fresh;
      await CacheService.cacheOrders(_orders);
    } catch (e) {
      debugPrint('Error fetching buyer orders: $e');
      // Keep cached copy if network fails
      if (_orders.isEmpty) {
        _orders = CacheService.getCachedOrders();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Fetch orders for a farmer
  Future<void> fetchFarmerOrders(String farmerId, String buyerId) async {
    // Load cache immediately
    if (_orders.isEmpty) {
      _orders = CacheService.getCachedOrders();
    }
    _isLoading = true;
    notifyListeners();
    try {
      final fresh = await _orderService.fetchFarmerOrders(farmerId, buyerId);
      _orders = fresh;
      await CacheService.cacheOrders(_orders);
      debugPrint('Fetched ${_orders.length} farmer orders');
    } catch (e) {
      debugPrint('ERROR FETCHING FARMER ORDERS: $e');
      if (_orders.isEmpty) {
        _orders = CacheService.getCachedOrders();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Fetch ALL orders for Admin
  Future<void> fetchAllOrders() async {
    if (_orders.isEmpty) {
      _orders = CacheService.getCachedOrders();
    }
    _isLoading = true;
    notifyListeners();
    try {
      final fresh = await _orderService.fetchAllOrders();
      _orders = fresh;
      await CacheService.cacheOrders(_orders);
    } catch (e) {
      debugPrint('Error fetching all orders: $e');
      if (_orders.isEmpty) {
        _orders = CacheService.getCachedOrders();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Update order status (farmer action)
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _orderService.updateOrderStatus(orderId, status);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final old = _orders[index];
        _orders[index] = OrderModel(
          id: old.id,
          buyerId: old.buyerId,
          farmerId: old.farmerId,
          totalAmount: old.totalAmount,
          paymentMethod: old.paymentMethod,
          deliveryAddress: old.deliveryAddress,
          status: status,
          isBulk: old.isBulk,
          notes: old.notes,
          confirmedAt: status == 'confirmed' ? DateTime.now() : old.confirmedAt,
          dispatchedAt: status == 'dispatched' ? DateTime.now() : old.dispatchedAt,
          deliveredAt: status == 'delivered' ? DateTime.now() : old.deliveredAt,
          paymentStatus: old.paymentStatus,
          paymentReference: old.paymentReference,
          paidAt: old.paidAt,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
          items: old.items,
        );
        await CacheService.cacheOrders(_orders);
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    if (status == 'all') return _orders;
    return _orders.where((o) => o.status == status).toList();
  }
}
