import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/auth_response_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponseEntity>> login({
    required String email,
    required String password,
  });

  /// Login with biometric authentication (no password required)
  Future<Either<Failure, AuthResponseEntity>> loginWithBiometric({
    required String email,
  });

  Future<Either<Failure, AuthResponseEntity>> register({
    required String name,
    required String pName,
    required String email,
    required String phone,
    required String password,
    required String licenseNumber,
    required String city,
    required String address,
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();
  
  Future<Either<Failure, bool>> checkAuthStatus();

  Future<Either<Failure, void>> forgotPassword({required String email});

  Future<Either<Failure, void>> updateProfile({
    String? name,
    String? email,
    String? phone,
  });
}
