import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import 'chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
        actions: [
          // If the current user is the owner, show delete/edit options
          if (context.read<AuthProvider>().currentUserId == product.userId)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Product'),
                      content: const Text('Are you sure you want to remove this product from the marketplace?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    try {
                      await ProductService().deleteProduct(product.id);
                      if (mounted) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Product', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image/emoji area
            Container(
              height: 250,
              width: double.infinity,
              color: const Color(0xFF1B6B3A).withValues(alpha: 0.1),
              child: product.imageUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: product.imageUrls.length,
                      itemBuilder: (context, index) {
                        return InteractiveViewer(
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrls[index],
                            fit: BoxFit.contain,
                            errorWidget: (context, url, err) => Center(
                              child: Text(product.productEmoji, style: const TextStyle(fontSize: 100)),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        product.productEmoji,
                        style: const TextStyle(fontSize: 100),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + organic badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (product.isOrganic)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🌿 ', style: TextStyle(fontSize: 12)),
                              Text('Organic',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price + Comparison info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ETB ${product.price.toStringAsFixed(0)} / ${product.unit}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B6B3A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Search for similar products
                          Navigator.pop(context);
                          // This would ideally set the search query in the provider
                        },
                        child: Text(
                          '${product.category} from ETB ${(product.price * 0.9).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bulk Pricing Incentive
                  if (product.bulkPrice != null && product.bulkMinQuantity != null)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bulk Savings: Buy ${product.bulkMinQuantity!.toStringAsFixed(0)}+ ${product.unit} at ETB ${product.bulkPrice!.toStringAsFixed(0)}/${product.unit}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        product.location,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      product.description!,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[700], height: 1.5),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Product details card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _detailRow('Category', '${product.categoryEmoji} ${product.category}'),
                          const Divider(),
                          _detailRow('Available',
                              '${product.quantity.toStringAsFixed(0)} ${product.unit}'),
                          const Divider(),
                          _detailRow('Min. Order',
                              '${product.minOrder.toStringAsFixed(0)} ${product.unit}'),
                          if (product.harvestDate != null) ...[
                            const Divider(),
                            _detailRow('Harvest Date',
                                timeago.format(product.harvestDate!)),
                          ],
                          const Divider(),
                          _detailRow('Posted',
                              timeago.format(product.createdAt)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Delivery options
                  Wrap(
                    spacing: 8,
                    children: [
                      if (product.deliveryAvailable)
                        _badge('🚚 Delivery', Colors.blue),
                      if (product.pickupAvailable)
                        _badge('📦 Pickup', Colors.orange),
                      if (product.bulkAvailable)
                        _badge('📊 Bulk', Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quantity selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 32,
                        color: const Color(0xFF1B6B3A),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        color: const Color(0xFF1B6B3A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Message farmer button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: product.userId,
                              otherUserName: 'Farmer',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Message Farmer',
                          style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B6B3A),
                        side: const BorderSide(color: Color(0xFF1B6B3A)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                cartProvider.addToCart(product, _quantity);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} x$_quantity added to cart'),
                    backgroundColor: const Color(0xFF1B6B3A),
                  ),
                );
              },
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: Text(
                'Add to Cart  ·  ETB ${(product.price * _quantity).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B6B3A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
