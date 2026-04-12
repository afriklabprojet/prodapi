import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

class GetProductsByCategoryUseCase {
  final dynamic repository;
  GetProductsByCategoryUseCase(this.repository);

  Future<Either<Failure, List<ProductEntity>>> call({
    String? category,
    int page = 1,
    int perPage = 20,
  }) async {
    if (category == null) {
      return await repository.getProducts(page: page, perPage: perPage);
    }
    return await repository.getProductsByCategory(
      category: category,
      page: page,
      perPage: perPage,
    );
  }
}
