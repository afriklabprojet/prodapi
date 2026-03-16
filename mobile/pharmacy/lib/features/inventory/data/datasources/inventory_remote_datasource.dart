import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

abstract class InventoryRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<CategoryModel>> getCategories();
  Future<void> updateStock(int productId, int newQuantity);
  Future<void> updatePrice(int productId, double newPrice);
  Future<void> toggleAvailability(int productId);
  Future<void> applyPromotion(int productId, double discountPercentage, {DateTime? endDate});
  Future<void> removePromotion(int productId);
  Future<void> markAsLoss(int productId, int quantity, String reason);
  Future<ProductModel> addProduct(Map<String, dynamic> productData, {XFile? image});
  Future<ProductModel> updateProduct(int id, Map<String, dynamic> productData, {XFile? image});
  Future<void> deleteProduct(int id);
  Future<CategoryModel> addCategory(String name, String? description);
  Future<CategoryModel> updateCategory(int id, String name, String? description);
  Future<void> deleteCategory(int id);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final ApiClient apiClient;

  InventoryRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ProductModel>> getProducts() async {
    // Liste des produits
    final response = await apiClient.get('/pharmacy/inventory');

    return (response.data['data'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    // Liste des catégories
    final response = await apiClient.get('/pharmacy/inventory/categories');

    return (response.data['data'] as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
  }

  @override
  Future<void> updateStock(int productId, int newQuantity) async {
    // Mise à jour du stock
    await apiClient.post(
      '/pharmacy/inventory/$productId/stock',
      data: {'quantity': newQuantity},
    );
  }

  @override
  Future<void> updatePrice(int productId, double newPrice) async {
    // Mise à jour du prix
    await apiClient.post(
      '/pharmacy/inventory/$productId/price',
      data: {'price': newPrice},
    );
  }

  @override
  Future<void> toggleAvailability(int productId) async {
    // Bascule de statut
    await apiClient.post('/pharmacy/inventory/$productId/toggle-status');
  }

  @override
  Future<ProductModel> addProduct(Map<String, dynamic> productData, {XFile? image}) async {
    // Ajout d'un nouveau produit avec gestion d'image
    // Conversion des booléens en entiers (1/0) pour Laravel Validation
    final Map<String, dynamic> safeData = Map.from(productData);
    if (safeData['requires_prescription'] is bool) {
      safeData['requires_prescription'] = safeData['requires_prescription'] ? 1 : 0;
    }

    dynamic data;
    if (image != null) {
      final bytes = await image.readAsBytes();
      final mimeType = _getMimeType(image.name);
      data = FormData.fromMap({
        ...safeData,
        'image': MultipartFile.fromBytes(
          bytes,
          filename: image.name,
          contentType: mimeType,
        ),
      });
    } else {
      data = safeData;
    }

    final response = await apiClient.post(
      '/pharmacy/inventory',
      data: data,
    );
    return ProductModel.fromJson(response.data['data']);
  }

  @override
  Future<ProductModel> updateProduct(int id, Map<String, dynamic> productData, {XFile? image}) async {
    final Map<String, dynamic> safeData = Map.from(productData);
    if (safeData['requires_prescription'] is bool) {
      safeData['requires_prescription'] = safeData['requires_prescription'] ? 1 : 0;
    }

    dynamic data;
    if (image != null) {
      final bytes = await image.readAsBytes();
      final mimeType = _getMimeType(image.name);
      data = FormData.fromMap({
        ...safeData,
        'image': MultipartFile.fromBytes(
          bytes,
          filename: image.name,
          contentType: mimeType,
        ),
      });
    } else {
      data = safeData;
    }

    final response = await apiClient.post(
      '/pharmacy/inventory/$id/update',
      data: data,
    );
    return ProductModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteProduct(int id) async {
    await apiClient.delete('/pharmacy/inventory/$id');
  }

  @override
  Future<void> applyPromotion(int productId, double discountPercentage, {DateTime? endDate}) async {
    await apiClient.post(
      '/pharmacy/inventory/$productId/promotion',
      data: {
        'discount_percentage': discountPercentage,
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      },
    );
  }

  @override
  Future<void> removePromotion(int productId) async {
    await apiClient.delete('/pharmacy/inventory/$productId/promotion');
  }

  @override
  Future<void> markAsLoss(int productId, int quantity, String reason) async {
    await apiClient.post(
      '/pharmacy/inventory/$productId/loss',
      data: {
        'quantity': quantity,
        'reason': reason,
      },
    );
  }

  @override
  Future<CategoryModel> addCategory(String name, String? description) async {
    final response = await apiClient.post(
      '/pharmacy/inventory/categories',
      data: {
        'name': name,
        'description': description,
      },
    );
    return CategoryModel.fromJson(response.data['data']);
  }

  @override
  Future<CategoryModel> updateCategory(int id, String name, String? description) async {
    final response = await apiClient.put(
      '/pharmacy/inventory/categories/$id',
      data: {
        'name': name,
        'description': description,
      },
    );
    return CategoryModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteCategory(int id) async {
    await apiClient.delete('/pharmacy/inventory/categories/$id');
  }

  /// Détermine le type MIME à partir de l'extension du fichier
  MediaType _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
