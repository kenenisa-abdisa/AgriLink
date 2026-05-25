import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_model.dart';
import '../models/farmer_model.dart';
import '../models/order_model.dart';
import '../models/message_model.dart';

class CacheService {
  static const String productBoxName = 'products_cache';
  static const String farmerBoxName = 'farmers_cache';
  static const String orderBoxName = 'orders_cache';
  static const String messageBoxName = 'messages_cache';
  static const String metaBoxName = 'cache_metadata';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(productBoxName);
    await Hive.openBox(farmerBoxName);
    await Hive.openBox(orderBoxName);
    await Hive.openBox(messageBoxName);
    await Hive.openBox(metaBoxName);
  }

  // --- Products ---

  static Future<void> cacheProducts(List<ProductModel> products) async {
    final box = Hive.box(productBoxName);
    final jsonList = products.map((p) => p.toJson()).toList();
    await box.put('all_products', jsonEncode(jsonList));
    await _updateTimestamp('products');
  }

  static List<ProductModel> getCachedProducts() {
    final box = Hive.box(productBoxName);
    final String? jsonStr = box.get('all_products');
    if (jsonStr == null) return [];
    
    try {
      final List decodeData = jsonDecode(jsonStr);
      return decodeData.map((p) => ProductModel.fromJson(p)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Farmers ---

  static Future<void> cacheFarmers(List<FarmerModel> farmers) async {
    final box = Hive.box(farmerBoxName);
    final jsonList = farmers.map((f) => f.toJson()).toList();
    await box.put('all_farmers', jsonEncode(jsonList));
    await _updateTimestamp('farmers');
  }

  static List<FarmerModel> getCachedFarmers() {
    final box = Hive.box(farmerBoxName);
    final String? jsonStr = box.get('all_farmers');
    if (jsonStr == null) return [];
    
    try {
      final List decodeData = jsonDecode(jsonStr);
      return decodeData.map((f) => FarmerModel.fromJson(f)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Orders ---

  static Future<void> cacheOrders(List<OrderModel> orders) async {
    final box = Hive.box(orderBoxName);
    final jsonList = orders.map((o) => o.toCacheJson()).toList();
    await box.put('all_orders', jsonEncode(jsonList));
    await _updateTimestamp('orders');
  }

  static List<OrderModel> getCachedOrders() {
    final box = Hive.box(orderBoxName);
    final String? jsonStr = box.get('all_orders');
    if (jsonStr == null) return [];
    
    try {
      final List decodeData = jsonDecode(jsonStr);
      return decodeData.map((o) => OrderModel.fromCacheJson(o)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Messages ---

  static Future<void> cacheMessages(List<MessageModel> messages) async {
    final box = Hive.box(messageBoxName);
    final jsonList = messages.map((m) => m.toCacheJson()).toList();
    await box.put('all_messages', jsonEncode(jsonList));
    await _updateTimestamp('messages');
  }

  static List<MessageModel> getCachedMessages() {
    final box = Hive.box(messageBoxName);
    final String? jsonStr = box.get('all_messages');
    if (jsonStr == null) return [];
    
    try {
      final List decodeData = jsonDecode(jsonStr);
      return decodeData.map((m) => MessageModel.fromCacheJson(m)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Metadata & Helpers ---

  static Future<void> _updateTimestamp(String key) async {
    final box = Hive.box(metaBoxName);
    await box.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  static bool isCacheFresh(String key, {int minutes = 30}) {
    final box = Hive.box(metaBoxName);
    final int? timestamp = box.get('${key}_timestamp');
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(cacheTime).inMinutes;
    return diff < minutes;
  }

  static String getCacheAgeMessage(String key) {
    final box = Hive.box(metaBoxName);
    final int? timestamp = box.get('${key}_timestamp');
    if (timestamp == null) return '';

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(cacheTime).inMinutes;
    if (diff == 0) return 'Updated just now';
    return 'Updated $diff minutes ago';
  }

  static Future<void> clearCache() async {
    await Hive.box(productBoxName).clear();
    await Hive.box(farmerBoxName).clear();
    await Hive.box(orderBoxName).clear();
    await Hive.box(messageBoxName).clear();
    await Hive.box(metaBoxName).clear();
  }
}
