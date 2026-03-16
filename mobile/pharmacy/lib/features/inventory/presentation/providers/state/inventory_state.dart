import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/category_entity.dart';

enum InventoryStatus { initial, loading, loaded, error }

class InventoryState {
  final InventoryStatus status;
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;
  final String? errorMessage;
  final String searchQuery;

  const InventoryState({
    this.status = InventoryStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.errorMessage,
    this.searchQuery = '',
  });

  InventoryState copyWith({
    InventoryStatus? status,
    List<ProductEntity>? products,
    List<CategoryEntity>? categories,
    String? errorMessage,
    String? searchQuery,
  }) {
    return InventoryState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
