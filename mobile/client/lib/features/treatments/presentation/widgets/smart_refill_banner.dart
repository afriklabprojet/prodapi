import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/services/smart_refill_service.dart';
import '../../../orders/presentation/providers/cart_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../../core/services/celebration_service.dart';

/// Bannière Smart Refill pour les rappels de renouvellement proactifs
class SmartRefillBanner extends ConsumerWidget {
  const SmartRefillBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smartRefillProvider);

    if (!state.hasUrgent) return const SizedBox.shrink();

    final urgentSuggestion = state.urgentSuggestions.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _SmartRefillCard(
        suggestion: urgentSuggestion,
        isDark: isDark,
      ),
    );
  }
}

/// Section complète Smart Refill pour la page d'accueil
class SmartRefillSection extends ConsumerStatefulWidget {
  const SmartRefillSection({super.key});

  @override
  ConsumerState<SmartRefillSection> createState() => _SmartRefillSectionState();
}

class _SmartRefillSectionState extends ConsumerState<SmartRefillSection> {
  @override
  void initState() {
    super.initState();
    // Vérifier les refills au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smartRefillProvider.notifier).checkRefills();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartRefillProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading || !state.hasAny) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'À renouveler',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${state.suggestions.length} traitement${state.suggestions.length > 1 ? 's' : ''} à renouveler',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.treatments),
                child: Text(
                  'Tout voir',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: state.suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _SmartRefillCard(
                suggestion: state.suggestions[index],
                isDark: isDark,
                compact: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SmartRefillCard extends ConsumerWidget {
  final RefillSuggestion suggestion;
  final bool isDark;
  final bool compact;

  const _SmartRefillCard({
    required this.suggestion,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatment = suggestion.treatment;
    final isUrgent = suggestion.urgency == RefillUrgency.urgent;

    final cardWidth = compact ? 280.0 : double.infinity;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isUrgent
            ? LinearGradient(
                colors: [
                  Colors.red.shade50,
                  Colors.orange.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUrgent ? null : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? Colors.red.shade200
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          width: isUrgent ? 1.5 : 1,
        ),
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: Colors.red.shade100.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Badge urgence
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUrgent ? Icons.warning_rounded : Icons.schedule_rounded,
                      size: 14,
                      color: isUrgent ? Colors.red.shade700 : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDaysText(suggestion.daysRemaining),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isUrgent ? Colors.red.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Bouton fermer
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(smartRefillProvider.notifier).dismissSuggestion(treatment.id);
                },
                customBorder: const CircleBorder(),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nom du traitement
          Text(
            treatment.productName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          if (treatment.dosage != null) ...[
            const SizedBox(height: 4),
            Text(
              treatment.dosage!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],

          const Spacer(),

          // CTA
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addToCart(context, ref),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Commander'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDaysText(int days) {
    if (days < 0) return 'En retard de ${days.abs()}j';
    if (days == 0) return 'Aujourd\'hui';
    if (days == 1) return 'Demain';
    return 'Dans $days jours';
  }

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();

    final treatment = suggestion.treatment;

    // Charger le produit
    try {
      final productsNotifier = ref.read(productsProvider.notifier);
      final product = await productsNotifier.getProductById(treatment.productId);

      if (product == null) {
        if (context.mounted) {
          AppSnackbar.warning(context, 'Produit non trouvé');
        }
        return;
      }

      // Ajouter au panier
      final quantity = treatment.quantityPerRenewal ?? 1;
      final success = await ref.read(cartProvider.notifier).addItem(
        product,
        quantity: quantity,
      );

      if (success && context.mounted) {
        // Marquer comme commandé
        await ref.read(smartRefillProvider.notifier).markAsOrdered(treatment.id);
        
        // Déclencher la célébration de renouvellement
        ref.read(celebrationProvider.notifier).triggerFirstRenewalCelebration();

        if (!context.mounted) return;
        AppSnackbar.success(
          context,
          '${treatment.productName} ajouté au panier',
          actionLabel: 'Voir panier',
          onAction: () => context.push(AppRoutes.cart),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erreur: ${e.toString()}');
      }
    }
  }
}
