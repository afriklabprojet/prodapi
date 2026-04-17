import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/category_entity.dart';

enum InventoryStatus { initial, loading, loaded, error }

/// Filtre pour l'état du stock
enum StockFilter { all, inStock, lowStock, outOfStock }

/// Tri des produits
enum ProductSortBy { name, priceAsc, priceDesc, stockAsc, stockDesc }

class InventoryState {
  final InventoryStatus status;
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;
  final String? errorMessage;
  final String searchQuery;

  // -- Nouveaux filtres avancés --
  final StockFilter stockFilter;
  final String? selectedCategory;
  final bool? requiresPrescriptionFilter;
  final ProductSortBy sortBy;

  const InventoryState({
    this.status = InventoryStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.stockFilter = StockFilter.all,
    this.selectedCategory,
    this.requiresPrescriptionFilter,
    this.sortBy = ProductSortBy.name,
  });

  /// Vérifie si des filtres avancés sont actifs
  bool get hasActiveFilters =>
      stockFilter != StockFilter.all ||
      selectedCategory != null ||
      requiresPrescriptionFilter != null;

  /// Nombre de filtres actifs
  int get activeFilterCount {
    int count = 0;
    if (stockFilter != StockFilter.all) count++;
    if (selectedCategory != null) count++;
    if (requiresPrescriptionFilter != null) count++;
    return count;
  }

  InventoryState copyWith({
    InventoryStatus? status,
    List<ProductEntity>? products,
    List<CategoryEntity>? categories,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? searchQuery,
    StockFilter? stockFilter,
    String? selectedCategory,
    bool clearCategory = false,
    bool? requiresPrescriptionFilter,
    bool clearPrescriptionFilter = false,
    ProductSortBy? sortBy,
  }) {
    return InventoryState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      stockFilter: stockFilter ?? this.stockFilter,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      requiresPrescriptionFilter: clearPrescriptionFilter
          ? null
          : (requiresPrescriptionFilter ?? this.requiresPrescriptionFilter),
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
