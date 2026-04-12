import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import '../../../../config/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../orders/presentation/providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../providers/products_state.dart';

enum ProductSort { none, priceLow, priceHigh, rating }

/// Page affichant tous les produits de toutes les pharmacies
class AllProductsPage extends ConsumerStatefulWidget {
  final String? initialQuery;

  const AllProductsPage({super.key, this.initialQuery});

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
  ProductSort _currentSort = ProductSort.none;
  bool _filterInStock = false;
  bool _filterPromo = false;

  // Catégories basées sur les IDs de l'API
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tous', 'icon': Icons.grid_view, 'id': null},
    {'name': 'Antidouleurs', 'icon': Icons.healing, 'id': '1'},
    {'name': 'Antibiotiques', 'icon': Icons.medical_services, 'id': '2'},
    {'name': 'Premiers Soins', 'icon': Icons.emergency, 'id': '3'},
    {'name': 'Soins & Beauté', 'icon': Icons.face, 'id': '4'},
    {'name': 'Dermatologie', 'icon': Icons.water_drop, 'id': '16'},
    {'name': 'Digestif', 'icon': Icons.medication_liquid, 'id': '17'},
    {'name': 'Antiseptiques', 'icon': Icons.sanitizer, 'id': '44'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Pré-remplir la recherche si un query initial est fourni
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    // Charger les produits au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.length >= 2) {
        ref
            .read(productsProvider.notifier)
            .searchProducts(widget.initialQuery!);
      } else {
        ref.read(productsProvider.notifier).loadProducts(refresh: true);
      }
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
        ref
            .read(productsProvider.notifier)
            .filterByCategory(_selectedCategory!);
      } else {
        ref.read(productsProvider.notifier).loadProducts(refresh: true);
      }
    } else if (query.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        ref.read(searchHistoryServiceProvider).addSearch(query);
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

  List<dynamic> _applyLocalFilters(List<dynamic> products) {
    var list = products.toList();
    if (_filterInStock)
      list = list
          .where((p) => p.isAvailable == true && p.isOutOfStock != true)
          .toList();
    if (_filterPromo) list = list.where((p) => p.hasDiscount == true).toList();
    switch (_currentSort) {
      case ProductSort.priceLow:
        list.sort(
          (a, b) => ((a.finalPrice ?? a.price ?? 0) as num).compareTo(
            (b.finalPrice ?? b.price ?? 0) as num,
          ),
        );
      case ProductSort.priceHigh:
        list.sort(
          (a, b) => ((b.finalPrice ?? b.price ?? 0) as num).compareTo(
            (a.finalPrice ?? a.price ?? 0) as num,
          ),
        );
      case ProductSort.rating:
        list.sort(
          (a, b) => ((b.averageRating ?? 0) as num).compareTo(
            (a.averageRating ?? 0) as num,
          ),
        );
      case ProductSort.none:
        break;
    }
    return list;
  }

  bool get _hasActiveFilters =>
      _filterInStock || _filterPromo || _currentSort != ProductSort.none;

  void _showFilterSheet(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trier & Filtrer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {});
                      setState(() {
                        _currentSort = ProductSort.none;
                        _filterInStock = false;
                        _filterPromo = false;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Réinitialiser',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Trier par',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SortChip(
                    label: 'Par défaut',
                    icon: Icons.sort,
                    value: ProductSort.none,
                    current: _currentSort,
                    isDark: isDark,
                    onTap: () => setModalState(
                      () => setState(() => _currentSort = ProductSort.none),
                    ),
                  ),
                  _SortChip(
                    label: 'Prix ↑',
                    icon: Icons.arrow_upward,
                    value: ProductSort.priceLow,
                    current: _currentSort,
                    isDark: isDark,
                    onTap: () => setModalState(
                      () => setState(() => _currentSort = ProductSort.priceLow),
                    ),
                  ),
                  _SortChip(
                    label: 'Prix ↓',
                    icon: Icons.arrow_downward,
                    value: ProductSort.priceHigh,
                    current: _currentSort,
                    isDark: isDark,
                    onTap: () => setModalState(
                      () =>
                          setState(() => _currentSort = ProductSort.priceHigh),
                    ),
                  ),
                  _SortChip(
                    label: 'Mieux notés',
                    icon: Icons.star_rounded,
                    value: ProductSort.rating,
                    current: _currentSort,
                    isDark: isDark,
                    onTap: () => setModalState(
                      () => setState(() => _currentSort = ProductSort.rating),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Filtres',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _filterInStock,
                onChanged: (v) =>
                    setModalState(() => setState(() => _filterInStock = v)),
                title: Text(
                  'En stock uniquement',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _filterPromo,
                onChanged: (v) =>
                    setModalState(() => setState(() => _filterPromo = v)),
                title: Text(
                  'En promotion',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Appliquer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 5, end: 5),
            showBadge: cartState.itemCount > 0,
            badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.primary),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
            child: Column(
              children: [
                TextField(
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (v) {
                    setState(() {});
                    _onSearch(v);
                  },
                ),
                const SizedBox(height: 8),
                // Sort & Filter toolbar
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSortChipSmall(
                              'Prix ↑',
                              ProductSort.priceLow,
                              isDark,
                            ),
                            const SizedBox(width: 6),
                            _buildSortChipSmall(
                              'Prix ↓',
                              ProductSort.priceHigh,
                              isDark,
                            ),
                            const SizedBox(width: 6),
                            _buildSortChipSmall(
                              'Mieux notés',
                              ProductSort.rating,
                              isDark,
                            ),
                            const SizedBox(width: 6),
                            if (_filterInStock)
                              _buildActiveFilterChip(
                                'En stock',
                                isDark,
                                () => setState(() => _filterInStock = false),
                              ),
                            if (_filterPromo)
                              _buildActiveFilterChip(
                                'Promo',
                                isDark,
                                () => setState(() => _filterPromo = false),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showFilterSheet(context, isDark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _hasActiveFilters
                              ? AppColors.primary
                              : (isDark ? Colors.white10 : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: _hasActiveFilters
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black54),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Filtres',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _hasActiveFilters
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    onSelected: (_) =>
                        _onCategorySelected(category['id'] as String?),
                  ),
                );
              },
            ),
          ),

          // Products Grid
          Expanded(child: _buildProductsContent(state, isDark)),
        ],
      ),
    );
  }

  Widget _buildSortChipSmall(String label, ProductSort value, bool isDark) {
    final isActive = _currentSort == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentSort = isActive ? ProductSort.none : value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark ? Colors.white10 : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(
    String label,
    bool isDark,
    VoidCallback onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
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
        onAction: () =>
            ref.read(productsProvider.notifier).loadProducts(refresh: true),
      );
    }

    final displayProducts = _applyLocalFilters(state.products);

    if (displayProducts.isEmpty) {
      return EmptyState(
        icon: Icons.medication_outlined,
        title: 'Aucun produit',
        message: _hasActiveFilters
            ? 'Aucun produit ne correspond aux filtres actifs'
            : _searchController.text.isNotEmpty
            ? 'Aucun résultat pour "${_searchController.text}"'
            : 'Aucun produit disponible pour le moment',
        actionLabel: _hasActiveFilters || _searchController.text.isNotEmpty
            ? 'Réinitialiser'
            : null,
        onAction: (_hasActiveFilters || _searchController.text.isNotEmpty)
            ? () {
                setState(() {
                  _currentSort = ProductSort.none;
                  _filterInStock = false;
                  _filterPromo = false;
                });
                if (_searchController.text.isNotEmpty) {
                  _searchController.clear();
                  _onSearch('');
                }
              }
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(productsProvider.notifier).loadProducts(refresh: true),
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
            onTap: () => context.goToProductDetails(product.id),
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

  Widget _SortChip({
    required String label,
    required IconData icon,
    required ProductSort value,
    required ProductSort current,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = value == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: product.isOutOfStock
                                ? Colors.red
                                : Colors.orange,
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
                    // Discount badge
                    if (product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${product.discountPercentage}%',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                    // Rating stars
                    if (product.hasRating)
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final rating = product.averageRating!;
                            return Icon(
                              i < rating.floor()
                                  ? Icons.star
                                  : (i < rating
                                        ? Icons.star_half
                                        : Icons.star_border),
                              color: Colors.amber,
                              size: 12,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '(${product.reviewsCount ?? 0})',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    // Price with discount
                    if (product.hasDiscount) ...[
                      Text(
                        currencyFormat.format(product.price),
                        style: TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        currencyFormat.format(product.finalPrice),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ] else
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
