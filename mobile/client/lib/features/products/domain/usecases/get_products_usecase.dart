import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

/// Use case pour récupérer la liste des produits
class GetProductsUseCase {
  final dynamic repository; // ProductsRepository
  GetProductsUseCase(this.repository);

  Future<Either<Failure, List<ProductEntity>>> call({int page = 1}) async {
    return await repository.getProducts(page: page);
  }
}
