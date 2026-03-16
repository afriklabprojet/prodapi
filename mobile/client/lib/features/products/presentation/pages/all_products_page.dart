import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../orders/presentation/providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../providers/products_state.dart';
import 'product_details_page.dart';

/// Page affichant tous les produits de toutes les pharmacies
class AllProductsPage extends ConsumerStatefulWidget {
  const AllProductsPage({super.key});

  @override
  ConsumerState<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends ConsumerState<AllProductsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  String? _selectedCategory;
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tous', 'icon': Icons.grid_view, 'id': null},
    {'name': 'Antidouleurs', 'icon': Icons.healing, 'id': 'pain-relief'},
    {'name': 'Antibiotiques', 'icon': Icons.medical_services, 'id': 'antibiotics'},
    {'name': 'Vitamines', 'icon': Icons.water_drop, 'id': 'vitamins'},
    {'name': 'Premiers Soins', 'icon': Icons.emergency, 'id': 'first-aid'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Charger les produits au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).loadProducts(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      if (_selectedCategory != null) {
        ref.read(productsProvider.notifier).filterByCategory(_selectedCategory!);
      } else {
        ref.read(productsProvider.notifier).loadProducts(refresh: true);
      }
    } else if (query.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        ref.read(productsProvider.notifier).searchProducts(query);
      });
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() => _selectedCategory = categoryId);
    _searchController.clear();
    
    if (categoryId == null) {
      ref.read(productsProvider.notifier).loadProducts(refresh: true);
    } else {
      ref.read(productsProvider.notifier).filterByCategory(categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);
    final cartState = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Tous les Médicaments',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        actions: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 5, end: 5),
            showBadge: cartState.itemCount > 0,
            badgeStyle: const badges.BadgeStyle(
              badgeColor: AppColors.primary,
            ),
            badgeContent: Text(
              '${cartState.itemCount}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: IconButton(
              icon: Icon(
                Icons.shopping_cart_outlined,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () => context.goToCart(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un médicament...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _onSearch,
            ),
          ),

          // Categories
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(category['name'] as String),
                      ],
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark ? Colors.white10 : Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    ),
                    onSelected: (_) => _onCategorySelected(category['id'] as String?),
                  ),
                );
              },
            ),
          ),

          // Products Grid
          Expanded(
            child: _buildProductsContent(state, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsContent(ProductsState state, bool isDark) {
    if (state.status == ProductsStatus.loading && state.products.isEmpty) {
      return _buildLoadingGrid();
    }

    if (state.errorMessage != null && state.products.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Erreur',
        message: state.errorMessage!,
        actionLabel: 'Réessayer',
        onAction: () => ref.read(productsProvider.notifier).loadProducts(refresh: true),
      );
    }

    if (state.products.isEmpty) {
      return EmptyState(
        icon: Icons.medication_outlined,
        title: 'Aucun produit',
        message: _searchController.text.isNotEmpty
            ? 'Aucun résultat pour "${_searchController.text}"'
            : 'Aucun produit disponible pour le moment',
        actionLabel: _searchController.text.isNotEmpty ? 'Effacer la recherche' : null,
        onAction: _searchController.text.isNotEmpty
            ? () {
                _searchController.clear();
                _onSearch('');
              }
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productsProvider.notifier).loadProducts(refresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.products.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.products.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = state.products[index];
          return _ProductCard(
            product: product,
            currencyFormat: _currencyFormat,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailsPage(productId: product.id),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final NumberFormat currencyFormat;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.currencyFormat,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedImage(
                      imageUrl: product.imageUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        child: Icon(
                          Icons.medication,
                          size: 50,
                          color: isDark ? Colors.white30 : Colors.grey[300],
                        ),
                      ),
                    ),
                    // Stock indicator
                    if (product.isLowStock || product.isOutOfStock)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.isOutOfStock ? Colors.red : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.isOutOfStock ? 'Rupture' : 'Stock faible',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Pharmacy badge
                    Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            product.pharmacy.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name ?? 'Produit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(product.price ?? 0),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
