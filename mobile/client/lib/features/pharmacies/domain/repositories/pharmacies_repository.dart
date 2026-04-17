import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/pharmacy_entity.dart';

abstract class PharmaciesRepository {
  Future<Either<Failure, List<PharmacyEntity>>> getPharmacies({int page = 1, int perPage = 20});
  Future<Either<Failure, List<PharmacyEntity>>> getNearbyPharmacies({required double latitude, required double longitude, double? radius});
  Future<Either<Failure, List<PharmacyEntity>>> getOnDutyPharmacies({double? latitude, double? longitude, double? radius});
  Future<Either<Failure, PharmacyEntity>> getPharmacyDetails(int pharmacyId);
  Future<Either<Failure, List<PharmacyEntity>>> getFeaturedPharmacies();
}
