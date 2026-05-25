import 'package:flutter/material.dart';
import '../models/order_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../utils/vibrant_theme.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isFarmerView;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDispatch;
  final VoidCallback? onMessage;
  final VoidCallback? onCancel;

  const OrderCard({
    super.key,
    required this.order,
    this.isFarmerView = false,
    this.onTap,
    this.onAccept,
    this.onDispatch,
    this.onMessage,
    this.onCancel,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return VibrantTheme.primaryGreen;
      case 'dispatched': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: VibrantTheme.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        timeago.format(order.createdAt),
                        style: const TextStyle(fontSize: 12, color: VibrantTheme.textGrey),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(order.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.statusDisplay,
                      style: TextStyle(color: _statusColor(order.status), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (order.items.isNotEmpty) ...[
                Text(
                  order.items.map((i) => '${i.productName} x${i.quantity.toStringAsFixed(0)}').join(', '),
                  style: const TextStyle(fontSize: 14, color: VibrantTheme.textDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} ETB',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: VibrantTheme.primaryGreen),
                  ),
                  if (order.paymentMethod != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                      child: Text(order.paymentMethod!, style: const TextStyle(fontSize: 10, color: VibrantTheme.textGrey)),
                    ),
                ],
              ),
              if (isFarmerView && order.status == 'pending') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VibrantTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Accept Order'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
