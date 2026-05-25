import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/farmer_model.dart';
import '../models/product_model.dart';
import '../utils/vibrant_theme.dart';
import '../widgets/product_card.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'product_detail_screen.dart';
import 'chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'reviews_screen.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../providers/localization_provider.dart';

class FarmerProfileScreen extends StatelessWidget {
  final FarmerModel farmer;

  const FarmerProfileScreen({super.key, required this.farmer});

  @override
  Widget build(BuildContext context) {
    final name = farmer.user?.name ?? farmer.displayName;
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with farmer info
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1B6B3A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B6B3A), Color(0xFF2D8B4E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          backgroundImage: farmer.user?.profileImage != null
                              ? CachedNetworkImageProvider(farmer.user!.profileImage!)
                              : null,
                          child: farmer.user?.profileImage == null
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'F',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (farmer.isVerified) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.verified,
                                        color: Colors.white, size: 20),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.white70, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    farmer.displayLocation,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsScreen(farmer: farmer)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            RatingBarIndicator(
                              rating: farmer.rating,
                              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                              itemCount: 5,
                              itemSize: 24.0,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              farmer.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${farmer.totalReviews} reviews)',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  FutureBuilder<List<ReviewModel>>(
                    future: ReviewService().getReviewsForFarmer(farmer.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                      
                      final reviews = snapshot.data!.take(3).toList();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recent Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: reviews.map((r) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1B6B3A),
                                  child: Text((r.buyerName?.isNotEmpty ?? false) ? r.buyerName![0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(r.buyerName ?? 'Anonymous Buyer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    RatingBarIndicator(
                                      rating: r.rating,
                                      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                                      itemCount: 5,
                                      itemSize: 12.0,
                                    ),
                                  ],
                                ),
                                subtitle: r.comment != null && r.comment!.isNotEmpty 
                                  ? Text(r.comment!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))
                                  : const Text('No comment attached', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)),
                              )).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Contact info
                  if (farmer.user != null) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Contact',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            if (farmer.user!.phone.isNotEmpty)
                              GestureDetector(
                                onTap: () async {
                                  final uri = Uri.parse(
                                      'tel:${farmer.user!.phone}');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone,
                                        color: Color(0xFF1B6B3A), size: 20),
                                    const SizedBox(width: 8),
                                    Text(farmer.user!.phone,
                                        style: const TextStyle(
                                            color: Color(0xFF1B6B3A),
                                            decoration:
                                                TextDecoration.underline)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.email,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(farmer.user!.email,
                                    style: TextStyle(
                                        color: Colors.grey[700])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // About / Bio
                  if (farmer.bio != null && farmer.bio!.isNotEmpty) ...[
                    const Text('About',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      farmer.bio!,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Certifications
                  if (farmer.certifications.isNotEmpty) ...[
                    const Text('Certifications',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: farmer.certifications.map((c) {
                        return Chip(
                          avatar: const Icon(Icons.verified,
                              color: Color(0xFF1B6B3A), size: 18),
                          label: Text(c),
                          backgroundColor: const Color(0xFF1B6B3A)
                              .withValues(alpha: 0.1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Farm details
                  if (farmer.farmSize != null) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (farmer.farmName != null)
                              _infoRow('Farm Name', farmer.farmName!),
                            _infoRow('Farm Size',
                                '${farmer.farmSize} hectares'),
                            _infoRow('Member Since',
                                '${farmer.joinedDate.month}/${farmer.joinedDate.year}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: VibrantTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: VibrantTheme.vibrantShadow,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUserId: farmer.userId,
                                    otherUserName: name,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.message_rounded, color: Colors.white),
                            label: Text(context.read<LocalizationProvider>().translate('Contact Farmer')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Products section
                  const Text('Products',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Farmer's products
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('products')
                .stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final products = snapshot.data!
                  .where((p) => p['user_id'] == farmer.userId)
                  .map((json) => ProductModel.fromJson(json))
                  .toList();

              if (products.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('No products yet',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.63,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        farmerName: name,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onAddToCart: () {
                          cartProvider.addToCart(product, 1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${product.name} added to cart'),
                              backgroundColor: const Color(0xFF1B6B3A),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}