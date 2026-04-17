import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../pharmacies/domain/entities/pharmacy_entity.dart';

class GetPharmaciesUseCase {
  final dynamic repository;
  GetPharmaciesUseCase(this.repository);

  Future<Either<Failure, List<PharmacyEntity>>> call({int page = 1, int perPage = 20}) async {
    return await repository.getPharmacies(page: page, perPage: perPage);
  }
}
