import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../orders/presentation/providers/cart_provider.dart';
import '../providers/frequent_products_provider.dart';

/// Page listant tous les produits fréquemment achetés par l'utilisateur
class FrequentProductsListPage extends ConsumerWidget {
  const FrequentProductsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(frequentProductsProvider);

    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: 'F CFA',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackgroundDeep
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackgroundDeep : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Vos habituels',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      body: _buildBody(context, ref, state, isDark, currencyFormat),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    FrequentProductsState state,
    bool isDark,
    NumberFormat currencyFormat,
  ) {
    if (state.isLoading) {
      return _buildLoadingGrid(isDark);
    }

    if (state.error != null) {
      return _buildErrorState(context, ref, state.error!, isDark);
    }

    if (state.products.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final fp = state.products[index];
        return _FrequentProductGridCard(
          frequentProduct: fp,
          isDark: isDark,
          currencyFormat: currencyFormat,
        );
      },
    );
  }

  Widget _buildLoadingGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.replay_rounded,
              size: 72,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun habituel pour l\'instant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Les produits que vous achetez régulièrement apparaîtront ici.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String error,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(frequentProductsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte grille d'un produit habituel
// ─────────────────────────────────────────────────────────────────────────────

class _FrequentProductGridCard extends ConsumerWidget {
  final FrequentProduct frequentProduct;
  final bool isDark;
  final NumberFormat currencyFormat;

  const _FrequentProductGridCard({
    required this.frequentProduct,
    required this.isDark,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = frequentProduct.product;

    return Material(
      color: isDark ? const Color(0xFF252540) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/products/${product.id}');
        },
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image du produit
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: product.imageUrl != null
                          ? CachedImage(
                              imageUrl: product.imageUrl!,
                              width: 72,
                              height: 72,
                              borderRadius: BorderRadius.circular(12),
                            )
                          : Icon(
                              Icons.medication_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Badge "Xème achat"
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 11,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${frequentProduct.purchaseCount}x',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Nom du produit
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),

                  // Prix
                  Text(
                    currencyFormat.format(product.price),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 28), // espace pour le bouton panier
                ],
              ),
            ),

            // Bouton ajouter au panier
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _addToCart(context, ref),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
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

  void _addToCart(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    final success = await ref
        .read(cartProvider.notifier)
        .addItem(frequentProduct.product, quantity: 1);

    if (success && context.mounted) {
      AppSnackbar.success(
        context,
        '${frequentProduct.product.name} ajouté au panier',
        actionLabel: 'Voir',
        onAction: () => context.push(AppRoutes.cart),
      );
    }
  }
}
