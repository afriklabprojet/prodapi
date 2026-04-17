import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

class SearchProductsUseCase {
  final dynamic repository;
  SearchProductsUseCase(this.repository);

  Future<Either<Failure, List<ProductEntity>>> call({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    return await repository.searchProducts(
      query: query,
      page: page,
      perPage: perPage,
    );
  }
}
