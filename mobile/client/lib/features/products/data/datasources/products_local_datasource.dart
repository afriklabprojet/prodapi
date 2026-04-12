import '../../../../core/services/cache_service.dart';
import '../../../../core/services/app_logger.dart';
import '../models/product_model.dart';

/// Datasource locale pour les produits — cache Hive via CacheService
class ProductsLocalDataSource {
  static const String _productsKey = 'products_list';
  static const String _productDetailsPrefix = 'product_detail_';

  /// Met en cache la liste des produits (première page)
  Future<void> cacheProducts(List<ProductModel> products) async {
    try {
      final jsonList = products.map((p) => p.toJson()).toList();
      CacheService.cacheProducts(_productsKey, jsonList);
    } catch (e) {
      AppLogger.warning('ProductsLocalDataSource.cacheProducts failed: $e');
    }
  }

  /// Récupère la liste de produits depuis le cache
  Future<List<ProductModel>?> getCachedProducts() async {
    try {
      final cached = CacheService.getCachedProducts(_productsKey);
      if (cached == null) return null;
      return cached.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      AppLogger.warning('ProductsLocalDataSource.getCachedProducts failed: $e');
      return null;
    }
  }

  /// Met en cache les détails d'un produit
  Future<void> cacheProductDetails(ProductModel product) async {
    try {
      final key = '$_productDetailsPrefix${product.id}';
      CacheService.cacheProducts(key, [product.toJson()]);
    } catch (e) {
      AppLogger.warning(
        'ProductsLocalDataSource.cacheProductDetails failed: $e',
      );
    }
  }

  /// Récupère le détail d'un produit depuis le cache
  Future<ProductModel?> getCachedProductDetails(int productId) async {
    try {
      final key = '$_productDetailsPrefix$productId';
      final cached = CacheService.getCachedProducts(key);
      if (cached == null || cached.isEmpty) return null;
      return ProductModel.fromJson(cached.first);
    } catch (e) {
      AppLogger.warning(
        'ProductsLocalDataSource.getCachedProductDetails failed: $e',
      );
      return null;
    }
  }
}
