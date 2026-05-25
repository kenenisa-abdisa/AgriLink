import 'package:flutter/material.dart';
import '../models/order_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'dispatched':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPremiumHorizontalStepper() {
    final status = order.status;
    final isCancelled = status == 'cancelled';
    
    if (isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.cancel_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Cancelled',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This order has been cancelled and cannot be processed further.',
                    style: TextStyle(fontSize: 12, color: Colors.red[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Status matching for steps
    final int currentStep;
    switch (status) {
      case 'pending':
        currentStep = 0;
        break;
      case 'confirmed':
        currentStep = 1;
        break;
      case 'dispatched':
        currentStep = 2;
        break;
      case 'delivered':
        currentStep = 3;
        break;
      default:
        currentStep = 0;
    }

    final steps = [
      {'title': 'Placed', 'icon': Icons.shopping_bag_outlined},
      {'title': 'Confirmed', 'icon': Icons.assignment_turned_in_outlined},
      {'title': 'Dispatched', 'icon': Icons.local_shipping_outlined},
      {'title': 'Delivered', 'icon': Icons.home_work_outlined},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final title = step['title'] as String;
              final icon = step['icon'] as IconData;
              final isActive = index <= currentStep;
              final isCurrent = index == currentStep;
              
              final stepColor = isActive
                  ? const Color(0xFF1B6B3A)
                  : Colors.grey[300]!;

              return Expanded(
                child: Column(
                  children: [
                    // Icon + Circle container
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? const Color(0xFF1B6B3A).withValues(alpha: 0.1)
                            : Colors.grey[50],
                        border: Border.all(
                          color: stepColor,
                          width: isCurrent ? 2.5 : 1.5,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: stepColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? Colors.black : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          // Progress Line Indicator overlay
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: currentStep / (steps.length - 1),
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B6B3A)),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text('Order #${order.id.substring(0, 8).toUpperCase()}'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status horizontal stepper (premium)
            _buildPremiumHorizontalStepper(),
            const SizedBox(height: 24),

            // Order items
            const Text('Order Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} × ${item.quantity.toStringAsFixed(0)} ${item.unit ?? ''}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              'ETB ${(item.price * item.quantity).toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(
                          'ETB ${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B6B3A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order details
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (order.paymentMethod != null)
                      _row('Payment', order.paymentMethod!),
                    if (order.deliveryAddress != null)
                      _row('Delivery Address', order.deliveryAddress!),
                    if (order.notes != null)
                      _row('Notes', order.notes!),
                    _row('Order Date', timeago.format(order.createdAt)),
                    if (order.isBulk) _row('Type', 'Bulk Order'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child:
                Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
