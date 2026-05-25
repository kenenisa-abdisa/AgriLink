import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import 'farmer_earnings_screen.dart';
import '../models/order_model.dart';
import '../widgets/quote_bottom_sheet.dart';
import '../services/invoice_service.dart';
import 'notifications_screen.dart';
import '../widgets/notification_bell.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeListings = 0;
  int _pendingOrders = 0;
  double _monthEarnings = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Proactive sync for users who might be incorrectly tagged as buyers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().syncRole();
    });
  }

  Future<void> _loadStats() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;

    try {
      // Count active listings
      final products = await Supabase.instance.client
          .from('products')
          .select('id')
          .eq('user_id', userId);
      _activeListings = (products as List).length;

      // Get farmer_id
      final farmerResp = await Supabase.instance.client
          .from('farmers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (farmerResp != null) {
        final farmerId = farmerResp['id'];

        // Count pending orders
        final pendingOrders = await Supabase.instance.client
            .from('orders')
            .select('id')
            .eq('farmer_id', farmerId)
            .eq('status', 'pending');
        _pendingOrders = (pendingOrders as List).length;

        // Calculate month earnings
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final deliveredOrders = await Supabase.instance.client
            .from('orders')
            .select('total_amount')
            .eq('farmer_id', farmerId)
            .eq('status', 'delivered')
            .gte('created_at', startOfMonth.toIso8601String());
        _monthEarnings = (deliveredOrders as List)
            .fold(0.0, (sum, o) => sum + (o['total_amount'] ?? 0).toDouble());
      }
    } catch (_) {}

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isFarmer = authProvider.userRole == 'farmer';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          const NotificationBell(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              Text(
                'Welcome back, ${authProvider.userName}! 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isFarmer ? 'Farmer Dashboard' : (authProvider.userRole == 'business' ? 'Business Dashboard' : 'Buyer Dashboard'),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Business Portal Quick Link
              if (authProvider.userRole == 'business')
                _businessPortalLink(),

              // Stats row
              if (isFarmer) _farmerStats() else _buyerStats(),
              const SizedBox(height: 24),

              // Farmer: earnings chart
              if (isFarmer) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monthly Earnings',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FarmerEarningsScreen()),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 16),
                      label: const Text('View Analytics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6B3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FarmerEarningsScreen()),
                    );
                  },
                  child: _earningsChart(),
                ),
                const SizedBox(height: 24),

                // My listings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Listings',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddProductScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add New'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _farmerListings(),
                
                const SizedBox(height: 24),
                const Text('Business & Bulk Orders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _farmerBusinessOrders(),
              ],

              // Buyer: recent orders
              if (!isFarmer) ...[
                const Text('Recent Orders',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buyerRecentOrders(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _farmerStats() {
    return Row(
      children: [
        _statCard('ETB ${_monthEarnings.toStringAsFixed(0)}', 'This Month',
            Icons.monetization_on, Colors.green),
        const SizedBox(width: 10),
        _statCard('$_activeListings', 'Listings',
            Icons.inventory_2, Colors.blue),
        const SizedBox(width: 10),
        _statCard('$_pendingOrders', 'Pending',
            Icons.pending_actions, Colors.orange),
      ],
    );
  }

  Widget _buyerStats() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final total = orderProvider.orders.length;
        final pending =
            orderProvider.orders.where((o) => o.status == 'pending').length;
        return Row(
          children: [
            _statCard('$total', 'Orders', Icons.receipt, Colors.blue),
            const SizedBox(width: 10),
            _statCard('$pending', 'Pending',
                Icons.pending_actions, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _earningsChart() {
    // Simple bar chart using containers
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ETB ${_monthEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold,
                      color: Color(0xFF1B6B3A)),
                ),
                const Text('This Month',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar('Consumers', 0.6, Colors.green),
                const SizedBox(width: 8),
                _bar('Restaurants', 0.3, Colors.orange),
                const SizedBox(width: 8),
                _bar('Shops', 0.1, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(String label, double fraction, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 80 * fraction,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _farmerListings() {
    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('products')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!
            .where((p) => p['user_id'] == userId)
            .toList();

        if (products.isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No listings yet. Add your first product!'),
              ),
            ),
          );
        }

        return Column(
          children: products.take(5).map((p) {
            final product = ProductModel.fromJson(p);
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(product.productEmoji,
                    style: const TextStyle(fontSize: 28)),
                title: Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${product.quantity.toStringAsFixed(0)} ${product.unit} · ETB ${product.price.toStringAsFixed(0)}'),
                trailing: const Icon(Icons.edit_outlined,
                    color: Color(0xFF1B6B3A)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailScreen(product: product),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buyerRecentOrders() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        if (orderProvider.orders.isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No orders yet. Browse the marketplace!'),
              ),
            ),
          );
        }

        return Column(
          children: orderProvider.orders.take(5).map((order) {
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1B6B3A)
                      .withValues(alpha: 0.1),
                  child: const Icon(Icons.receipt,
                      color: Color(0xFF1B6B3A)),
                ),
                title: Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle:
                    Text('ETB ${order.totalAmount.toStringAsFixed(0)}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status == 'delivered'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: order.status == 'delivered'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _farmerBusinessOrders() {
    final authProvider = context.read<AuthProvider>();
    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('farmers')
          .select('id')
          .eq('user_id', authProvider.currentUserId)
          .maybeSingle(),
      builder: (context, farmerSnap) {
        if (!farmerSnap.hasData || farmerSnap.data == null) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No business orders yet.'))));
        }
        final farmerId = farmerSnap.data!['id'] as String;
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('orders')
              .stream(primaryKey: ['id'])
              .eq('farmer_id', farmerId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final bizOrders = snapshot.data!.where((o) => o['is_bulk'] == true).toList();
            if (bizOrders.isEmpty) {
              return const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No business orders yet.'))));
            }
            return Column(
              children: bizOrders.map((o) {
                final order = OrderModel.fromJson(o);
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.business, color: Colors.white, size: 18)),
                    title: Text('Business Order #${order.id.substring(0,6).toUpperCase()}'),
                    subtitle: Text('Status: ${order.statusDisplay}'),
                    trailing: order.status == 'quote_requested' 
                      ? ElevatedButton(
                          onPressed: () => _showQuoteSheet(order), 
                          child: const Text('Quote'),
                        )
                      : (order.status == 'delivered' 
                          ? IconButton(
                              icon: const Icon(Icons.download, color: Colors.blue),
                              onPressed: () => InvoiceService().generateAndPrintInvoice(order),
                            )
                          : const Icon(Icons.chevron_right)),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  void _showQuoteSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: QuoteBottomSheet(order: order),
      ),
    );
  }

  Widget _businessPortalLink() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1B6B3A), Color(0xFF2D8B4E)]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Business Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Access bulk ordering & recurring savings', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/business-portal'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1B6B3A)),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}