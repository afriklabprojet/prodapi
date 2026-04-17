import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../providers/inventory_di_providers.dart';
import 'state/inventory_state.dart';
import '../../domain/entities/product_entity.dart';

class InventoryNotifier extends Notifier<InventoryState> {
  late final InventoryRepository _repository;

  @override
  InventoryState build() {
    _repository = ref.watch(inventoryRepositoryProvider);
    // Defer initial fetches to avoid "Bad state: uninitialized" error
    Future.microtask(() {
      fetchProducts();
      _loadCategories();
    });
    return const InventoryState();
  }

  Future<void> _loadCategories() async {
    final result = await _repository.getCategories();
    result.fold(
      (failure) => debugPrint(
        '⚠️ [InventoryNotifier] Failed to load categories: ${failure.message}',
      ),
      (cats) => state = state.copyWith(categories: cats),
    );
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(
      status: InventoryStatus.loading,
      clearErrorMessage: true,
    );

    final result = await _repository.getProducts();

    result.fold(
      (failure) => state = state.copyWith(
        status: InventoryStatus.error,
        errorMessage: failure.message,
      ),
      (products) => state = state.copyWith(
        status: InventoryStatus.loaded,
        products: products,
      ),
    );
  }

  Future<void> updateStock(int productId, int newQuantity) async {
    final result = await _repository.updateStock(productId, newQuantity);

    result.fold(
      (failure) {
        // Handle error (maybe show snackbar via a stream or callback?)
        // For now just refresh to get consistent state
        fetchProducts();
      },
      (_) {
        // Optimistically update the list
        final updatedProducts = state.products.map((p) {
          if (p.id == productId) {
            return p.copyWith(stockQuantity: newQuantity);
          }
          return p;
        }).toList();

        state = state.copyWith(products: updatedProducts);
      },
    );
  }

  Future<void> addProduct(
    String name,
    String description,
    double price,
    int stockQuantity,
    String category,
    bool requiresPrescription, {
    String? barcode,
    XFile? image, // Change to XFile
    // New fields
    String? brand,
    String? manufacturer,
    String? activeIngredient,
    String? unit,
    DateTime? expiryDate,
    String? usageInstructions,
    String? sideEffects,
  }) async {
    final result = await _repository.addProduct(
      name,
      description,
      price,
      stockQuantity,
      category,
      requiresPrescription,
      barcode: barcode,
      image: image,
      brand: brand,
      manufacturer: manufacturer,
      activeIngredient: activeIngredient,
      unit: unit,
      expiryDate: expiryDate,
      usageInstructions: usageInstructions,
      sideEffects: sideEffects,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: InventoryStatus.error,
        errorMessage: failure.message,
      ),
      (newProduct) {
        state = state.copyWith(
          status: InventoryStatus.loaded,
          products: [...state.products, newProduct],
          clearErrorMessage: true,
        );
      },
    );
  }

  /// Returns true if category was added successfully, false otherwise.
  /// Error message is available in state.errorMessage.
  Future<bool> addCategory(String name, String? description) async {
    final result = await _repository.addCategory(name, description);

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (newCategory) {
        final currentCategories = [...state.categories, newCategory];
        currentCategories.sort((a, b) => a.name.compareTo(b.name));

        state = state.copyWith(
          categories: currentCategories,
          clearErrorMessage: true,
        );
        return true;
      },
    );
  }

  /// Returns true if category was updated successfully, false otherwise.
  Future<bool> updateCategory(int id, String name, String? description) async {
    final result = await _repository.updateCategory(id, name, description);

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (updatedCategory) {
        final updatedCategories = state.categories.map((c) {
          return c.id == id ? updatedCategory : c;
        }).toList();
        updatedCategories.sort((a, b) => a.name.compareTo(b.name));

        state = state.copyWith(
          categories: updatedCategories,
          clearErrorMessage: true,
        );
        return true;
      },
    );
  }

  /// Returns true if category was deleted successfully, false otherwise.
  Future<bool> deleteCategory(int id) async {
    final result = await _repository.deleteCategory(id);

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        final updatedCategories = state.categories
            .where((c) => c.id != id)
            .toList();
        state = state.copyWith(
          categories: updatedCategories,
          clearErrorMessage: true,
        );
        return true;
      },
    );
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // -- Méthodes de filtrage avancé --

  /// Définit le filtre de stock
  void setStockFilter(StockFilter filter) {
    state = state.copyWith(stockFilter: filter);
  }

  /// Définit la catégorie filtrée
  void setCategoryFilter(String? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  /// Définit le filtre d'ordonnance
  void setPrescriptionFilter(bool? requiresPrescription) {
    if (requiresPrescription == null) {
      state = state.copyWith(clearPrescriptionFilter: true);
    } else {
      state = state.copyWith(requiresPrescriptionFilter: requiresPrescription);
    }
  }

  /// Définit le tri
  void setSortBy(ProductSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  /// Réinitialise tous les filtres
  void clearAllFilters() {
    state = state.copyWith(
      searchQuery: '',
      stockFilter: StockFilter.all,
      clearCategory: true,
      clearPrescriptionFilter: true,
      sortBy: ProductSortBy.name,
    );
  }

  /// Applique les filtres et le tri sur la liste de produits
  List<ProductEntity> getFilteredProducts() {
    var filtered = state.products.where((product) {
      // Recherche textuelle (nom, DCI, catégorie, code-barres)
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final matchesName = product.name.toLowerCase().contains(query);
        final matchesDci =
            product.activeIngredient?.toLowerCase().contains(query) ?? false;
        final matchesCategory = product.category.toLowerCase().contains(query);
        final matchesBarcode = product.barcode?.contains(query) ?? false;
        final matchesBrand =
            product.brand?.toLowerCase().contains(query) ?? false;
        if (!matchesName &&
            !matchesDci &&
            !matchesCategory &&
            !matchesBarcode &&
            !matchesBrand) {
          return false;
        }
      }

      // Filtre par stock
      switch (state.stockFilter) {
        case StockFilter.inStock:
          if (product.stockQuantity <= 0) return false;
        case StockFilter.lowStock:
          if (product.stockQuantity <= 0 || product.stockQuantity > 10)
            return false;
        case StockFilter.outOfStock:
          if (product.stockQuantity > 0) return false;
        case StockFilter.all:
          break;
      }

      // Filtre par catégorie
      if (state.selectedCategory != null) {
        if (product.category != state.selectedCategory) return false;
      }

      // Filtre par ordonnance
      if (state.requiresPrescriptionFilter != null) {
        if (product.requiresPrescription != state.requiresPrescriptionFilter)
          return false;
      }

      return true;
    }).toList();

    // Tri
    switch (state.sortBy) {
      case ProductSortBy.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case ProductSortBy.priceAsc:
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case ProductSortBy.priceDesc:
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case ProductSortBy.stockAsc:
        filtered.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
      case ProductSortBy.stockDesc:
        filtered.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
    }

    return filtered;
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      fetchProducts();
      return;
    }

    final filtered = state.products.where((p) {
      final nameLower = p.name.toLowerCase();
      return nameLower.contains(query.toLowerCase()) || p.barcode == query;
    }).toList();

    state = state.copyWith(products: filtered);
  }

  ProductEntity? findProductByBarcode(String barcode) {
    try {
      return state.products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProduct(
    int id,
    Map<String, dynamic> data, {
    XFile? image,
  }) async {
    final result = await _repository.updateProduct(id, data, image: image);

    result.fold(
      (failure) => state = state.copyWith(
        status: InventoryStatus.error,
        errorMessage: failure.message,
      ),
      (updatedProduct) {
        final newProducts = state.products
            .map((p) => p.id == id ? updatedProduct : p)
            .toList();
        state = state.copyWith(products: newProducts, clearErrorMessage: true);
      },
    );
  }

  Future<void> deleteProduct(int id) async {
    final result = await _repository.deleteProduct(id);

    result.fold(
      (failure) => state = state.copyWith(
        status: InventoryStatus.error,
        errorMessage: failure.message,
      ),
      (_) {
        final newProducts = state.products.where((p) => p.id != id).toList();
        state = state.copyWith(products: newProducts, clearErrorMessage: true);
      },
    );
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(
  InventoryNotifier.new,
);
