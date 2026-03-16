import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/failure.dart';
import '../entities/product_entity.dart';
import '../entities/category_entity.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts();
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, void>> updateStock(int productId, int newQuantity);
  Future<Either<Failure, void>> updatePrice(int productId, double newPrice);
  Future<Either<Failure, void>> toggleAvailability(int productId);
  Future<Either<Failure, void>> applyPromotion(int productId, double discountPercentage, {DateTime? endDate});
  Future<Either<Failure, void>> removePromotion(int productId);
  Future<Either<Failure, void>> markAsLoss(int productId, int quantity, String reason);
  Future<Either<Failure, ProductEntity>> addProduct(
    String name,
    String description,
    double price,
    int stockQuantity,
    String category,
    bool requiresPrescription, {
    String? barcode,
    XFile? image,
    String? brand,
    String? manufacturer,
    String? activeIngredient,
    String? unit,
    DateTime? expiryDate,
    String? usageInstructions,
    String? sideEffects,
  });
  Future<Either<Failure, ProductEntity>> updateProduct(
    int id,
    Map<String, dynamic> data, {
    XFile? image,
  });
  Future<Either<Failure, void>> deleteProduct(int id);
  Future<Either<Failure, CategoryEntity>> addCategory(String name, String? description);
  Future<Either<Failure, CategoryEntity>> updateCategory(int id, String name, String? description);
  Future<Either<Failure, void>> deleteCategory(int id);
}
