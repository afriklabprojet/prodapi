import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_logger.dart';

/// Modèle d'avis vérifié
class ProductReview {
  final int id;
  final String userName;
  final int rating;
  final String? comment;
  final List<String> tags;
  final DateTime createdAt;

  const ProductReview({
    required this.id,
    required this.userName,
    required this.rating,
    this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] as int? ?? 0,
      userName: json['user_name']?.toString() ?? 'Client',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment']?.toString(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
          [],
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// État des avis produit
class ProductReviewsState {
  final List<ProductReview> reviews;
  final bool isLoading;
  final String? error;
  final double? averageRating;
  final int totalCount;

  const ProductReviewsState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
    this.averageRating,
    this.totalCount = 0,
  });
}

/// Provider pour les avis d'un produit
final productReviewsProvider = StateNotifierProvider.autoDispose
    .family<ProductReviewsNotifier, ProductReviewsState, int>((ref, productId) {
      final apiClient = ref.watch(apiClientProvider);
      return ProductReviewsNotifier(apiClient, productId);
    });

class ProductReviewsNotifier extends StateNotifier<ProductReviewsState> {
  final dynamic _apiClient;
  final int _productId;

  ProductReviewsNotifier(this._apiClient, this._productId)
    : super(const ProductReviewsState()) {
    loadReviews();
  }

  Future<void> loadReviews() async {
    state = ProductReviewsState(isLoading: true);

    try {
      final response = await _apiClient.get(
        '/products/$_productId/reviews',
        queryParameters: {'per_page': 10},
      );

      final data = response.data['data'];
      final meta = response.data['meta'] as Map<String, dynamic>? ?? {};

      final reviews =
          (data as List<dynamic>?)
              ?.map((j) => ProductReview.fromJson(j as Map<String, dynamic>))
              .toList() ??
          [];

      state = ProductReviewsState(
        reviews: reviews,
        averageRating: (meta['average_rating'] as num?)?.toDouble(),
        totalCount: meta['total'] as int? ?? reviews.length,
      );
    } catch (e) {
      AppLogger.debug('[ProductReviews] Could not load reviews: $e');
      // Non-blocking: reviews are not critical, show empty state
      state = const ProductReviewsState();
    }
  }
}

/// Section d'avis vérifiés affichée sur la fiche produit
class ProductReviewsSection extends ConsumerWidget {
  final int productId;

  const ProductReviewsSection({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsState = ref.watch(productReviewsProvider(productId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Don't show section while loading or if no reviews exist
    if (reviewsState.isLoading) {
      return const SizedBox.shrink();
    }

    if (reviewsState.reviews.isEmpty) {
      return _buildEmptyReviews(context, isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
        const SizedBox(height: 16),

        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avis vérifiés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${reviewsState.totalCount} avis',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Summary bar
        if (reviewsState.averageRating != null)
          _buildRatingSummary(
            context,
            reviewsState.averageRating!,
            reviewsState.totalCount,
            isDark,
          ),

        const SizedBox(height: 16),

        // Review cards
        ...reviewsState.reviews
            .take(5)
            .map((review) => _buildReviewCard(context, review, isDark)),

        if (reviewsState.totalCount > 5)
          Center(
            child: TextButton(
              onPressed: () {
                // Could navigate to full reviews page in the future
              },
              child: Text(
                'Voir les ${reviewsState.totalCount} avis',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyReviews(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 20,
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Aucun avis pour le moment',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            'Achetez ce produit et soyez le premier à donner votre avis.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSummary(
    BuildContext context,
    double average,
    int count,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.withValues(alpha: 0.08)
            : Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < average.floor()
                        ? Icons.star
                        : (i < average ? Icons.star_half : Icons.star_border),
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(height: 2),
              Text(
                'Basé sur $count avis vérifiés',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    ProductReview review,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + stars + date
            Row(
              children: [
                // Avatar initials
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              review.userName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(review.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[500]
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Tags
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: review.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            // Comment
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.grey[300] : AppColors.textSecondary,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
