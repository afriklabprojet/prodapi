import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../orders/presentation/providers/cart_provider.dart';
import '../../../products/presentation/providers/frequent_products_provider.dart';

/// Section "Vos habituels" - Produits fréquemment achetés sur la home page
class FrequentProductsSection extends ConsumerWidget {
  final bool isDark;

  const FrequentProductsSection({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(frequentProductsProvider);
    final topProducts = ref.watch(topFrequentProductsProvider);

    // Ne pas afficher si pas de produits fréquents
    if (topProducts.isEmpty && !state.isLoading) {
      return const SizedBox.shrink();
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: 'F CFA',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.replay_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vos habituels',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              if (topProducts.length >= 6)
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.push(AppRoutes.frequentProducts);
                  },
                  child: const Text('Voir tout'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Loading state
        if (state.isLoading)
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) => _buildSkeletonCard(isDark),
            ),
          )
        else
          // Products list
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: topProducts.length,
              itemBuilder: (context, index) {
                final frequentProduct = topProducts[index];
                return _FrequentProductCard(
                  frequentProduct: frequentProduct,
                  isDark: isDark,
                  currencyFormat: currencyFormat,
                );
              },
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSkeletonCard(bool isDark) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _FrequentProductCard extends ConsumerWidget {
  final FrequentProduct frequentProduct;
  final bool isDark;
  final NumberFormat currencyFormat;

  const _FrequentProductCard({
    required this.frequentProduct,
    required this.isDark,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = frequentProduct.product;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: () => context.push('/products/${product.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image du produit
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: product.imageUrl != null
                            ? CachedImage(
                                imageUrl: product.imageUrl!,
                                width: 60,
                                height: 60,
                                  borderRadius: BorderRadius.circular(10),
                              )
                            : Icon(
                                Icons.medication_rounded,
                                color: AppColors.primary,
                                size: 32,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Nom du produit
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12,
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Nombre d'achats
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${frequentProduct.purchaseCount}x achetés',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bouton ajouter au panier
              Positioned(
                right: 4,
                bottom: 4,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _addToCart(context, ref),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    
    final success = await ref.read(cartProvider.notifier).addItem(
      frequentProduct.product,
      quantity: 1,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${frequentProduct.product.name} ajouté au panier'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () => context.push(AppRoutes.cart),
          ),
        ),
      );
    }
  }
}
