import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/pharmacy_entity.dart';

class GetPharmacyDetailsUseCase {
  final dynamic repository;
  GetPharmacyDetailsUseCase(this.repository);

  Future<Either<Failure, PharmacyEntity>> call(int id) async {
    return await repository.getPharmacyDetails(id);
  }
}
