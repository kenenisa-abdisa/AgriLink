import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.fetchDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final fmt = NumberFormat.currency(symbol: 'ETB ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadStats, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Marketplace Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 4 : 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.8,
                children: [
                   _StatCard(
                    title: 'Total Revenue',
                    value: fmt.format(_stats?['totalRevenue'] ?? 0),
                    icon: Icons.payments,
                    color: Colors.green,
                    trend: '+12% from last month',
                  ),
                  _StatCard(
                    title: 'Farmers Registered',
                    value: (_stats?['totalFarmers'] ?? 0).toString(),
                    icon: Icons.agriculture,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Total Orders',
                    value: (_stats?['totalOrders'] ?? 0).toString(),
                    icon: Icons.shopping_basket,
                    color: Colors.blue,
                  ),
                   _StatCard(
                    title: 'New Today',
                    value: (_stats?['registrationsToday'] ?? 0).toString(),
                    icon: Icons.person_add,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Quick Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniCard(
                    title: 'Total Products',
                    value: (_stats?['totalProducts'] ?? 0).toString(),
                    subtitle: 'Active listings',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MiniCard(
                    title: 'Buyer Base',
                    value: (_stats?['totalBuyers'] ?? 0).toString(),
                    subtitle: 'Unique accounts',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MiniCard(
                    title: 'System Status',
                    value: 'Healthy',
                    subtitle: 'All services online',
                    isGood: true,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (trend != null)
                    Text(trend!, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool isGood;

  const _MiniCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.isGood = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isGood ? Colors.green : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
