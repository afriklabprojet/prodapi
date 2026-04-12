import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductsRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
    int perPage = 20,
  });
  Future<Either<Failure, ProductEntity>> getProductDetails(int productId);
  Future<Either<Failure, List<ProductEntity>>> searchProducts({
    required String query,
    int page = 1,
    int perPage = 20,
  });
  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory({
    required String category,
    int page = 1,
    int perPage = 20,
  });
  Future<Either<Failure, List<ProductEntity>>> getProductsByPharmacy({
    required int pharmacyId,
    int page = 1,
    int perPage = 20,
  });
}
