import 'package:flutter/material.dart';
import '../models/farmer_model.dart';
import '../utils/vibrant_theme.dart';

class FarmerCard extends StatelessWidget {
  final FarmerModel farmer;
  final VoidCallback? onTap;
  final VoidCallback? onViewProducts;
  final VoidCallback? onMessage;

  const FarmerCard({
    super.key,
    required this.farmer,
    this.onTap,
    this.onViewProducts,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final name = farmer.user?.name ?? farmer.displayName;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: VibrantTheme.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with Vibrant Background
              Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  gradient: VibrantTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'F',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: VibrantTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (farmer.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: VibrantTheme.primaryGreen, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: VibrantTheme.freshLime),
                        const SizedBox(width: 4),
                        Text(
                          farmer.displayLocation,
                          style: const TextStyle(fontSize: 13, color: VibrantTheme.textGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: i < farmer.rating.round() ? Colors.amber : Colors.grey[300],
                            );
                          }),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          farmer.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VibrantTheme.textDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Buttons (Condensed)
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.storefront_rounded, color: VibrantTheme.primaryGreen),
                    onPressed: onViewProducts,
                    tooltip: 'View Products',
                  ),
                  IconButton(
                    icon: const Icon(Icons.message_rounded, color: VibrantTheme.secondaryGreen),
                    onPressed: onMessage,
                    tooltip: 'Message Farmer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
