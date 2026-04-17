import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../products/presentation/providers/favorites_provider.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../orders/presentation/providers/cart_provider.dart';

/// Section "Mes habituels" affichant les produits favoris
class FavoriteProductsSection extends ConsumerWidget {
  final bool isDark;

  const FavoriteProductsSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final favorites = favoritesState.favoriteProducts;

    // Ne pas afficher la section si pas de favoris
    if (favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec "Voir tout"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mes habituels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.goToFavorites(),
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Liste horizontale des favoris
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length > 6 ? 6 : favorites.length,
            itemBuilder: (context, index) {
              final product = favorites[index];
              return _FavoriteProductCard(
                product: product,
                isDark: isDark,
                onTap: () => context.goToProductDetails(product.id),
                onAddToCart: () {
                  ref.read(cartProvider.notifier).addItem(product);
                  AppSnackbar.success(
                    context,
                    '${product.name} ajouté au panier',
                    actionLabel: 'Voir',
                    onAction: () => context.goToCart(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FavoriteProductCard extends StatelessWidget {
  final ProductEntity product;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _FavoriteProductCard({
    required this.product,
    required this.isDark,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: '',
      decimalDigits: 0,
    );

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 80,
                width: double.infinity,
                child: product.hasImage
                    ? CachedImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(
                          Icons.medication_outlined,
                          size: 32,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
              ),
            ),
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${currencyFormat.format(product.price)} F',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        // Bouton ajout rapide
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: product.isAvailable ? onAddToCart : null,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: product.isAvailable
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.add_shopping_cart,
                                size: 16,
                                color: product.isAvailable
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
