import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/farmer_model.dart';
import 'package:intl/intl.dart';

class FarmersScreen extends StatefulWidget {
  const FarmersScreen({super.key});

  @override
  State<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends State<FarmersScreen> {
  final AdminService _adminService = AdminService();
  List<FarmerModel>? _farmers;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    setState(() => _isLoading = true);
    try {
      final farmers = await _adminService.fetchFarmers();
      setState(() {
        _farmers = farmers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<FarmerModel> displayedFarmers = _farmers ?? [];
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      displayedFarmers = displayedFarmers
          .where((f) =>
              (f.farmName.toLowerCase().contains(q)) ||
              (f.displayName?.toLowerCase().contains(q) ?? false) ||
              (f.region?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Management'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by name or region...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(onPressed: _loadFarmers, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      columns: const [
                        DataColumn(label: Text('Farm Name')),
                        DataColumn(label: Text('Owner')),
                        DataColumn(label: Text('Region')),
                        DataColumn(label: Text('Rating')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Joined')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: displayedFarmers.map((farmer) {
                        return DataRow(cells: [
                          DataCell(Text(farmer.farmName)),
                          DataCell(Text(farmer.displayName ?? 'Unknown')),
                          DataCell(Text(farmer.region ?? '—')),
                          DataCell(
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(farmer.rating.toStringAsFixed(1)),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: farmer.isVerified ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                farmer.isVerified ? 'Verified' : 'Pending',
                                style: TextStyle(
                                  color: farmer.isVerified ? Colors.green : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(DateFormat('MMM dd, yyyy').format(farmer.joinedDate))),
                          DataCell(
                            Row(
                              children: [
                                if (!farmer.isVerified)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                    tooltip: 'Verify Farmer',
                                    onPressed: () => _handleVerify(farmer),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.block, color: Colors.red),
                                  tooltip: 'Suspend Account',
                                  onPressed: () => _handleSuspend(farmer),
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

  Future<void> _handleVerify(FarmerModel farmer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Farmer?'),
        content: Text('This will mark ${farmer.farmName} as a verified supplier.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Verify Now'),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (!mounted) return;
      await _adminService.verifyFarmer(farmer.id, farmer.userId);
      _loadFarmers();
    }
  }

  Future<void> _handleSuspend(FarmerModel farmer) async {
     final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Account?'),
        content: Text('Are you sure you want to suspend access for ${farmer.displayName}? They will no longer be able to log in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _adminService.suspendUser(farmer.userId, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User suspended successfully.')));
    }
  }
}
