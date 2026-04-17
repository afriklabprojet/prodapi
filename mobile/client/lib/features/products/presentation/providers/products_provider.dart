import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../domain/usecases/get_product_details_usecase.dart';
import '../../domain/usecases/get_products_by_category_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/search_products_usecase.dart';
import 'products_notifier.dart';
import 'products_state.dart';

final productsProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  final repository = ref.watch(productsRepositoryProvider);

  return ProductsNotifier(
    getProductsUseCase: GetProductsUseCase(repository),
    searchProductsUseCase: SearchProductsUseCase(repository),
    getProductDetailsUseCase: GetProductDetailsUseCase(repository),
    getProductsByCategoryUseCase: GetProductsByCategoryUseCase(repository),
  );
});
