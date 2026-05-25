import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import 'email_service.dart';
import 'notification_service.dart';

class OrderService {
  final _supabase = Supabase.instance.client;

  /// Place a new order with order items
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
    try {
      // Insert order
      final orderResponse = await _supabase.from('orders').insert({
        'buyer_id': buyerId,
        'farmer_id': farmerId,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'delivery_address': deliveryAddress,
        'notes': notes,
        'is_bulk': isBulk,
        'status': 'pending',
        'payment_status': paymentStatus,
        'payment_reference': paymentReference,
      }).select().single();

      final orderId = orderResponse['id'];

      // Resolve farmer's actual user_id for notifications
      // (farmerId is farmers.id PK, but notifications.user_id expects users.id)
      String farmerUserId = farmerId;
      try {
        final farmerRecord = await _supabase
            .from('farmers')
            .select('user_id')
            .eq('id', farmerId)
            .maybeSingle();
        if (farmerRecord != null) {
          farmerUserId = farmerRecord['user_id'];
        }
      } catch (_) {}

      // Insert order items and check for low stock
      for (final item in items) {
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit': item.unit,
          'price': item.price,
        });

        // Check stock levels
        final pResponse = await _supabase.from('products').select('quantity, name').eq('id', item.productId).single();
        final currentStock = (pResponse['quantity'] as num).toDouble();
        if (currentStock < 10) {
           await _supabase.from('notifications').insert({
            'user_id': farmerUserId,
            'title': 'Low Stock Alert! ⚠️',
            'body': 'Your product "${pResponse['name']}" is running low ($currentStock remaining).',
            'data': {'product_id': item.productId, 'type': 'low_stock'}
          });
        }
      }

      // Notify Farmer about new order
      try {
        final itemsText = items.map((i) => '${i.quantity}x ${i.productName}').join(', ');
        await _supabase.from('notifications').insert({
          'user_id': farmerUserId,
          'title': 'New Order Received! 📦',
          'body': 'You have a new order for $itemsText (Total: ETB ${totalAmount.toStringAsFixed(0)}).',
          'data': {'order_id': orderId, 'type': 'order_placed'}
        });

        // Send New Order Email to Farmer
        final farmerData = await _supabase.from('users').select('email').eq('id', farmerUserId).single();
        await EmailService().sendOrderUpdateEmail(
          email: farmerData['email'],
          orderId: orderId,
          status: 'pending',
          isFarmer: true,
        );
        
        // Send FCM Push Notification
        await NotificationService().sendPushNotification(
          receiverId: farmerUserId,
          title: 'New Order Received! 📦',
          body: 'You have a new order for $itemsText (Total: ETB ${totalAmount.toStringAsFixed(0)}).',
          data: {'type': 'order_placed', 'order_id': orderId},
        );
      } catch (notifyErr) {
        debugPrint('Post-order notification/email failed: $notifyErr');
        // We don't rethrow here because the order IS successfully created in the DB.
      }

      return OrderModel.fromJson(orderResponse, items: items);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch orders where current user is the buyer
  Future<List<OrderModel>> fetchBuyerOrders(String buyerId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);

      final orders = <OrderModel>[];
      for (final orderJson in response) {
        List<OrderItemModel> items = [];
        try {
          final itemsResponse = await _supabase
              .from('order_items')
              .select()
              .eq('order_id', orderJson['id']);
          items = (itemsResponse as List)
              .map((j) => OrderItemModel.fromJson(j))
              .toList();
        } catch (itemErr) {
          debugPrint('Failed to fetch items for order ${orderJson['id']}: $itemErr');
        }
        orders.add(OrderModel.fromJson(orderJson, items: items));
      }
      return orders;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch orders for a farmer (by farmer_id) or where they are the buyer (by buyer_id)
  Future<List<OrderModel>> fetchFarmerOrders(String farmerId, String buyerId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .or('farmer_id.eq.$farmerId,buyer_id.eq.$buyerId')
          .order('created_at', ascending: false);

      final orders = <OrderModel>[];
      for (final orderJson in response) {
        List<OrderItemModel> items = [];
        try {
          final itemsResponse = await _supabase
              .from('order_items')
              .select()
              .eq('order_id', orderJson['id']);
          items = (itemsResponse as List)
              .map((j) => OrderItemModel.fromJson(j))
              .toList();
        } catch (itemErr) {
          debugPrint('Failed to fetch items for order ${orderJson['id']}: $itemErr');
        }
        orders.add(OrderModel.fromJson(orderJson, items: items));
      }
      return orders;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch ALL orders for Admin oversight
  Future<List<OrderModel>> fetchAllOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      final orders = <OrderModel>[];
      for (final orderJson in response) {
        final itemsResponse = await _supabase
            .from('order_items')
            .select()
            .eq('order_id', orderJson['id']);
        final items = (itemsResponse as List)
            .map((j) => OrderItemModel.fromJson(j))
            .toList();
        orders.add(OrderModel.fromJson(orderJson, items: items));
      }
      return orders;
    } catch (e) {
      rethrow;
    }
  }

  /// Update order status (for farmers)
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'confirmed') {
        updates['confirmed_at'] = DateTime.now().toIso8601String();
      } else if (status == 'dispatched') {
        updates['dispatched_at'] = DateTime.now().toIso8601String();
      } else if (status == 'delivered') {
        updates['delivered_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('orders').update(updates).eq('id', orderId);

      // Notify Buyer about status change
      final orderData = await _supabase.from('orders').select('buyer_id').eq('id', orderId).maybeSingle();
      if (orderData == null) return; // Prevents PGRST116 if row isn't returned
      final buyerId = orderData['buyer_id'];
      
      String title = 'Order Update';
      String body = 'Your order is now $status.';
      
      if (status == 'confirmed') {
        title = 'Order Confirmed! ✅';
        body = 'The farmer has confirmed your order.';
      } else if (status == 'dispatched') {
        title = 'Order Dispatched! 🚚';
        body = 'Your produce is on the way to you.';
      } else if (status == 'delivered') {
        title = 'Order Delivered! 🏁';
        body = 'Your order has been delivered. Please rate the farmer!';
      }

      await _supabase.from('notifications').insert({
        'user_id': buyerId,
        'title': title,
        'body': body,
        'data': {'order_id': orderId, 'type': 'status_change'}
      });

      // Send Order Status Email to Buyer
      final buyerData = await _supabase.from('users').select('email').eq('id', buyerId).maybeSingle();
      if (buyerData != null && buyerData['email'] != null) {
        await EmailService().sendOrderUpdateEmail(
          email: buyerData['email'],
          orderId: orderId,
          status: status,
          isFarmer: false,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus(String txRef, String paymentStatus) async {
    try {
      await _supabase.from('orders').update({
        'payment_status': paymentStatus,
        'paid_at': paymentStatus == 'paid' ? DateTime.now().toIso8601String() : null,
      }).eq('payment_reference', txRef);
    } catch (e) {
      rethrow;
    }
  }

  /// Stream orders for real-time updates
  Stream<List<Map<String, dynamic>>> streamOrders() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }
}
