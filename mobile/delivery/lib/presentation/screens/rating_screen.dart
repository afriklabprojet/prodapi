import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/rating.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../core/services/offline_service.dart';
import '../../core/utils/error_utils.dart';
import '../../core/utils/responsive.dart';

/// Écran de notation du client après une livraison réussie
class RatingScreen extends ConsumerStatefulWidget {
  final int deliveryId;
  final String customerName;
  final String? customerAddress;
  final int initialRating;

  const RatingScreen({
    super.key,
    required this.deliveryId,
    required this.customerName,
    this.customerAddress,
    this.initialRating = 0,
  });

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  // Tags prédéfinis utilisant les enums
  List<String> get _positiveTags =>
      PositiveRatingTag.values.map((t) => t.displayLabel).toList();

  List<String> get _negativeTags =>
      NegativeRatingTag.values.map((t) => t.displayLabel).toList();

  final Set<String> _selectedTags = {};

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Veuillez donner une note')));
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      // Créer le modèle Rating
      final rating = Rating(
        deliveryId: widget.deliveryId,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        tags: _selectedTags.toList(),
      );

      final repo = ref.read(deliveryRepositoryProvider);
      await repo.rateCustomer(
        deliveryId: rating.deliveryId,
        rating: rating.rating,
        comment: rating.comment,
        tags: rating.tags,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        // Sauvegarder le rating en offline pour sync ultérieure
        try {
          await OfflineService.instance.addPendingAction(
            type: 'rate_customer',
            deliveryId: widget.deliveryId,
            data: {
              'rating': _rating,
              'comment': _commentController.text.trim().isEmpty
                  ? null
                  : _commentController.text.trim(),
              'tags': _selectedTags.toList(),
            },
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Évaluation sauvegardée, envoi automatique à la reconnexion',
                ),
                backgroundColor: Colors.orange,
              ),
            );
            // Naviguer comme si c'était un succès (sera synchro plus tard)
            _showSuccessDialog();
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(userFriendlyError(e))));
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Merci pour votre avis !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre évaluation aide à améliorer le service.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(
                    context,
                  ).pop(true); // Return true to indicate rating submitted
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _skipRating() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          'Évaluer le client',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          TextButton(onPressed: _skipRating, child: const Text('Passer')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Client info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      widget.customerName.isNotEmpty
                          ? widget.customerName[0].toUpperCase()
                          : 'C',
                      style: TextStyle(
                        fontSize: context.r.sp(32),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.customerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.customerAddress != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.customerAddress!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Rating question
            const Text(
              'Comment était votre expérience\navec ce client ?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 24),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                final isSelected = starNumber <= _rating;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = starNumber);
                    _animationController.forward().then((_) {
                      _animationController.reverse();
                    });
                  },
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final scale = starNumber == _rating
                          ? _scaleAnimation.value
                          : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            isSelected
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 48,
                            color: isSelected
                                ? Colors.amber
                                : Colors.grey.shade400,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // Rating text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _getRatingText(),
                key: ValueKey(_rating),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _getRatingColor(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Tags
            if (_rating > 0) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Qu\'est-ce qui a marqué cette livraison ? (optionnel)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_rating >= 4 ? _positiveTags : _negativeTags).map((
                  tag,
                ) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue,
                    backgroundColor: isDark
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey.shade100,
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Comment field
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire (optionnel)',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Envoyer l\'évaluation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Très mauvais 😞';
      case 2:
        return 'Mauvais 😕';
      case 3:
        return 'Correct 😐';
      case 4:
        return 'Bien 🙂';
      case 5:
        return 'Excellent ! 😄';
      default:
        return 'Touchez pour noter';
    }
  }

  Color _getRatingColor() {
    switch (_rating) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
