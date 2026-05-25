import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final AdminService _adminService = AdminService();
  List<OrderModel>? _orders;
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _adminService.fetchOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _exportToCSV() {
    if (_orders == null || _orders!.isEmpty) return;

    List<List<dynamic>> rows = [];
    // Header
    rows.add(['Order ID', 'Buyer', 'Farmer', 'Amount', 'Status', 'Date']);

    for (var order in _orders!) {
      rows.add([
        order.id,
        order.buyerName ?? 'Unknown',
        order.farmerName ?? 'Unknown',
        order.totalAmount,
        order.status,
        DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt),
      ]);
    }

    String csvData = rows.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');
    
    // Modern web export using package:web
    final blob = web.Blob([csvData.toJS].toJS, web.BlobPropertyBag(type: 'text/csv'));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = 'agrilink_orders_${DateTime.now().millisecondsSinceEpoch}.csv';
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  @override
  Widget build(BuildContext context) {
    List<OrderModel> displayed = _orders ?? [];
    if (_statusFilter != 'all') {
      displayed = displayed.where((o) => o.status == _statusFilter).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          _buildFilter('All', 'all'),
          _buildFilter('Pending', 'pending'),
          _buildFilter('Delivered', 'delivered'),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _exportToCSV,
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh)),
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
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Buyer')),
                        DataColumn(label: Text('Farmer')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Date')),
                      ],
                      rows: displayed.map((order) {
                        return DataRow(cells: [
                          DataCell(Text(order.id.substring(0, 8))),
                          DataCell(Text(order.buyerName ?? '—')),
                          DataCell(Text(order.farmerName ?? '—')),
                          DataCell(Text('ETB ${order.totalAmount}')),
                          DataCell(_StatusChip(status: order.status)),
                          DataCell(Text(DateFormat('MMM dd, HH:mm').format(order.createdAt))),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFilter(String label, String value) {
    bool isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (s) => setState(() => _statusFilter = value),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'delivered':
        color = Colors.green;
      case 'pending':
        color = Colors.orange;
      case 'cancelled':
        color = Colors.red;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
