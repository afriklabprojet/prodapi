import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/products_provider.dart';
import '../providers/products_state.dart';
import '../../../orders/presentation/providers/cart_provider.dart';
import '../../../orders/presentation/providers/cart_state.dart';

/// Provider for product quantity selection, auto-disposed per product page
final _quantityProvider = StateProvider.autoDispose.family<int, int>(
  (ref, productId) => 1,
);

class ProductDetailsPage extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_CI',
    symbol: 'F CFA',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Load product details when page opens
    Future.microtask(() {
      ref.read(productsProvider.notifier).loadProductDetails(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final cartState = ref.watch(cartProvider);
    final product = productsState.selectedProduct;
    final quantity = ref.watch(_quantityProvider(widget.productId));

    // Show cart error as snackbar
    if (cartState.status == CartStatus.error &&
        cartState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cartState.errorMessage!),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ref.read(cartProvider.notifier).clearError();
              },
            ),
          ),
        );
        ref.read(cartProvider.notifier).clearError();
      });
    }

    return Scaffold(
      body: productsState.status == ProductsStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : productsState.status == ProductsStatus.error
          ? _buildError(productsState.errorMessage)
          : product == null
          ? _buildError('Produit non trouvé')
          : _buildProductDetails(product),
      floatingActionButton: product != null && product.isAvailable
          ? _buildAddToCartFAB(product, quantity)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final cartState = ref.watch(cartProvider);
              final itemCount = cartState.items.length;

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: badges.Badge(
                  position: badges.BadgePosition.topEnd(top: 0, end: 3),
                  showBadge: itemCount > 0,
                  badgeContent: Text(
                    '$itemCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: IconButton(
                    tooltip: 'Voir le panier',
                    icon: Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                    onPressed: () {
                      context.goToCart();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartFAB(ProductEntity product, int quantity) {
    final cartItem = ref.watch(cartProvider).getItem(product.id);
    final currentQuantity = cartItem?.quantity ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity selector - compact design
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D2D) : Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Minus button
                  Semantics(
                    button: true,
                    label: 'Diminuer la quantité',
                    enabled: quantity > 1,
                    child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: quantity > 1
                          ? () => ref.read(_quantityProvider(widget.productId).notifier).state--
                          : null,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                      child: Container(
                        width: 44,
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.remove,
                          size: 20,
                          color: quantity > 1 
                              ? AppColors.primary 
                              : (isDark ? Colors.grey[600] : Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                  ),
                  // Quantity display
                  Container(
                    width: 36,
                    alignment: Alignment.center,
                    child: Text(
                      '$quantity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Plus button
                  Semantics(
                    button: true,
                    label: 'Augmenter la quantité',
                    enabled: quantity < product.stockQuantity,
                    child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: quantity < product.stockQuantity
                          ? () => ref.read(_quantityProvider(widget.productId).notifier).state++
                          : null,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                      child: Container(
                        width: 44,
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: quantity < product.stockQuantity 
                              ? AppColors.primary 
                              : (isDark ? Colors.grey[600] : Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add to cart button - sleek design
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(cartProvider.notifier)
                        .addItem(product, quantity: quantity);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          currentQuantity > 0
                              ? 'Quantité mise à jour: ${currentQuantity + quantity}'
                              : 'Ajouté au panier',
                        ),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                  label: Text(
                    currentQuantity > 0
                        ? 'Mettre à jour ($currentQuantity)'
                        : 'Ajouter au panier',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildError(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message ?? 'Une erreur s\'est produite',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails(dynamic product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400] : AppColors.textSecondary;
    final cardColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[50];
    
    return CustomScrollView(
      slivers: [
        // App Bar with Image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: product.imageUrl != null
                ? Hero(
                    tag: 'product-image-${product.id}',
                    child: ProductImage(
                      imageUrl: product.imageUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.zero,
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.medication, size: 100, semanticLabel: 'Image du produit non disponible'),
                  ),
          ),
        ),

        // Product Details
        SliverToBoxAdapter(
          child: Container(
            color: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Manufacturer
                  if (product.manufacturer != null)
                    Text(
                      product.manufacturer!,
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Price
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Prix:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(product.price),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock Status
                  _buildInfoRow(
                    'Stock',
                    product.isAvailable
                        ? '${product.stockQuantity} disponible(s)'
                        : 'Rupture de stock',
                    product.isAvailable ? AppColors.success : AppColors.error,
                    isDark,
                  ),
                  const SizedBox(height: 8),

                  // Prescription Required
                  _buildInfoRow(
                    'Ordonnance',
                    product.requiresPrescription ? 'Requise' : 'Non requise',
                    product.requiresPrescription
                        ? AppColors.warning
                        : AppColors.success,
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (product.description != null) ...[
                    Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],

                  // Pharmacy Info
                  const SizedBox(height: 24),
                  Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Pharmacie',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPharmacyCard(product.pharmacy, isDark, cardColor, textColor, secondaryTextColor),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color color, bool isDark) {
    final labelColor = isDark ? Colors.grey[400] : AppColors.textSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: labelColor),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPharmacyCard(
    dynamic pharmacy, 
    bool isDark, 
    Color cardColor, 
    Color textColor, 
    Color? secondaryTextColor,
  ) {
    return Card(
      elevation: isDark ? 0 : 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark 
            ? BorderSide(color: Colors.grey[700]!, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_pharmacy, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pharmacy.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pharmacy.address,
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  pharmacy.phone,
                  style: TextStyle(color: secondaryTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
