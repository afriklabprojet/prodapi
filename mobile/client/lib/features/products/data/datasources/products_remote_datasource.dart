import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/cache_service.dart';
import '../models/product_model.dart';

class ProductsRemoteDataSource {
  final ApiClient apiClient;

  ProductsRemoteDataSource(this.apiClient);

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final cacheKey = 'products_p${page}_pp$perPage';
    try {
      final response = await apiClient.get(
        ApiConstants.products,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final responseData = response.data['data'];
      final List<dynamic> data = responseData is List
          ? responseData
          : (responseData['products'] ?? responseData['data'] ?? []);
      // Cache les données brutes
      CacheService.cacheProducts(cacheKey, data.cast<Map<String, dynamic>>());
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback cache offline
      final cached = CacheService.getCachedProducts(cacheKey);
      if (cached != null) {
        AppLogger.info('Products loaded from cache (key: $cacheKey)');
        return cached.map((json) => ProductModel.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<ProductModel> getProductDetails(int productId) async {
    final response = await apiClient.get(
      ApiConstants.productDetails(productId),
    );
    final responseData = response.data['data'];
    final productJson =
        responseData is Map<String, dynamic> &&
            responseData.containsKey('product')
        ? responseData['product'] as Map<String, dynamic>
        : responseData as Map<String, dynamic>;
    return ProductModel.fromJson(productJson);
  }

  Future<List<ProductModel>> searchProducts({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    final cacheKey = 'search_${query}_p${page}_pp$perPage';
    try {
      final response = await apiClient.get(
        ApiConstants.searchProducts,
        queryParameters: {'q': query, 'page': page, 'per_page': perPage},
      );
      final responseData = response.data['data'];
      final List<dynamic> data = responseData is List
          ? responseData
          : (responseData['products'] ?? responseData['data'] ?? []);
      CacheService.cacheProducts(cacheKey, data.cast<Map<String, dynamic>>());
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final cached = CacheService.getCachedProducts(cacheKey);
      if (cached != null) {
        AppLogger.info('Search results loaded from cache (key: $cacheKey)');
        return cached.map((json) => ProductModel.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<List<ProductModel>> getProductsByCategory({
    required String category,
    int page = 1,
    int perPage = 20,
  }) async {
    final cacheKey = 'cat_${category}_p${page}_pp$perPage';
    try {
      final response = await apiClient.get(
        ApiConstants.productsByCategory,
        queryParameters: {
          'category': category,
          'page': page,
          'per_page': perPage,
        },
      );
      final responseData = response.data['data'];
      final List<dynamic> data = responseData is List
          ? responseData
          : (responseData['products'] ?? responseData['data'] ?? []);
      CacheService.cacheProducts(cacheKey, data.cast<Map<String, dynamic>>());
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final cached = CacheService.getCachedProducts(cacheKey);
      if (cached != null) {
        AppLogger.info('Category products loaded from cache (key: $cacheKey)');
        return cached.map((json) => ProductModel.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<List<ProductModel>> getProductsByPharmacy({
    required int pharmacyId,
    int page = 1,
    int perPage = 20,
  }) async {
    final cacheKey = 'pharmacy_${pharmacyId}_p${page}_pp$perPage';
    try {
      final response = await apiClient.get(
        '/pharmacies/$pharmacyId/products',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final responseData = response.data['data'];
      final List<dynamic> data = responseData is List
          ? responseData
          : (responseData['data'] ?? []);
      CacheService.cacheProducts(cacheKey, data.cast<Map<String, dynamic>>());
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final cached = CacheService.getCachedProducts(cacheKey);
      if (cached != null) {
        AppLogger.info('Pharmacy products loaded from cache (key: $cacheKey)');
        return cached.map((json) => ProductModel.fromJson(json)).toList();
      }
      rethrow;
    }
  }
}
