import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../models/farmer_model.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewsScreen extends StatefulWidget {
  final FarmerModel farmer;
  const ReviewsScreen({super.key, required this.farmer});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final service = ReviewService();
    final reviews = await service.getReviewsForFarmer(widget.farmer.id);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text('Reviews for ${widget.farmer.displayName}'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? _buildEmptyState()
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStatsHeader()),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildReviewCard(_reviews[index]),
                        childCount: _reviews.length,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in _reviews) {
      final key = r.rating.round();
      if (counts.containsKey(key)) {
        counts[key] = counts[key]! + 1;
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  widget.farmer.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                RatingBarIndicator(
                  rating: widget.farmer.rating,
                  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 18.0,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_reviews.length} reviews',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [5, 4, 3, 2, 1].map((stars) {
                  final count = counts[stars]!;
                  final ratio = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Text('$stars', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1B6B3A),
                      child: Text(
                        (review.buyerName?.isNotEmpty ?? false) ? review.buyerName![0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      review.buyerName ?? 'Anonymous Buyer',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(review.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                RatingBarIndicator(
                  rating: review.rating,
                  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 16.0,
                ),
                const SizedBox(width: 8),
                if (review.orderId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified, size: 12, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Purchase',
                          style: TextStyle(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
