import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/price_comparison_provider.dart';

/// Widget affichant les alternatives de prix dans d'autres pharmacies
class PriceComparisonSection extends ConsumerWidget {
  final int productId;
  final double currentPrice;

  const PriceComparisonSection({
    super.key,
    required this.productId,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(priceComparisonProvider(productId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: 'F',
      decimalDigits: 0,
    );

    // Ne rien afficher si loading ou pas d'alternatives
    if (state.isLoading) {
      return const SizedBox.shrink();
    }

    if (!state.hasAlternatives) {
      return const SizedBox.shrink();
    }

    final bestPrice = state.bestPrice;
    final savings = currentPrice - (bestPrice?.price ?? currentPrice);
    final hasSavings = savings > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E3A2F) 
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? AppColors.primary.withValues(alpha: 0.3) 
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aussi disponible ailleurs',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (hasSavings)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Économisez ${currencyFormat.format(savings)}',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Liste des alternatives
          ...state.alternatives.take(3).map((alt) => _buildAlternativeItem(
            context,
            alt,
            currencyFormat,
            isDark,
            alt.price < currentPrice,
          )),

          // Bouton voir plus si plus de 3 alternatives
          if (state.alternatives.length > 3)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    _showAllAlternatives(context, state.alternatives, currencyFormat);
                  },
                  child: Text(
                    'Voir ${state.alternatives.length - 3} autre${state.alternatives.length > 4 ? 's' : ''}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlternativeItem(
    BuildContext context,
    PriceAlternative alt,
    NumberFormat currencyFormat,
    bool isDark,
    bool isCheaper,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        // Naviguer vers le produit alternatif
        context.push('/products/${alt.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Icône pharmacie
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_pharmacy,
                size: 18,
                color: isCheaper ? AppColors.success : AppColors.textHint,
              ),
            ),
            const SizedBox(width: 10),
            
            // Infos pharmacie
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alt.pharmacyName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (alt.pharmacyAddress != null)
                    Text(
                      alt.pharmacyAddress!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            
            // Prix
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCheaper)
                      Icon(
                        Icons.arrow_downward,
                        size: 12,
                        color: AppColors.success,
                      ),
                    Text(
                      currencyFormat.format(alt.price),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isCheaper ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (alt.hasPromo && alt.originalPrice != null)
                  Text(
                    currencyFormat.format(alt.originalPrice),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  void _showAllAlternatives(
    BuildContext context,
    List<PriceAlternative> alternatives,
    NumberFormat currencyFormat,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Poignée
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Titre
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Disponible dans ${alternatives.length} pharmacies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            
            // Liste
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: alternatives.length,
                itemBuilder: (context, index) {
                  final alt = alternatives[index];
                  return _buildAlternativeItem(
                    context,
                    alt,
                    currencyFormat,
                    isDark,
                    alt.price < currentPrice,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
