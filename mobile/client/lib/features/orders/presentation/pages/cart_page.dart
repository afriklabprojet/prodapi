import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/cart_provider.dart';
import '../providers/cart_state.dart';
import '../utils/cart_ui_guards.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  /// Supprime un article du panier avec possibilité d'annuler
  void _removeItemWithUndo({
    required BuildContext context,
    required WidgetRef ref,
    required int productId,
  }) {
    // Récupérer l'article avant suppression
    final cartState = ref.read(cartProvider);
    final item = cartState.getItem(productId);
    if (item == null) return;

    final product = item.product;
    final quantity = item.quantity;

    // Supprimer l'article
    ref.read(cartProvider.notifier).removeItem(productId);

    // Afficher le snackbar avec option "Annuler"
    AppSnackbar.undo(
      context,
      message: '${product.name} retiré du panier',
      onUndo: () {
        // Restaurer l'article avec la même quantité
        ref.read(cartProvider.notifier).addItem(product, quantity: quantity);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: 'F CFA',
      decimalDigits: 0,
    );

    // Listen for error changes and show snackbar automatically
    ref.listen<CartState>(cartProvider, (previous, next) {
      if (next.errorMessage != null &&
          (previous?.errorMessage != next.errorMessage)) {
        AppSnackbar.error(context, next.errorMessage!);
        // Auto-clear error after showing
        Future.delayed(const Duration(seconds: 3), () {
          ref.read(cartProvider.notifier).clearError();
        });
      }
    });

    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mon Panier'),
          backgroundColor: AppColors.primary,
          actions: [
            if (cartState.isNotEmpty)
              IconButton(
                onPressed: () => _showClearCartDialog(context, ref),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Vider le panier',
              ),
          ],
        ),
        body: cartState.isEmpty
            ? _buildEmptyCart(context)
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartState.items.length,
                      itemBuilder: (context, index) {
                        final item = cartState.items[index];
                        return _buildCartItem(
                          context,
                          ref,
                          item,
                          currencyFormat,
                        );
                      },
                    ),
                  ),
                  _buildCartSummary(context, ref, cartState, currencyFormat),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: isDark ? Colors.grey[600] : Colors.grey[300],
            semanticLabel: 'Panier vide',
          ),
          const SizedBox(height: 16),
          const Text(
            'Votre panier est vide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des produits pour commencer',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.products),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Voir les produits'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    item,
    NumberFormat currencyFormat,
  ) {
    final product = item.product;
    final isAvailable = item.isAvailable;

    return Semantics(
      container: true,
      label:
          '${product.name}, quantité ${item.quantity}, ${currencyFormat.format(product.price * item.quantity)}${!isAvailable ? ", stock insuffisant" : ""}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ExcludeSemantics(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.medication,
                              size: 40,
                              semanticLabel: 'Image non disponible',
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.medication,
                          size: 40,
                          semanticLabel: 'Image non disponible',
                        ),
                ),
              ), // ExcludeSemantics
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.pharmacy.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Stock insuffisant',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Text(
                          currencyFormat.format(product.price),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        // Quantity Controls
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF3C3C3C)
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Semantics(
                                button: true,
                                label: item.quantity > 1
                                    ? 'Diminuer la quantité'
                                    : 'Supprimer du panier',
                                child: DebouncedIconButton(
                                  tooltip: item.quantity > 1
                                      ? 'Diminuer la quantité'
                                      : 'Supprimer du panier',
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                            product.id,
                                            item.quantity - 1,
                                          );
                                    } else {
                                      _removeItemWithUndo(
                                        context: context,
                                        ref: ref,
                                        productId: product.id,
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    item.quantity > 1
                                        ? Icons.remove
                                        : Icons.delete_outline,
                                    size: 20,
                                    semanticLabel: item.quantity > 1
                                        ? 'Diminuer'
                                        : 'Supprimer',
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                              Semantics(
                                label: 'Quantité: ${item.quantity}',
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: 'Augmenter la quantité',
                                enabled:
                                    isAvailable &&
                                    item.quantity < product.stockQuantity,
                                child: DebouncedIconButton(
                                  tooltip: 'Augmenter la quantité',
                                  onPressed:
                                      isAvailable &&
                                          item.quantity < product.stockQuantity
                                      ? () {
                                          ref
                                              .read(cartProvider.notifier)
                                              .updateQuantity(
                                                product.id,
                                                item.quantity + 1,
                                              );
                                        }
                                      : null,
                                  icon: const Icon(
                                    Icons.add,
                                    size: 20,
                                    semanticLabel: 'Augmenter',
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ), // Semantics
    );
  }

  Widget _buildCartSummary(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
    NumberFormat currencyFormat,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sous-total',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  currencyFormat.format(cartState.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frais de livraison',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  currencyFormat.format(cartState.deliveryFee),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(cartState.total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Builder(
                builder: (context) {
                  final hasUnavailable = cartState.items.any((item) => !item.isAvailable);
                  return Column(
                    children: [
                      if (hasUnavailable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Certains articles sont en rupture de stock. Retirez-les pour continuer.',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: hasUnavailable ? null : () => context.pushToCheckout(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Passer la commande',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer tous les articles du panier ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }
}
