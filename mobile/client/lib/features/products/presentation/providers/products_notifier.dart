import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_product_details_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/search_products_usecase.dart';
import '../../domain/usecases/get_products_by_category_usecase.dart';
import 'products_state.dart';

class ProductsNotifier extends StateNotifier<ProductsState> {
  final GetProductsUseCase getProductsUseCase;
  final SearchProductsUseCase searchProductsUseCase;
  final GetProductDetailsUseCase getProductDetailsUseCase;
  final GetProductsByCategoryUseCase getProductsByCategoryUseCase;

  Timer? _debounce;

  ProductsNotifier({
    required this.getProductsUseCase,
    required this.searchProductsUseCase,
    required this.getProductDetailsUseCase,
    required this.getProductsByCategoryUseCase,
  }) : super(const ProductsState.initial()) {
    loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      state = const ProductsState.loading();
    } else if (state.status == ProductsStatus.loading ||
        state.status == ProductsStatus.loadingMore) {
      return; // Already loading
    }

    final page = refresh ? 1 : state.currentPage;

    final result = await getProductsUseCase(page: page);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: ProductsStatus.error,
          errorMessage: failure.message,
        );
      },
      (products) {
        if (refresh) {
          state = ProductsState(
            status: ProductsStatus.loaded,
            products: products,
            currentPage: 1,
            hasMore: products.length >= 20,
          );
        } else {
          state = state.copyWith(
            status: ProductsStatus.loaded,
            products: [...state.products, ...products],
            currentPage: page,
            hasMore: products.length >= 20,
          );
        }
      },
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == ProductsStatus.loadingMore) {
      return;
    }

    state = state.copyWith(status: ProductsStatus.loadingMore);

    final nextPage = state.currentPage + 1;
    final result = await getProductsUseCase(page: nextPage);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: ProductsStatus.loaded,
          errorMessage: failure.message,
        );
      },
      (products) {
        state = state.copyWith(
          status: ProductsStatus.loaded,
          products: [...state.products, ...products],
          currentPage: nextPage,
          hasMore: products.length >= 20,
        );
      },
    );
  }

  // removed duplicate definition

  Future<void> loadProductDetails(int productId) async {
    state = state.copyWith(status: ProductsStatus.loading);

    final result = await getProductDetailsUseCase(productId);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: ProductsStatus.error,
          errorMessage: failure.message,
        );
      },
      (product) {
        state = state.copyWith(
          status: ProductsStatus.loaded,
          selectedProduct: product,
        );
      },
    );
  }

  Future<void> filterByCategory(String? category, {bool refresh = true}) async {
    if (refresh) {
      state = const ProductsState.loading();
    }

    final page = refresh ? 1 : state.currentPage;

    final result = await getProductsByCategoryUseCase(
      category: category,
      page: page,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: ProductsStatus.error,
          errorMessage: failure.message,
        );
      },
      (products) {
        if (refresh) {
          state = ProductsState(
            status: ProductsStatus.loaded,
            products: products,
            currentPage: 1,
            hasMore: products.length >= 20,
          );
        } else {
          state = state.copyWith(
            status: ProductsStatus.loaded,
            products: [...state.products, ...products],
            currentPage: page,
            hasMore: products.length >= 20,
          );
        }
      },
    );
  }

  Future<void> searchProducts(String query) async {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      loadProducts(refresh: true);
      return;
    }

    // Debounce 400ms to avoid excessive API calls while typing
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      state = const ProductsState.loading();

      final result = await searchProductsUseCase(query: query);

      if (!mounted) return;
      result.fold(
        (failure) {
          state = state.copyWith(
            status: ProductsStatus.error,
            errorMessage: failure.message,
          );
        },
        (products) {
          state = ProductsState(
            status: ProductsStatus.loaded,
            products: products,
            currentPage: 1,
            hasMore: products.length >= 20,
          );
        },
      );
    });
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(
        errorMessage: null,
        status: state.products.isEmpty
            ? ProductsStatus.initial
            : ProductsStatus.loaded,
      );
    }
  }
}
