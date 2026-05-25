import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/product_model.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final AdminService _adminService = AdminService();
  List<ProductModel>? _products;
  bool _isLoading = true;
  String _filter = 'all'; // all, pending, approved

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _adminService.fetchProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ProductModel> displayedProducts = _products ?? [];
    if (_filter == 'pending') {
      displayedProducts = displayedProducts.where((p) => !p.isApproved).toList();
    } else if (_filter == 'approved') {
      displayedProducts = displayedProducts.where((p) => p.isApproved).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Moderation'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Approved', 'approved'),
          const SizedBox(width: 16),
          IconButton(onPressed: _loadProducts, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                      columns: const [
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Farmer')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: displayedProducts.map((product) {
                        return DataRow(cells: [
                          DataCell(
                            Row(
                              children: [
                                Text('${product.name} '),
                                if (product.imageUrls.isNotEmpty)
                                  const Icon(Icons.image, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                          DataCell(Text(product.farmerName ?? 'Unknown')),
                          DataCell(Text(product.category)),
                          DataCell(Text('${product.price} / ${product.unit}')),
                          DataCell(Text(product.quantity.toString())),
                          DataCell(
                            _StatusBadge(isApproved: product.isApproved),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    product.isApproved ? Icons.visibility_off : Icons.visibility,
                                    color: product.isApproved ? Colors.orange : Colors.green,
                                  ),
                                  tooltip: product.isApproved ? 'Unapprove' : 'Approve',
                                  onPressed: () => _handleApproval(product),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Remove Listing',
                                  onPressed: () => _handleDelete(product),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filter = value);
      },
      selectedColor: const Color(0xFF1B6B3A).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1B6B3A) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _handleApproval(ProductModel product) async {
    await _adminService.updateProductApproval(product.id, !product.isApproved);
    _loadProducts();
  }

  Future<void> _handleDelete(ProductModel product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to remove "${product.name}" from the marketplace? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _adminService.deleteProduct(product.id);
      _loadProducts();
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isApproved;
  const _StatusBadge({required this.isApproved});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isApproved ? 'Approved' : 'Pending',
        style: TextStyle(
          color: isApproved ? Colors.green : Colors.orange,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
