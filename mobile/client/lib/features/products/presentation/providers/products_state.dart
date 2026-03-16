import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';

enum ProductsStatus {
  initial,
  loading,
  loaded,
  error,
  loadingMore, // For pagination
}

class ProductsState extends Equatable {
  final ProductsStatus status;
  final List<ProductEntity> products;
  final ProductEntity? selectedProduct;
  final String? errorMessage;
  final int currentPage;
  final bool hasMore;

  const ProductsState({
    required this.status,
    required this.products,
    this.selectedProduct,
    this.errorMessage,
    this.currentPage = 1,
    this.hasMore = true,
  });

  const ProductsState.initial()
      : status = ProductsStatus.initial,
        products = const [],
        selectedProduct = null,
        errorMessage = null,
        currentPage = 1,
        hasMore = true;

  const ProductsState.loading()
      : status = ProductsStatus.loading,
        products = const [],
        selectedProduct = null,
        errorMessage = null,
        currentPage = 1,
        hasMore = true;

  ProductsState copyWith({
    ProductsStatus? status,
    List<ProductEntity>? products,
    ProductEntity? selectedProduct,
    bool clearSelectedProduct = false,
    String? errorMessage,
    bool clearError = false,
    int? currentPage,
    bool? hasMore,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedProduct: clearSelectedProduct ? null : (selectedProduct ?? this.selectedProduct),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        selectedProduct,
        errorMessage,
        currentPage,
        hasMore,
      ];
}
