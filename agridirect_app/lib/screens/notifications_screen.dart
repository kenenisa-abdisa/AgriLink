import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';
import '../models/order_model.dart';
import 'order_tracking_screen.dart';
import 'chat_screen.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  void _handleNotificationTap(BuildContext context, Map<String, dynamic> n) async {
    // Mark as read
    final isRead = n['read'] ?? false;
    if (!isRead) {
      await Supabase.instance.client
          .from('notifications')
          .update({'read': true})
          .eq('id', n['id']);
    }

    // Parse notification data for deep linking
    Map<String, dynamic> data = {};
    if (n['data'] != null) {
      if (n['data'] is String) {
        try {
          data = jsonDecode(n['data']);
        } catch (_) {}
      } else if (n['data'] is Map) {
        data = Map<String, dynamic>.from(n['data']);
      }
    }

    final type = data['type'] ?? '';

    if (!context.mounted) return;

    if (type == 'order_placed' || type == 'status_change') {
      final orderId = data['order_id'];
      if (orderId != null) {
        try {
          final response = await Supabase.instance.client.from('orders').select().eq('id', orderId).maybeSingle();
          if (response != null) {
            final itemsResponse = await Supabase.instance.client.from('order_items').select().eq('order_id', orderId);
            final items = (itemsResponse as List).map((j) => OrderItemModel.fromJson(j)).toList();
            final order = OrderModel.fromJson(response, items: items);
            if (context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(initialOrder: order)));
            }
            return;
          }
        } catch (_) {}
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (type == 'new_message') {
      final senderId = data['sender_id'];
      if (senderId != null) {
        try {
          final senderData = await Supabase.instance.client.from('users').select('name').eq('id', senderId).maybeSingle();
          final senderName = senderData?['name'] ?? 'User';
          if (context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: senderId, otherUserName: senderName)));
          }
          return;
        } catch (_) {}
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (type == 'low_stock') {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
        actions: [
          // Mark all as read button
          TextButton(
            onPressed: () async {
              if (userId == null) return;
              await Supabase.instance.client
                  .from('notifications')
                  .update({'read': true})
                  .eq('user_id', userId)
                  .eq('read', false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    backgroundColor: Color(0xFF1B6B3A),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text(
              'Read All',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // This simply triggers a rebuild so the FutureBuilder refetches
          setState(() {});
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          // Fetch notifications manually as a fallback to the stream
          future: Supabase.instance.client
              .from('notifications')
              .select()
              .eq('user_id', userId ?? '')
              .order('created_at', ascending: false),
          builder: (context, futureSnapshot) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('notifications')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, streamSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting &&
                    !streamSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Prefer stream data if available, otherwise use future data
                List<Map<String, dynamic>> notifications = [];
                if (streamSnapshot.hasData && streamSnapshot.data!.isNotEmpty) {
                  notifications = streamSnapshot.data!
                      .where((n) => n['user_id'] == userId)
                      .toList();
                } else if (futureSnapshot.hasData) {
                  notifications = futureSnapshot.data!;
                }

                if (notifications.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final isRead = n['read'] ?? false;
                    final createdAt = DateTime.parse(n['created_at']);

                    return Container(
                      decoration: BoxDecoration(
                        color: isRead
                            ? Colors.white
                            : const Color(0xFF1B6B3A).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRead
                              ? Colors.grey[200]!
                              : const Color(0xFF1B6B3A).withValues(alpha: 0.2),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: (isRead
                              ? Colors.grey[200]
                              : const Color(0xFF1B6B3A))!,
                          child: Icon(
                            _getIconForTitle(n['title']),
                            color: isRead ? Colors.grey[600] : Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          n['title'] ?? 'Notification',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              n['body'] ?? '',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              timeago.format(createdAt),
                              style: TextStyle(color: Colors.grey[400], fontSize: 11),
                            ),
                          ],
                        ),
                        onTap: () => _handleNotificationTap(context, n),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForTitle(String? title) {
    final t = title?.toLowerCase() ?? '';
    if (t.contains('order')) return Icons.receipt_long;
    if (t.contains('message')) return Icons.message;
    if (t.contains('stock')) return Icons.inventory_2;
    if (t.contains('deliver')) return Icons.local_shipping;
    if (t.contains('confirm')) return Icons.check_circle;
    return Icons.notifications;
  }
}

