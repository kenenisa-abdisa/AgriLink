import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/farmer_model.dart';
import '../widgets/farmer_card.dart';
import '../widgets/skeleton_loader.dart';
import '../providers/farmer_provider.dart';
import 'farmer_profile_screen.dart';
import 'chat_screen.dart';
import 'farmer_registration_screen.dart';
import '../utils/vibrant_theme.dart';
import '../providers/auth_provider.dart';

class FarmersScreen extends StatefulWidget {
  const FarmersScreen({super.key});

  @override
  State<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends State<FarmersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'rating';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final farmerProvider = context.watch<FarmerProvider>();
    final isFarmer = authProvider.userRole == 'farmer';
    
    // Check if current user has a farmer profile in the list
    final currentFarmer = farmerProvider.farmers.cast<FarmerModel?>().firstWhere(
      (f) => f?.userId == authProvider.currentUserId,
      orElse: () => null,
    );

    final needsProfileCompletion = isFarmer && (currentFarmer == null || currentFarmer.bio == null || currentFarmer.region == null);

    return Scaffold(
      backgroundColor: VibrantTheme.softBackground,
      body: RefreshIndicator(
        onRefresh: () => context.read<FarmerProvider>().fetchFarmers(refresh: true),
        child: CustomScrollView(
          slivers: [
            // Modern Header
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: VibrantTheme.primaryGreen,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: VibrantTheme.primaryGradient,
                  ),
                  child: const SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meet Our Farmers (v2)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Direct connection with 100% local producers',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Search Bar Area
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: VibrantTheme.softShadow,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search by name or region...',
                            prefixIcon: const Icon(Icons.search, color: VibrantTheme.primaryGreen),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: VibrantTheme.softShadow,
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.sort_rounded, color: VibrantTheme.primaryGreen),
                        onSelected: (val) => setState(() => _sortBy = val),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'rating', child: Text('Top Rated')),
                          const PopupMenuItem(value: 'newest', child: Text('Newly Joined')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Farmers List
            Consumer<FarmerProvider>(
              builder: (context, provider, _) {
                
                if (provider.isLoading && provider.farmers.isEmpty) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((ctx, i) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: FarmerSkeleton(),
                      ), childCount: 3),
                    ),
                  );
                }

                List<FarmerModel> farmers = List.from(provider.farmers);
                
                // Filter and sort...
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  farmers = farmers.where((f) => f.displayName.toLowerCase().contains(q) || (f.region?.toLowerCase().contains(q) ?? false)).toList();
                }
                
                if (_sortBy == 'rating') {
                  farmers.sort((a, b) => b.rating.compareTo(a.rating));
                } else {
                  farmers.sort((a, b) => b.joinedDate.compareTo(a.joinedDate));
                }

                return SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),

                    if (farmers.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 100),
                            Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[200]),
                            const SizedBox(height: 16),
                            const Text('No farmers match your search', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    else
                      ...farmers.map((farmer) => FarmerCard(
                        farmer: farmer,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerProfileScreen(farmer: farmer))),
                        onViewProducts: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerProfileScreen(farmer: farmer))),
                        onMessage: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: farmer.userId, otherUserName: farmer.displayName))),
                      )),
                  ]),
                );
              },
            ),


            // Bottom Spacer for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: (authProvider.userRole != 'farmer' || needsProfileCompletion)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerRegistrationScreen())),
              backgroundColor: VibrantTheme.primaryGreen,
              foregroundColor: Colors.white,
              icon: Icon(needsProfileCompletion ? Icons.edit_note_rounded : Icons.agriculture_rounded),
              label: Text(needsProfileCompletion ? 'Complete Profile' : 'Become a Farmer'),
            )
          : null,
    );
  }
}
