import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_di_providers.dart';

/// Bottom sheet pour noter le livreur après une livraison.
/// Appelé depuis la page de détails de commande quand status == delivered.
class CourierRatingBottomSheet extends ConsumerStatefulWidget {
  final int orderId;
  final String courierName;

  const CourierRatingBottomSheet({
    super.key,
    required this.orderId,
    required this.courierName,
  });

  /// Affiche le bottom sheet et retourne true si la note a été envoyée.
  static Future<bool?> show(
    BuildContext context, {
    required int orderId,
    required String courierName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CourierRatingBottomSheet(
        orderId: orderId,
        courierName: courierName,
      ),
    );
  }

  @override
  ConsumerState<CourierRatingBottomSheet> createState() =>
      _CourierRatingBottomSheetState();
}

class _CourierRatingBottomSheetState
    extends ConsumerState<CourierRatingBottomSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _positiveTags = [
    'Rapide',
    'Poli',
    'Professionnel',
    'Ponctuel',
  ];

  final List<String> _negativeTags = [
    'En retard',
    'Impoli',
    'Colis abîmé',
    'Non professionnel',
  ];

  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
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
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Évaluez le livreur',
                style: theme.textTheme.titleLarge?.copyWith(
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
                    // Courier info
                    Row(
                      children: [
                        Icon(Icons.delivery_dining,
                            color: colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Livreur',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.courierName,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return InkWell(
                          onTap: () => setState(() => _rating = starValue),
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              starValue <= _rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: starValue <= _rating
                                  ? Colors.amber
                                  : Colors.grey[400],
                              size: 44,
                            ),
                          ),
                        );
                      }),
                    ),

                    if (_rating > 0) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _ratingLabel(_rating),
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...(_rating >= 3 ? _positiveTags : _negativeTags)
                              .map((tag) {
                            final selected = _selectedTags.contains(tag);
                            return FilterChip(
                              label: Text(tag),
                              selected: selected,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedTags.add(tag);
                                  } else {
                                    _selectedTags.remove(tag);
                                  }
                                });
                              },
                              selectedColor:
                                  colorScheme.primary.withValues(alpha: 0.2),
                              checkmarkColor: colorScheme.primary,
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Comment
                      TextField(
                        controller: _commentController,
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
                    onPressed: _rating > 0 && !_isSubmitting
                        ? _submitRating
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
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
      final repo = ref.read(orderRepositoryProvider);

      final result = await repo.rateCourier(
        widget.orderId,
        rating: _rating,
        comment: _commentController.text.isNotEmpty
            ? _commentController.text
            : null,
        tags: _selectedTags.isNotEmpty ? _selectedTags.toList() : null,
      );

      result.fold(
        (failure) {
          if (mounted) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (_) {
          if (mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Merci pour votre évaluation !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'envoyer votre avis. Réessayez.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
