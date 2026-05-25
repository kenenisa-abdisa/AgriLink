import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payment_service.dart';
import '../services/order_service.dart';
import 'payment_success_screen.dart';
import 'payment_failed_screen.dart';
import 'mock_chapa_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _deliveryOption = 'delivery';
  String _paymentMethod = 'Telebirr';
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  Future<void> _placeOrder() async {
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final authProvider = context.read<AuthProvider>();

    if (_deliveryOption == 'delivery' && _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final itemsByFarmer = cartProvider.itemsByFarmer;
      final isCod = _paymentMethod == 'Cash on Delivery';
      final txRef = isCod ? null : const Uuid().v4();
      final totalAmount = cartProvider.totalPrice;

      // Group items by farmer and create separate orders
      for (final entry in itemsByFarmer.entries) {
        String farmerId = entry.key;
        
        // 🚨 FIX: Ensure the ID we send to the orders table is a valid UUID in the farmers table.
        try {
          // 1. Try to find farmer by primary key
          final byId = await Supabase.instance.client.from('farmers').select('id').eq('id', farmerId).maybeSingle();
          if (byId != null) {
            farmerId = byId['id'];
          } else {
            // 2. Try to find farmer by user_id
            final byUser = await Supabase.instance.client.from('farmers').select('id').eq('user_id', farmerId).maybeSingle();
            if (byUser != null) {
              farmerId = byUser['id'];
            } else {
              // 3. Last resort: create a stub profile
              try {
                final newFarmer = await Supabase.instance.client.from('farmers').insert({
                  'user_id': farmerId,
                  'farm_name': 'Independent Seller',
                  'is_verified': false,
                  'rating': 0.0,
                  'total_reviews': 0,
                }).select('id').single();
                farmerId = newFarmer['id'];
              } catch (insertErr) {
                // If insert fails (e.g. duplicate user_id), try fetching one last time
                final lastDitch = await Supabase.instance.client.from('farmers').select('id').eq('user_id', farmerId).maybeSingle();
                if (lastDitch != null) {
                  farmerId = lastDitch['id'];
                } else {
                  rethrow; // Cannot resolve farmerId, must fail
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Farmer resolution error: $e');
          // If we can't resolve it, the order will likely fail at the DB level, 
          // but we've tried our best to find a valid ID.
        }

        final items = entry.value;
        final total = items.fold(0.0, (sum, item) => sum + item.totalPrice);

        final orderItems = items.map((item) {
          return OrderItemModel(
            id: '',
            orderId: '',
            productId: item.product.id,
            productName: item.product.name,
            quantity: item.quantity.toDouble(),
            unit: item.product.unit,
            price: item.product.price,
          );
        }).toList();

        await orderProvider.placeOrder(
          buyerId: authProvider.currentUserId,
          farmerId: farmerId,
          totalAmount: total,
          paymentMethod: _paymentMethod,
          paymentStatus: 'pending',
          paymentReference: txRef,
          deliveryAddress:
              _deliveryOption == 'delivery' ? _addressController.text : null,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
          items: orderItems,
        );
      }

      if (isCod) {
        cartProvider.clearCart();
        if (mounted) {
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentSuccessScreen(orderId: 'COD-ORDER', amount: totalAmount, paymentMethod: 'Cash on Delivery')));
        }
        return;
      }

      // Initialize Chapa Payment
      final paymentService = PaymentService();
      final checkoutUrl = await paymentService.initializePayment(
        amount: totalAmount,
        email: authProvider.userEmail.isNotEmpty ? authProvider.userEmail : 'buyer@agrilink.et',
        firstName: authProvider.userName.isNotEmpty ? authProvider.userName : 'Buyer',
        lastName: 'App',
        phoneNumber: authProvider.userPhone.isNotEmpty ? authProvider.userPhone : '0900000000',
        txRef: txRef!,
      );

      if (checkoutUrl != null) {
        if (!mounted) return;
        // Intercept simulated mock payments
        if (checkoutUrl.contains('mock-checkout')) {
           final success = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => MockChapaScreen(amount: totalAmount, txRef: txRef)));
           
           if (success == true) {
             await OrderService().updatePaymentStatus(txRef, 'paid');
             cartProvider.clearCart();
             if (mounted) {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentSuccessScreen(orderId: txRef.substring(0, 8), amount: totalAmount, paymentMethod: _paymentMethod)));
             }
           } else {
             if (mounted) {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentFailedScreen(
                 errorMessage: 'Payment cancelled in simulation environment.',
                 onRetry: () => Navigator.pop(context),
                 onPayOnDelivery: () async {
                    cartProvider.clearCart();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentSuccessScreen(orderId: txRef.substring(0, 8), amount: totalAmount, paymentMethod: 'Converted to Cash on Delivery')));
                 }
               )));
             }
           }
           return;
        }

        // Launch In-App Browser for REAL Chapa Checkout
        final uri = Uri.parse(checkoutUrl);
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);

        // Wait for browser close, then verify
        setState(() => _isLoading = true);
        final isVerified = await paymentService.verifyPayment(txRef);

        if (isVerified) {
          // Update order statuses
          await OrderService().updatePaymentStatus(txRef, 'paid');
          cartProvider.clearCart();
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentSuccessScreen(orderId: txRef.substring(0, 8), amount: totalAmount, paymentMethod: _paymentMethod)));
          }
        } else {
          // Failed to verify
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentFailedScreen(
              errorMessage: 'The transaction was closed or failed verification. Your order is pending.',
              onRetry: () => Navigator.pop(context),
              onPayOnDelivery: () async {
                 cartProvider.clearCart();
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentSuccessScreen(orderId: txRef.substring(0, 8), amount: totalAmount, paymentMethod: 'Converted to Cash on Delivery')));
              }
            )));
          }
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            const Text('Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: cartProvider.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(item.product.productEmoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.product.name} x${item.quantity}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            'ETB ${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Delivery option
            const Text('Delivery Option',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _optionCard('🚚 Delivery', 'delivery'),
                const SizedBox(width: 12),
                _optionCard('📦 Pickup', 'pickup'),
              ],
            ),
            const SizedBox(height: 16),

            // Delivery address
            if (_deliveryOption == 'delivery') ...[
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  hintText: 'Enter your delivery address',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Payment method
            const Text('Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: paymentMethods.map((method) {
                final isSelected = _paymentMethod == method;
                return ChoiceChip(
                  label: Text(method),
                  selected: isSelected,
                  selectedColor:
                      const Color(0xFF1B6B3A).withValues(alpha: 0.2),
                  onSelected: (_) =>
                      setState(() => _paymentMethod = method),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Order Notes (Optional)',
                hintText: 'Any special instructions...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Total
            Card(
              color: const Color(0xFF1B6B3A).withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'ETB ${cartProvider.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B6B3A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            CustomButton(
              text: 'Place Order',
              onPressed: _placeOrder,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(String label, String value) {
    final isSelected = _deliveryOption == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _deliveryOption = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1B6B3A).withValues(alpha: 0.1)
                : Colors.white,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1B6B3A)
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF1B6B3A)
                    : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
