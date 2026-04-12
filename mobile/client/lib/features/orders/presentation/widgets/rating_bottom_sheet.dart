import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';

/// Bottom sheet for rating an order (courier + pharmacy).
/// Call [RatingBottomSheet.show] after an order is delivered.
class RatingBottomSheet extends ConsumerStatefulWidget {
  final int orderId;
  final String pharmacyName;
  final String? courierName;

  const RatingBottomSheet({
    super.key,
    required this.orderId,
    required this.pharmacyName,
    this.courierName,
  });

  /// Show the rating bottom sheet and return true if submitted.
  static Future<bool?> show(
    BuildContext context, {
    required int orderId,
    required String pharmacyName,
    String? courierName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RatingBottomSheet(
        orderId: orderId,
        pharmacyName: pharmacyName,
        courierName: courierName,
      ),
    );
  }

  @override
  ConsumerState<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends ConsumerState<RatingBottomSheet> {
  int _courierRating = 0;
  int _pharmacyRating = 0;
  final _courierCommentController = TextEditingController();
  final _pharmacyCommentController = TextEditingController();

  final List<String> _courierPositiveTags = [
    'Rapide',
    'Poli',
    'Professionnel',
    'Ponctuel',
  ];

  final List<String> _courierNegativeTags = [
    'En retard',
    'Impoli',
    'Colis abîmé',
  ];

  final List<String> _pharmacyPositiveTags = [
    'Bon emballage',
    'Produits conformes',
    'Service rapide',
  ];

  final List<String> _pharmacyNegativeTags = [
    'Produit manquant',
    'Emballage insuffisant',
    'Attente longue',
  ];

  final Set<String> _selectedCourierTags = {};
  final Set<String> _selectedPharmacyTags = {};

  bool _isSubmitting = false;

  @override
  void dispose() {
    _courierCommentController.dispose();
    _pharmacyCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Évaluez votre commande',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Divider(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Courier rating
                    if (widget.courierName != null) ...[
                      _buildRatingSection(
                        title: 'Livreur',
                        subtitle: widget.courierName!,
                        icon: Icons.delivery_dining,
                        rating: _courierRating,
                        onRatingChanged: (r) =>
                            setState(() => _courierRating = r),
                        positiveTags: _courierPositiveTags,
                        negativeTags: _courierNegativeTags,
                        selectedTags: _selectedCourierTags,
                        commentController: _courierCommentController,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],

                    // Pharmacy rating
                    _buildRatingSection(
                      title: 'Pharmacie',
                      subtitle: widget.pharmacyName,
                      icon: Icons.local_pharmacy,
                      rating: _pharmacyRating,
                      onRatingChanged: (r) =>
                          setState(() => _pharmacyRating = r),
                      positiveTags: _pharmacyPositiveTags,
                      negativeTags: _pharmacyNegativeTags,
                      selectedTags: _selectedPharmacyTags,
                      commentController: _pharmacyCommentController,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Submit button
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submitRating : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Envoyer mon avis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit =>
      !_isSubmitting && (_courierRating > 0 || _pharmacyRating > 0);

  Widget _buildRatingSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required int rating,
    required ValueChanged<int> onRatingChanged,
    required List<String> positiveTags,
    required List<String> negativeTags,
    required Set<String> selectedTags,
    required TextEditingController commentController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () => onRatingChanged(starValue),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  starValue <= rating ? Icons.star : Icons.star_border,
                  color: starValue <= rating
                      ? Colors.amber
                      : Colors.grey[400],
                  size: 40,
                ),
              ),
            );
          }),
        ),
        if (rating > 0) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _ratingLabel(rating),
                style: TextStyle(
                  color: context.secondaryText,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Tags
        if (rating > 0)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...(rating >= 3 ? positiveTags : negativeTags).map((tag) {
                final selected = selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }),
            ],
          ),
        const SizedBox(height: 12),

        // Comment
        if (rating > 0)
          TextField(
            controller: commentController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Ajouter un commentaire (optionnel)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
      ],
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Très mauvais';
      case 2:
        return 'Mauvais';
      case 3:
        return 'Correct';
      case 4:
        return 'Bien';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final body = <String, dynamic>{};

      if (_courierRating > 0) {
        body['courier_rating'] = _courierRating;
        body['courier_comment'] = _courierCommentController.text.isNotEmpty
            ? _courierCommentController.text
            : null;
        body['courier_tags'] = _selectedCourierTags.toList();
      }

      if (_pharmacyRating > 0) {
        body['pharmacy_rating'] = _pharmacyRating;
        body['pharmacy_comment'] = _pharmacyCommentController.text.isNotEmpty
            ? _pharmacyCommentController.text
            : null;
        body['pharmacy_tags'] = _selectedPharmacyTags.toList();
      }

      await apiClient.post(
        ApiConstants.rateOrder(widget.orderId),
        data: body,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Merci pour votre avis !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'envoyer votre avis. Réessayez.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
