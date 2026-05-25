import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class QuoteBottomSheet extends StatefulWidget {
  final OrderModel order;
  const QuoteBottomSheet({super.key, required this.order});

  @override
  State<QuoteBottomSheet> createState() => _QuoteBottomSheetState();
}

class _QuoteBottomSheetState extends State<QuoteBottomSheet> {
  final List<TextEditingController> _priceControllers = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (var item in widget.order.items) {
      _priceControllers.add(TextEditingController(text: item.price.toStringAsFixed(0)));
    }
  }

  double get _newTotal {
    double total = 0;
    for (int i = 0; i < widget.order.items.length; i++) {
      final price = double.tryParse(_priceControllers[i].text) ?? 0;
      total += price * widget.order.items[i].quantity;
    }
    return total;
  }

  Future<void> _sendQuote() async {
    setState(() => _isSubmitting = true);
    try {
      final client = Supabase.instance.client;

      // 1. Update order total
      await client.from('orders').update({
        'total_amount': _newTotal,
        'status': 'confirmed', // Business policy: sending quote = confirming availability at a price
      }).eq('id', widget.order.id);

      // 2. Update item prices
      for (int i = 0; i < widget.order.items.length; i++) {
        await client.from('order_items').update({
          'price': double.tryParse(_priceControllers[i].text) ?? 0,
        }).eq('id', widget.order.items[i].id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote sent and order confirmed!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Finalize Bulk Quote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Adjust prices for business order #${widget.order.id.substring(0, 6).toUpperCase()}', 
            style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ...List.generate(widget.order.items.length, (index) {
            final item = widget.order.items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('${item.quantity} ${item.unit ?? "kg"}')),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _priceControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price/unit', prefixText: 'ETB '),
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Calculated Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('ETB ${_newTotal.toStringAsFixed(0)}', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _sendQuote,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6B3A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirm & Send Quote'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
