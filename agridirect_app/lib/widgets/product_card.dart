import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/vibrant_theme.dart';
import 'skeleton_loader.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final String? farmerName;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.farmerName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: VibrantTheme.cardDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: VibrantTheme.primaryGreen.withValues(alpha: 0.05),
                      ),
                      child: product.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrls.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SkeletonLoader(
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(product.productEmoji, style: const TextStyle(fontSize: 40)),
                              ),
                            )
                          : Center(
                              child: Text(
                                product.productEmoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                    ),
                    // Price Badge
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: VibrantTheme.softShadow,
                        ),
                        child: Text(
                          '${product.price.toStringAsFixed(0)} ETB',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: VibrantTheme.primaryGreen,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // New Badge
                    if (DateTime.now().difference(product.createdAt).inHours < 48)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: VibrantTheme.freshLime,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content Section
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: VibrantTheme.textGrey),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  product.location,
                                  style: const TextStyle(fontSize: 11, color: VibrantTheme.textGrey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'per ${product.unit}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                          if (onAddToCart != null)
                            InkWell(
                              onTap: onAddToCart,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: VibrantTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}