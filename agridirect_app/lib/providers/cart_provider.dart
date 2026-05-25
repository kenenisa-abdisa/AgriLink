import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, required this.quantity});

  double get unitPrice {
    if (product.bulkPrice != null && product.bulkMinQuantity != null && quantity >= product.bulkMinQuantity!) {
      return product.bulkPrice!;
    }
    return product.price;
  }

  double get totalPrice => unitPrice * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.length;

  int get totalQuantity =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addToCart(ProductModel product, int quantity) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index =
        _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(String productId) {
    try {
      return _items
          .firstWhere((item) => item.product.id == productId)
          .quantity;
    } catch (_) {
      return 0;
    }
  }

  /// Group cart items by farmer for checkout
  Map<String, List<CartItem>> get itemsByFarmer {
    final map = <String, List<CartItem>>{};
    for (final item in _items) {
      final farmerId = item.product.farmerId ?? item.product.userId;
      map.putIfAbsent(farmerId, () => []).add(item);
    }
    return map;
  }
}