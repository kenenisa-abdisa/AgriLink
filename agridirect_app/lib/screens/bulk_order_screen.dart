import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';
import '../models/farmer_model.dart';

class BulkOrderScreen extends StatefulWidget {
  const BulkOrderScreen({super.key});

  @override
  State<BulkOrderScreen> createState() => _BulkOrderScreenState();
}

class _BulkOrderScreenState extends State<BulkOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedFarmerId;
  List<ProductModel> _farmerProducts = [];
  final List<Map<String, dynamic>> _selectedItems = [];
  
  String _recurrenceInterval = 'one-time';
  String _recurrenceDay = 'Monday';
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoadingFarmers = true;
  List<FarmerModel> _farmers = [];

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    try {
      final res = await Supabase.instance.client.from('farmers').select();
      setState(() {
        _farmers = (res as List).map((f) => FarmerModel.fromJson(f)).toList();
        _isLoadingFarmers = false;
      });
    } catch (e) {
      setState(() => _isLoadingFarmers = false);
    }
  }

  Future<void> _loadProducts(String farmerId) async {
    final res = await Supabase.instance.client
        .from('products')
        .select()
        .eq('farmer_id', farmerId)
        .eq('bulk_available', true);
    
    setState(() {
      _farmerProducts = (res as List).map((p) => ProductModel.fromJson(p)).toList();
      _selectedItems.clear();
    });
  }

  double get _totalEstimate {
    double total = 0;
    for (var item in _selectedItems) {
      final product = item['product'] as ProductModel;
      final qty = item['quantity'] as double;
      final price = (product.bulkPrice != null && qty >= (product.bulkMinQuantity ?? 0))
          ? product.bulkPrice!
          : product.price;
      total += price * qty;
    }
    return total;
  }

  Future<void> _submitQuoteRequest() async {
    if (!_formKey.currentState!.validate() || _selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select items and fill address')));
      return;
    }

    setState(() => _isLoadingFarmers = true);
    final userId = context.read<AuthProvider>().currentUserId;

    try {
      final orderRes = await Supabase.instance.client.from('orders').insert({
        'buyer_id': userId,
        'farmer_id': _selectedFarmerId,
        'total_amount': _totalEstimate,
        'delivery_address': _addressController.text,
        'status': 'quote_requested',
        'is_bulk': true,
        'is_recurring': _recurrenceInterval != 'one-time',
        'recurrence_interval': _recurrenceInterval == 'one-time' ? null : _recurrenceInterval,
        'recurrence_day': _recurrenceInterval == 'one-time' ? null : _recurrenceDay,
        'notes': _notesController.text,
      }).select().single();

      final orderId = orderRes['id'];

      final itemsToInsert = _selectedItems.map((item) {
        final ProductModel p = item['product'];
        final double qty = item['quantity'];
        return {
          'order_id': orderId,
          'product_id': p.id,
          'product_name': p.name,
          'quantity': qty,
          'unit': p.unit,
          'price': (p.bulkPrice != null && qty >= (p.bulkMinQuantity ?? 0)) ? p.bulkPrice : p.price,
        };
      }).toList();

      await Supabase.instance.client.from('order_items').insert(itemsToInsert);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote request sent successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFarmers = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Order Request'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingFarmers 
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Supplier', border: OutlineInputBorder()),
                    items: _farmers.map((f) => DropdownMenuItem(value: f.id, child: Text(f.farmName ?? 'Unnamed Farm'))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedFarmerId = val;
                      });
                      if (val != null) _loadProducts(val);
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  if (_selectedFarmerId != null) ...[
                    const Text('Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._farmerProducts.map((p) {
                      bool isSelected = _selectedItems.any((i) => (i['product'] as ProductModel).id == p.id);
                      return CheckboxListTile(
                        title: Text(p.name),
                        subtitle: Text('Min: ${(p.bulkMinQuantity ?? p.minOrder).toStringAsFixed(0)} ${p.unit}'),
                        value: isSelected,
                        activeColor: const Color(0xFF1B6B3A),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedItems.add({'product': p, 'quantity': p.bulkMinQuantity ?? p.minOrder});
                            } else {
                              _selectedItems.removeWhere((i) => (i['product'] as ProductModel).id == p.id);
                            }
                          });
                        },
                      );
                    }),
                    
                    if (_selectedItems.isNotEmpty) ...[
                      const Divider(),
                      ..._selectedItems.map((item) {
                        final p = item['product'] as ProductModel;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(child: Text(p.name)),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  initialValue: item['quantity'].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Qty'),
                                  onChanged: (val) {
                                    setState(() {
                                      item['quantity'] = double.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(p.unit),
                            ],
                          ),
                        );
                      }),
                    ],
                    
                    const SizedBox(height: 20),
                    const Text('Delivery Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      initialValue: _recurrenceInterval,
                      items: const [
                        DropdownMenuItem(value: 'one-time', child: Text('One-time Order')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      ],
                      onChanged: (val) => setState(() => _recurrenceInterval = val!),
                    ),
                    if (_recurrenceInterval != 'one-time') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _recurrenceDay,
                        items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                            .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) => setState(() => _recurrenceDay = val!),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Delivery Address', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Special Instructions', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('ETB ${_totalEstimate.toStringAsFixed(0)}', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitQuoteRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6B3A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Request Quote', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
