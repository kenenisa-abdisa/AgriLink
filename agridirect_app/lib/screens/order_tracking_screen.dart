import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/review_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/review_bottom_sheet.dart';
import 'chat_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel initialOrder;

  const OrderTrackingScreen({super.key, required this.initialOrder});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Stream<List<Map<String, dynamic>>> _orderStream;
  bool _hasPromptedReview = false;

  @override
  void initState() {
    super.initState();
    _orderStream = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.initialOrder.id);
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  Future<void> _checkAndShowReviewSheet(OrderModel order) async {
    final reviewService = ReviewService();
    final alreadyReviewed = await reviewService.checkIfReviewed(
      order.id,
      order.buyerId,
    );
    if (alreadyReviewed) return;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ReviewBottomSheet(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isFarmer = authProvider.userRole == 'farmer';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Order Tracking'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _orderStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading order tracking'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          OrderModel order = widget.initialOrder;

          if (data != null && data.isNotEmpty) {
            order = OrderModel.fromJson(
              data.first,
              items: widget.initialOrder.items,
            );
            if (order.status == 'delivered' &&
                !_hasPromptedReview &&
                !isFarmer) {
              _hasPromptedReview = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _checkAndShowReviewSheet(order);
              });
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTimeline(order),
                const SizedBox(height: 24),
                _buildMapPlaceholder(order),
                const SizedBox(height: 24),

                if (isFarmer) ...[
                  _buildFarmerActions(context, order),
                  const SizedBox(height: 24),
                ],

                _buildContactCard(order, isFarmer),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(OrderModel order) {
    final stages = [
      {'title': 'Order Placed', 'time': order.createdAt},
      {'title': 'Confirmed by Farmer', 'time': order.confirmedAt},
      {'title': 'Being Prepared', 'time': null},
      {'title': 'Dispatched / On the Way', 'time': order.dispatchedAt},
      {'title': 'Delivered', 'time': order.deliveredAt},
    ];

    bool isCompleted(int s) {
      if (s == 0) return true;
      if (s == 1) return order.confirmedAt != null;
      if (s == 2) return order.dispatchedAt != null;
      if (s == 3) return order.deliveredAt != null;
      if (s == 4) {
        return order.deliveredAt != null && order.status == 'delivered';
      }
      return false;
    }

    bool isCurrent(int s) {
      if (order.status == 'pending' && s == 1) return true;
      if (order.status == 'confirmed' && s == 2) return true;
      if (order.status == 'dispatched' && s == 3) return true;
      if (order.status == 'delivered' && s == 4) return true;
      return false;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: #${order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ...List.generate(stages.length, (index) {
              final stage = stages[index];
              final completed = isCompleted(index);
              final current = isCurrent(index);

              Color dotColor = Colors.grey[300]!;
              if (completed) dotColor = const Color(0xFF1B6B3A);
              if (current) dotColor = Colors.amber;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (index < stages.length - 1)
                        Container(
                          width: 2,
                          height: 40,
                          color: completed
                              ? const Color(0xFF1B6B3A)
                              : Colors.grey[200],
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage['title'] as String,
                          style: TextStyle(
                            fontWeight: current || completed
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: current || completed
                                ? Colors.black87
                                : Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                        if (stage['time'] != null)
                          Text(
                            DateFormat(
                              'MMM d, h:mm a',
                            ).format(stage['time'] as DateTime),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        if (current)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Action needed',
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B6B3A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1B6B3A).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_on, size: 48, color: Color(0xFF1B6B3A)),
          const SizedBox(height: 12),
          Text(
            'Live map coming soon',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1B6B3A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Delivery to: ${order.deliveryAddress ?? "Farm Location"}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerActions(BuildContext context, OrderModel order) {
    if (order.status != 'confirmed' && order.status != 'dispatched') {
      return const SizedBox.shrink();
    }

    final orderProvider = context.read<OrderProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (order.status == 'confirmed')
          CustomButton(
            text: 'Mark as Dispatched',
            onPressed: () =>
                orderProvider.updateOrderStatus(order.id, 'dispatched'),
          ),
        if (order.status == 'dispatched')
          CustomButton(
            text: 'Mark as Delivered',
            onPressed: () =>
                orderProvider.updateOrderStatus(order.id, 'delivered'),
          ),
      ],
    );
  }

  Widget _buildContactCard(OrderModel order, bool isFarmer) {
    final name = isFarmer
        ? (widget.initialOrder.buyerName ?? 'Buyer')
        : (widget.initialOrder.farmerName ?? 'Farmer');
    final otherId = isFarmer ? order.buyerId : order.farmerId;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF1B6B3A),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (!isFarmer) // fake rating for UI, can be updated later if needed
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('4.8', style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.phone, color: Color(0xFF1B6B3A)),
              onPressed: () => _makePhoneCall(
                '0900000000',
              ), // Replace dynamically if needed in future
            ),
            IconButton(
              icon: const Icon(Icons.message, color: Color(0xFF1B6B3A)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatScreen(otherUserId: otherId, otherUserName: name),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
