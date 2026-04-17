import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/pharmacy_entity.dart';

class GetFeaturedPharmaciesUseCase {
  final dynamic repository;
  GetFeaturedPharmaciesUseCase(this.repository);

  Future<Either<Failure, List<PharmacyEntity>>> call() async {
    return await repository.getFeaturedPharmacies();
  }
}
