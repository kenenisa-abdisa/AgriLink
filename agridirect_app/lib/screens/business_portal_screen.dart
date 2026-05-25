import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../widgets/product_card.dart';
import 'bulk_order_screen.dart';
import 'product_detail_screen.dart';

class BusinessPortalScreen extends StatefulWidget {
  const BusinessPortalScreen({super.key});

  @override
  State<BusinessPortalScreen> createState() => _BusinessPortalScreenState();
}

class _BusinessPortalScreenState extends State<BusinessPortalScreen> {
  List<ProductModel> _bulkSuppliers = [];
  List<OrderModel> _standingOrders = [];
  List<OrderModel> _allBusinessOrders = [];
  bool _isLoading = true;

  double get _totalSpentThisMonth {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    return _allBusinessOrders
        .where((o) => o.createdAt.isAfter(firstDay) && o.status == 'delivered')
        .fold(0, (sum, o) => sum + o.totalAmount);
  }

  Map<String, double> get _topSuppliers {
    final Map<String, double> spends = {};
    for (var o in _allBusinessOrders) {
      if (o.status == 'delivered') {
        final name = o.farmerName ?? 'Supplier';
        spends[name] = (spends[name] ?? 0) + o.totalAmount;
      }
    }
    return spends;
  }

  @override
  void initState() {
    super.initState();
    _loadPortalData();
  }

  Future<void> _loadPortalData() async {
    setState(() => _isLoading = true);
    final client = Supabase.instance.client;
    final userId = context.read<AuthProvider>().currentUserId;

    try {
      // 1. Fetch products with bulk availability
      final productRes = await client
          .from('products')
          .select('*, farmers(farm_name)')
          .eq('bulk_available', true)
          .order('created_at', ascending: false);
      
      // 2. Fetch recurring orders for this business
      final ordersRes = await client
          .from('orders')
          .select('*, order_items(*)')
          .eq('buyer_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allBusinessOrders = (ordersRes as List)
              .map((o) => OrderModel.fromJson(o, items: (o['order_items'] as List).map((i) => OrderItemModel.fromJson(i)).toList()))
              .toList();
          _standingOrders = _allBusinessOrders.where((o) => o.isRecurring).toList();
          _bulkSuppliers = (productRes as List)
              .map((p) => ProductModel.fromJson(p, farmerName: p['farmers']?['farm_name']))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF1B6B3A),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Business Portal', style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B6B3A), Color(0xFF2D8B4E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Order in bulk, save more',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_bulkSuppliers.isEmpty && _standingOrders.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No bulk listings available yet.')),
            )
          else ...[
            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _portalActionCard(
                        'New Bulk Order',
                        Icons.add_shopping_cart,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkOrderScreen())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _portalActionCard(
                        'Bulk Analytics',
                        Icons.bar_chart,
                        () {}, // Will handle in dashboard tab
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Business Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _statBox('ETB ${_totalSpentThisMonth.toStringAsFixed(0)}', 'Spent (Month)', Colors.green),
                    const SizedBox(width: 12),
                    _statBox(_topSuppliers.length.toString(), 'Pro Suppliers', Colors.blue),
                  ],
                ),
              ),
            ),

            // Upcoming Deliveries Placeholder
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text('Delivery Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Next scheduled: Tomorrow (Wednesday)', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            // Standing Orders Section
            if (_standingOrders.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text('My Standing Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = _standingOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFF1B6B3A), child: Icon(Icons.repeat, color: Colors.white)),
                        title: Text('Every ${order.recurrenceInterval ?? 'Order'}'),
                        subtitle: Text('Total: ETB ${order.totalAmount.toStringAsFixed(0)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    );
                  },
                  childCount: _standingOrders.length,
                ),
              ),
            ],

            // Bulk Suppliers Section
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text('Browse Bulk Suppliers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _bulkSuppliers[index];
                    return ProductCard(
                      product: product,
                      farmerName: product.farmerName,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                    );
                  },
                  childCount: _bulkSuppliers.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ],
      ),
    );
  }

  Widget _statBox(String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _portalActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1B6B3A), size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
