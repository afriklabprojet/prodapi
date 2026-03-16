import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../orders/presentation/providers/cart_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../widgets/category_chip.dart';
import '../providers/products_provider.dart';
import '../providers/products_state.dart';
import 'product_details_page.dart';

// Provider ID pour cette page
const _selectedCategoryId = 'products_list_selected_category';

class ProductsListPage extends ConsumerStatefulWidget {
  const ProductsListPage({super.key});

  @override
  ConsumerState<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends ConsumerState<ProductsListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tous', 'icon': Icons.grid_view, 'id': null},
    {'name': 'Antidouleurs', 'icon': Icons.healing, 'id': 'pain-relief'},
    {
      'name': 'Antibiotiques',
      'icon': Icons.medical_services,
      'id': 'antibiotics',
    },
    {'name': 'Vitamines', 'icon': Icons.water_drop, 'id': 'vitamins'},
    {'name': 'Premiers Soins', 'icon': Icons.emergency, 'id': 'first-aid'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    final selectedCategory = ref.read(formFieldsProvider(_selectedCategoryId))['category'];
    if (query.isEmpty) {
      if (selectedCategory != null) {
        ref
            .read(productsProvider.notifier)
            .filterByCategory(selectedCategory);
      } else {
        ref.read(productsProvider.notifier).loadProducts(refresh: true);
      }
    } else if (query.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        ref.read(productsProvider.notifier).searchProducts(query);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Cart Icon
          Consumer(
            builder: (context, ref, child) {
              final cartState = ref.watch(cartProvider);
              final itemCount = cartState.items.length;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: badges.Badge(
                  position: badges.BadgePosition.topEnd(top: 0, end: 3),
                  showBadge: itemCount > 0,
                  badgeContent: Text(
                    '$itemCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'Panier',
                    onPressed: () => context.goToCart(),
                  ),
                ),
              );
            },
          ),
          // Prescription button
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Upload ordonnance',
            onPressed: () => context.goToPrescriptionUpload(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher des médicaments...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Prescription Banner
          _buildPrescriptionBanner(),

          // Categories
          _buildCategoriesSection(),

          // Products List
          Expanded(child: _buildProductsList(productsState)),
        ],
      ),
    );
  }

  Widget _buildProductsList(ProductsState state) {
    if (state.status == ProductsStatus.loading) {
      return const ProductsListSkeleton();
    }

    if (state.status == ProductsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Une erreur s\'est produite',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(productsProvider.notifier).loadProducts(refresh: true);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
      // Check if it's a search result
      if (_searchController.text.isNotEmpty) {
        return EmptySearchState(
          searchQuery: _searchController.text,
          onClear: () {
            _searchController.clear();
            ref.read(productsProvider.notifier).loadProducts(refresh: true);
          },
        );
      }

      return EmptyProductsState(
        onRefresh: () {
          ref.read(productsProvider.notifier).loadProducts(refresh: true);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(productsProvider.notifier).loadProducts(refresh: true);
      },
      child: ResponsiveBuilder(
        builder: (context, r) {
          final columns = r.value(mobile: 2, tablet: 3, desktop: 4);
          final aspectRatio = r.value(mobile: 0.75, tablet: 0.72, desktop: 0.7);
          
          return GridView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(r.horizontalPadding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: r.gridSpacing,
              mainAxisSpacing: r.gridSpacing,
            ),
            itemCount:
                state.products.length +
                (state.status == ProductsStatus.loadingMore ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= state.products.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final product = state.products[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductEntity product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.pushSlideAndFade(ProductDetailsPage(productId: product.id));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: product.imageUrl != null
                    ? Hero(
                        tag: 'product-image-${product.id}',
                        child: ProductImage(
                          imageUrl: product.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.medication,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    // Price and Stock
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currencyFormat.format(product.price),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              product.isAvailable
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 14,
                              color: product.isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.isAvailable ? 'Disponible' : 'Rupture',
                              style: TextStyle(
                                fontSize: 12,
                                color: product.isAvailable
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildPrescriptionBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.goToPrescriptionUpload(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.file_upload,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vous avez une ordonnance ?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uploadez-la pour validation',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final selectedCategory = ref.watch(formFieldsProvider(_selectedCategoryId))['category'];
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return CategoryChip(
            name: category['name'],
            icon: category['icon'],
            isSelected: selectedCategory == category['id'],
            onTap: () {
              if (selectedCategory == category['id']) {
                ref.read(formFieldsProvider(_selectedCategoryId).notifier).setField('category', null);
                ref
                    .read(productsProvider.notifier)
                    .loadProducts(refresh: true);
              } else {
                ref.read(formFieldsProvider(_selectedCategoryId).notifier).setField('category', category['id']);
                ref
                    .read(productsProvider.notifier)
                    .filterByCategory(category['id'], refresh: true);
              }
            },
          );
        },
      ),
    );
  }
}
