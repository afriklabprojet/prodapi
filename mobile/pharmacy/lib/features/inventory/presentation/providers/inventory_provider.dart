import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../providers/inventory_di_providers.dart';
import 'state/inventory_state.dart';
import '../../domain/entities/product_entity.dart';

class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryRepository _repository;

  InventoryNotifier(this._repository) : super(const InventoryState()) {
    fetchProducts();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await _repository.getCategories();
    result.fold(
      (l) {}, // Silently fail or log
      (cats) => state = state.copyWith(categories: cats),
    );
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(status: InventoryStatus.loading, errorMessage: null);

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
          errorMessage: null,
        );
      },
    );
  }

  Future<void> addCategory(String name, String? description) async {
    final result = await _repository.addCategory(name, description);

    result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        throw Exception(failure.message);
      },
      (newCategory) {
        final currentCategories = [...state.categories, newCategory];
        currentCategories.sort((a, b) => a.name.compareTo(b.name));

        state = state.copyWith(
          categories: currentCategories,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> updateCategory(int id, String name, String? description) async {
    final result = await _repository.updateCategory(id, name, description);

    result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        throw Exception(failure.message);
      },
      (updatedCategory) {
        final updatedCategories = state.categories.map((c) {
          return c.id == id ? updatedCategory : c;
        }).toList();
        updatedCategories.sort((a, b) => a.name.compareTo(b.name));

        state = state.copyWith(
          categories: updatedCategories,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> deleteCategory(int id) async {
    final result = await _repository.deleteCategory(id);

    result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        throw Exception(failure.message);
      },
      (_) {
        final updatedCategories = state.categories.where((c) => c.id != id).toList();
        state = state.copyWith(
          categories: updatedCategories,
          errorMessage: null,
        );
      },
    );
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
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

  Future<void> updateProduct(int id, Map<String, dynamic> data, {XFile? image}) async {
    final result = await _repository.updateProduct(id, data, image: image);

    result.fold(
      (failure) => state = state.copyWith(
        status: InventoryStatus.error,
        errorMessage: failure.message,
      ),
      (updatedProduct) {
        final newProducts = state.products.map((p) => p.id == id ? updatedProduct : p).toList();
        state = state.copyWith(
          products: newProducts,
          errorMessage: null,
        );
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
        state = state.copyWith(
          products: newProducts,
          errorMessage: null,
        );
      },
    );
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
      return InventoryNotifier(ref.watch(inventoryRepositoryProvider));
    });
