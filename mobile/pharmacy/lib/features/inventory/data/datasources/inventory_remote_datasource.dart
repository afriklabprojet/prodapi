import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_batch_model.dart';
import '../models/product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper Functions
// ─────────────────────────────────────────────────────────────────────────────

/// Retourne le MediaType approprié pour une extension d'image.
MediaType _getMimeTypeForExtension(String ext) => switch (ext) {
  'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
  'png' => MediaType('image', 'png'),
  'webp' => MediaType('image', 'webp'),
  'gif' => MediaType('image', 'gif'),
  _ => MediaType('image', 'jpeg'),
};

// ─────────────────────────────────────────────────────────────────────────────
// Interface
// ─────────────────────────────────────────────────────────────────────────────

abstract class InventoryRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<CategoryModel>> getCategories();
  Future<void> updateStock(int productId, int newQuantity);
  Future<void> updatePrice(int productId, double newPrice);
  Future<void> toggleAvailability(int productId);
  Future<void> applyPromotion(
    int productId,
    double discountPercentage, {
    DateTime? endDate,
  });
  Future<void> removePromotion(int productId);
  Future<void> markAsLoss(int productId, int quantity, String reason);
  Future<ProductModel> addProduct(
    Map<String, dynamic> productData, {
    XFile? image,
  });
  Future<ProductModel> updateProduct(
    int id,
    Map<String, dynamic> productData, {
    XFile? image,
  });
  Future<void> deleteProduct(int id);
  Future<CategoryModel> addCategory(String name, String? description);
  Future<CategoryModel> updateCategory(
    int id,
    String name,
    String? description,
  );
  Future<void> deleteCategory(int id);
  Future<List<ProductBatchModel>> getProductBatches({int? productId});
  Future<ProductBatchModel> addBatch(Map<String, dynamic> data);
  Future<void> deleteBatch(int batchId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Implementation
// ─────────────────────────────────────────────────────────────────────────────

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final ApiClient apiClient;

  InventoryRemoteDataSourceImpl({required this.apiClient});

  // ─────────────────────────────────────────────────────────────────────────
  // Products
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await apiClient.get('/pharmacy/inventory');
    return _extractList(
      response.data,
    ).map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<ProductModel> addProduct(
    Map<String, dynamic> productData, {
    XFile? image,
  }) async {
    final data = await _prepareDataWithImage(productData, image);
    final response = await apiClient.post('/pharmacy/inventory', data: data);
    return ProductModel.fromJson(response.data['data']);
  }

  @override
  Future<ProductModel> updateProduct(
    int id,
    Map<String, dynamic> productData, {
    XFile? image,
  }) async {
    final data = await _prepareDataWithImage(productData, image);
    final response = await apiClient.post(
      '/pharmacy/inventory/$id/update',
      data: data,
    );
    return ProductModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteProduct(int id) =>
      apiClient.delete('/pharmacy/inventory/$id');

  @override
  Future<void> updateStock(int productId, int newQuantity) => apiClient.post(
    '/pharmacy/inventory/$productId/stock',
    data: {'quantity': newQuantity},
  );

  @override
  Future<void> updatePrice(int productId, double newPrice) => apiClient.post(
    '/pharmacy/inventory/$productId/price',
    data: {'price': newPrice},
  );

  @override
  Future<void> toggleAvailability(int productId) =>
      apiClient.post('/pharmacy/inventory/$productId/toggle-status');

  // ─────────────────────────────────────────────────────────────────────────
  // Promotions & Loss
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> applyPromotion(
    int productId,
    double discountPercentage, {
    DateTime? endDate,
  }) => apiClient.post(
    '/pharmacy/inventory/$productId/promotion',
    data: {
      'discount_percentage': discountPercentage,
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    },
  );

  @override
  Future<void> removePromotion(int productId) =>
      apiClient.delete('/pharmacy/inventory/$productId/promotion');

  @override
  Future<void> markAsLoss(int productId, int quantity, String reason) =>
      apiClient.post(
        '/pharmacy/inventory/$productId/loss',
        data: {'quantity': quantity, 'reason': reason},
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Categories
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await apiClient.get('/pharmacy/inventory/categories');
    return _extractList(
      response.data,
    ).map((e) => CategoryModel.fromJson(e)).toList();
  }

  @override
  Future<CategoryModel> addCategory(String name, String? description) async {
    final response = await apiClient.post(
      '/pharmacy/inventory/categories',
      data: {'name': name, 'description': description},
    );
    return CategoryModel.fromJson(response.data['data']);
  }

  @override
  Future<CategoryModel> updateCategory(
    int id,
    String name,
    String? description,
  ) async {
    final response = await apiClient.put(
      '/pharmacy/inventory/categories/$id',
      data: {'name': name, 'description': description},
    );
    return CategoryModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteCategory(int id) =>
      apiClient.delete('/pharmacy/inventory/categories/$id');

  // ─────────────────────────────────────────────────────────────────────────
  // Batches
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<ProductBatchModel>> getProductBatches({int? productId}) async {
    final response = await apiClient.get(
      '/pharmacy/inventory/batches',
      queryParameters: productId != null ? {'product_id': productId} : null,
    );
    return _extractList(response.data)
        .map((e) => ProductBatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProductBatchModel> addBatch(Map<String, dynamic> data) async {
    final response = await apiClient.post(
      '/pharmacy/inventory/batches',
      data: data,
    );
    return ProductBatchModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteBatch(int batchId) =>
      apiClient.delete('/pharmacy/inventory/batches/$batchId');

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Extract a List from various API response shapes.
  static List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map && inner['data'] is List) return inner['data'] as List;
    }
    return [];
  }

  /// Prépare les données du produit avec image optionnelle en FormData.
  Future<dynamic> _prepareDataWithImage(
    Map<String, dynamic> productData,
    XFile? image,
  ) async {
    final safeData = _sanitizeBooleans(productData);
    if (image == null) return safeData;

    final bytes = await image.readAsBytes();
    final ext = image.name.split('.').last.toLowerCase();
    return FormData.fromMap({
      ...safeData,
      'image': MultipartFile.fromBytes(
        bytes,
        filename: image.name,
        contentType: _getMimeTypeForExtension(ext),
      ),
    });
  }

  /// Convertit les booléens en int (0/1) pour Laravel validation.
  Map<String, dynamic> _sanitizeBooleans(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    if (result['requires_prescription'] is bool) {
      result['requires_prescription'] = result['requires_prescription'] ? 1 : 0;
    }
    return result;
  }
}
