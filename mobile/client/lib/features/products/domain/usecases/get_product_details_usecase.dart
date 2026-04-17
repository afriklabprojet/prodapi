import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

class GetProductDetailsUseCase {
  final dynamic repository;
  GetProductDetailsUseCase(this.repository);

  Future<Either<Failure, ProductEntity>> call(int productId) async {
    return await repository.getProductDetails(productId);
  }
}
