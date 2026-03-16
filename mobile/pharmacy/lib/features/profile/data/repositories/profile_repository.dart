import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';

/// Repository pour la gestion du profil pharmacien.
abstract class ProfileRepository {
  Future<Either<Failure, Map<String, dynamic>>> getProfile();
  Future<Either<Failure, void>> updateProfile(Map<String, dynamic> data);
  Future<Either<Failure, void>> updatePharmacy(int pharmacyId, Map<String, dynamic> data);
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient apiClient;

  ProfileRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProfile() async {
    try {
      final response = await apiClient.get('/pharmacy/profile');
      return Right(response.data['data'] as Map<String, dynamic>);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return Left(NetworkFailure('Pas de connexion internet'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile(Map<String, dynamic> data) async {
    try {
      await apiClient.put('/pharmacy/profile', data: data);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return Left(NetworkFailure('Pas de connexion internet'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePharmacy(int pharmacyId, Map<String, dynamic> data) async {
    try {
      await apiClient.put('/pharmacy/pharmacies/$pharmacyId', data: data);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return Left(NetworkFailure('Pas de connexion internet'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await apiClient.post('/pharmacy/change-password', data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return Left(NetworkFailure('Pas de connexion internet'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
