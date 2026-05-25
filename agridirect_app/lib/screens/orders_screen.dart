import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import 'order_tracking_screen.dart';
import 'chat_screen.dart';
import '../services/cache_service.dart';
import '../utils/vibrant_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = ['All', 'Pending', 'Confirmed', 'In Transit', 'Delivered'];
  final _statusMap = {
    'All': 'all',
    'Pending': 'pending',
    'Confirmed': 'confirmed',
    'In Transit': 'dispatched',
    'Delivered': 'delivered',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  void _loadOrders() async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final userId = authProvider.currentUserId;

    if (authProvider.userRole == 'admin') {
      orderProvider.fetchAllOrders();
      return;
    }

    try {
      // Check if they have a farmer record (even an auto-generated one)
      final farmerResponse = await Supabase.instance.client
          .from('farmers')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      if (farmerResponse.isNotEmpty && mounted) {
        // They are a farmer, fetch BOTH their farmer and buyer orders
        orderProvider.fetchFarmerOrders(farmerResponse.first['id'], userId);
      } else if (mounted) {
        // Just a regular buyer
        orderProvider.fetchBuyerOrders(userId);
      }
    } catch (_) {
      if (mounted) orderProvider.fetchBuyerOrders(userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isFarmer = authProvider.userRole == 'farmer';

    return Scaffold(
      backgroundColor: VibrantTheme.softBackground,
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: VibrantTheme.primaryGradient)),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: VibrantTheme.primaryGreen));
          }

          final ageMessage = CacheService.getCacheAgeMessage('orders');

          return Column(
            children: [
              if (ageMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.amber[50],
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 16, color: Colors.amber[800]),
                      const SizedBox(width: 8),
                      Text(
                        'Viewing offline copy ($ageMessage)',
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    final status = _statusMap[tab]!;
                    final orders = orderProvider.getOrdersByStatus(status);

                    if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey[200]),
                            const SizedBox(height: 16),
                            Text('No $tab orders yet', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _loadOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 20),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final isBuyer = order.buyerId == authProvider.currentUserId;
                          final isFarmerViewForOrder = !isBuyer; // If they are not the buyer, they must be the farmer/admin

                          return OrderCard(
                            order: order,
                            isFarmerView: isFarmerViewForOrder,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(initialOrder: order))),
                            onAccept: () => orderProvider.updateOrderStatus(order.id, 'confirmed'),
                            onDispatch: () => orderProvider.updateOrderStatus(order.id, 'dispatched'),
                            onCancel: () => orderProvider.updateOrderStatus(order.id, 'cancelled'),
                            onMessage: () {
                              final otherId = isFarmerViewForOrder ? order.buyerId : order.farmerId;
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: otherId, otherUserName: isFarmerViewForOrder ? 'Buyer' : 'Farmer')));
                            },
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
