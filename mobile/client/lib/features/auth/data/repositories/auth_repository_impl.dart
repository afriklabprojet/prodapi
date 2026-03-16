import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final ApiClient apiClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.apiClient,
  });

  @override
  Future<Either<Failure, AuthResponseEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Cache token and user
      await localDataSource.cacheToken(result.token);
      await localDataSource.cacheUser(result.user);

      // Configure ApiClient with the new token
      apiClient.setToken(result.token);

      // Authentifier auprès de Firebase avec le custom token (pour Firestore tracking)
      if (result.firebaseToken != null) {
        try {
          await fb.FirebaseAuth.instance
              .signInWithCustomToken(result.firebaseToken!);
          debugPrint('🔥 [Firebase Auth] Client connecté');
        } catch (e) {
          debugPrint('⚠️ [Firebase Auth] Erreur signIn: $e');
        }
      }

      return Right(result.toEntity());
    } on ValidationException catch (e) {
      // Extraire le premier message d'erreur
      String errorMessage = 'Erreur de validation';
      if (e.errors.isNotEmpty) {
        final firstKey = e.errors.keys.first;
        if (e.errors[firstKey]!.isNotEmpty) {
          errorMessage = e.errors[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: 401));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? address,
  }) async {
    try {
      final result = await remoteDataSource.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        address: address,
      );

      // Cache token and user
      await localDataSource.cacheToken(result.token);
      await localDataSource.cacheUser(result.user);

      // Configure ApiClient with the new token
      apiClient.setToken(result.token);

      return Right(result.toEntity());
    } on ValidationException catch (e) {
      // Extraire le premier message d'erreur
      String errorMessage = 'Erreur de validation';
      if (e.errors.isNotEmpty) {
        final firstKey = e.errors.keys.first;
        if (e.errors[firstKey]!.isNotEmpty) {
          errorMessage = e.errors[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: 401));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final token = await localDataSource.getCachedToken();
      if (token != null) {
        await remoteDataSource.logout(token);
      }

      // Clear local data
      await localDataSource.clearToken();
      await localDataSource.clearUser();

      // Clear token from ApiClient
      apiClient.clearToken();

      // Déconnecter Firebase Auth
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {}

      return const Right(null);
    } on ServerException catch (e) {
      // Even if server logout fails, clear local data
      await localDataSource.clearToken();
      await localDataSource.clearUser();
      apiClient.clearToken();
      try { await fb.FirebaseAuth.instance.signOut(); } catch (_) {}
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      // Always clear local data
      await localDataSource.clearToken();
      await localDataSource.clearUser();
      apiClient.clearToken();
      try { await fb.FirebaseAuth.instance.signOut(); } catch (_) {}
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final token = await localDataSource.getCachedToken();
      if (token == null) {
        return const Left(UnauthorizedFailure());
      }

      // Configure ApiClient with the cached token
      apiClient.setToken(token);

      // Try to get cached user first
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }

      // If no cached user, fetch from server
      final user = await remoteDataSource.getCurrentUser(token);
      await localDataSource.cacheUser(user);

      return Right(user.toEntity());
    } on UnauthorizedException catch (_) {
      // Token expired or invalid - clear local data
      await localDataSource.clearToken();
      await localDataSource.clearUser();
      apiClient.clearToken();
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        // Token expired - clear local data
        await localDataSource.clearToken();
        await localDataSource.clearUser();
        apiClient.clearToken();
        return const Left(UnauthorizedFailure());
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      // Return cached user if available during network error
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await localDataSource.getCachedToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getToken() async {
    return await localDataSource.getCachedToken();
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      String errorMessage = 'Erreur de validation';
      if (e.errors.isNotEmpty) {
        final firstKey = e.errors.keys.first;
        if (e.errors[firstKey]!.isNotEmpty) {
          errorMessage = e.errors[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: 401));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    try {
      final result = await remoteDataSource.verifyOtp(
        identifier: identifier,
        otp: otp,
      );

      // Update cached token and user
      await localDataSource.cacheToken(result.token);
      await localDataSource.cacheUser(result.user);

      // Configure ApiClient with the new token
      apiClient.setToken(result.token);

      return Right(result.toEntity());
    } on ValidationException catch (e) {
      String errorMessage = 'Code OTP invalide';
      if (e.errors.isNotEmpty) {
        final firstKey = e.errors.keys.first;
        if (e.errors[firstKey]!.isNotEmpty) {
          errorMessage = e.errors[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> verifyFirebaseOtp({
    required String phone,
    required String firebaseUid,
  }) async {
    try {
      final result = await remoteDataSource.verifyFirebaseOtp(
        phone: phone,
        firebaseUid: firebaseUid,
      );

      // Update cached token and user
      await localDataSource.cacheToken(result.token);
      await localDataSource.cacheUser(result.user);

      // Configure ApiClient with the new token
      apiClient.setToken(result.token);

      return Right(result.toEntity());
    } on ValidationException catch (e) {
      String errorMessage = 'Vérification Firebase échouée';
      if (e.errors.isNotEmpty) {
        final firstKey = e.errors.keys.first;
        if (e.errors[firstKey]!.isNotEmpty) {
          errorMessage = e.errors[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> resendOtp({
    required String identifier,
  }) async {
    try {
      final result = await remoteDataSource.resendOtp(identifier: identifier);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({
    required String email,
  }) async {
    try {
      await remoteDataSource.forgotPassword(email: email);
      return const Right(null);
    } on ValidationException catch (e) {
      String errorMessage = 'Email non trouvé';
      if (e.errors.isNotEmpty) {
        final firstKey = e.errors.keys.first;
        if (e.errors[firstKey]!.isNotEmpty) {
          errorMessage = e.errors[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await remoteDataSource.verifyResetOtp(email: email, otp: otp);
      return const Right(null);
    } on ValidationException catch (e) {
      String errorMessage = 'Code invalide';
      if (e.errors.isNotEmpty) {
        final firstKey = e.errors.keys.first;
        if (e.errors[firstKey]!.isNotEmpty) {
          errorMessage = e.errors[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await remoteDataSource.resetPassword(
        email: email,
        otp: otp,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      String errorMessage = 'Erreur de réinitialisation';
      if (e.errors.isNotEmpty) {
        final firstKey = e.errors.keys.first;
        if (e.errors[firstKey]!.isNotEmpty) {
          errorMessage = e.errors[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
