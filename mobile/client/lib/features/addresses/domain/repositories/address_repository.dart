import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/address_remote_datasource.dart';
import '../entities/address_entity.dart';

/// Repository pour les adresses
abstract class AddressRepository {
  Future<Either<Failure, List<AddressEntity>>> getAddresses();
  Future<Either<Failure, AddressEntity>> getAddress(int id);
  Future<Either<Failure, AddressEntity>> getDefaultAddress();
  Future<Either<Failure, AddressEntity>> createAddress({
    required String label,
    required String address,
    String? city,
    String? district,
    String? phone,
    String? instructions,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  });
  Future<Either<Failure, AddressEntity>> updateAddress({
    required int id,
    String? label,
    String? address,
    String? city,
    String? district,
    String? phone,
    String? instructions,
    double? latitude,
    double? longitude,
    bool? isDefault,
  });
  Future<Either<Failure, void>> deleteAddress(int id);
  Future<Either<Failure, AddressEntity>> setDefaultAddress(int id);
  Future<Either<Failure, AddressFormData>> getLabels();
}
