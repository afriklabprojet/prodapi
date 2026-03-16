import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final ApiClient apiClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.apiClient,
  });

  @override
  Future<Either<Failure, AuthResponseEntity>> login({
    required String email,
    required String password,
  }) async {
    if (kDebugMode) debugPrint('📡 [AuthRepository] login() appelé - email: $email');
    
    final isConnected = await networkInfo.isConnected;
    if (kDebugMode) debugPrint('📡 [AuthRepository] Connexion réseau: $isConnected');
    
    if (isConnected) {
      try {
        if (kDebugMode) debugPrint('📡 [AuthRepository] Appel remoteDataSource.login()...');
        final remoteAuth = await remoteDataSource.login(
          email: email,
          password: password,
        );
        if (kDebugMode) debugPrint('📡 [AuthRepository] Réponse reçue - hasToken: ${remoteAuth.token.isNotEmpty}');
        
        await localDataSource.cacheToken(remoteAuth.token);
        await localDataSource.cacheUser(remoteAuth.user);
        if (kDebugMode) debugPrint('📡 [AuthRepository] Token et user mis en cache');
        
        apiClient.setToken(remoteAuth.token);
        if (kDebugMode) debugPrint('📡 [AuthRepository] Token défini dans ApiClient');

        return Right(remoteAuth.toEntity());
      } on ServerException catch (e) {
        if (kDebugMode) debugPrint('❌ [AuthRepository] ServerException: ${e.message}');
        return Left(ServerFailure(e.message));
      } on UnauthorizedException catch (e) {
        if (kDebugMode) debugPrint('❌ [AuthRepository] UnauthorizedException: ${e.message}');
        return Left(UnauthorizedFailure(e.message));
      } on ForbiddenException catch (e) {
        if (kDebugMode) debugPrint('❌ [AuthRepository] ForbiddenException: ${e.message} (code: ${e.errorCode})');
        return Left(ForbiddenFailure(e.message, errorCode: e.errorCode));
      } on ValidationException catch (e) {
        if (kDebugMode) debugPrint('❌ [AuthRepository] ValidationException: ${e.errors}');
        return Left(ValidationFailure(e.errors));
      } catch (e, stackTrace) {
        if (kDebugMode) debugPrint('💥 [AuthRepository] Exception inattendue: $e');
        if (kDebugMode) debugPrint('💥 [AuthRepository] StackTrace: $stackTrace');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      if (kDebugMode) debugPrint('❌ [AuthRepository] Pas de connexion réseau');
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
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
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteAuth = await remoteDataSource.register(
          name: name,
          pName: pName,
          email: email,
          phone: phone,
          password: password,
          licenseNumber: licenseNumber,
          city: city,
          address: address,
          latitude: latitude,
          longitude: longitude,
        );

        // NE PAS stocker le token après inscription
        // Le compte doit être approuvé par l'admin avant la connexion
        // await localDataSource.cacheToken(remoteAuth.token);
        // await localDataSource.cacheUser(remoteAuth.user);
        // apiClient.setToken(remoteAuth.token);

        return Right(remoteAuth.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(e.errors));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token != null) {
          await remoteDataSource.logout(token);
        }
        await localDataSource.clearAuthData();
        apiClient.clearToken();
        return const Right(null);
      } catch (e) {
        // Even if logout fails on server, clear local data
        await localDataSource.clearAuthData();
        apiClient.clearToken();
        return const Right(null);
      }
    } else {
      // Offline logout - just clear local data
      await localDataSource.clearAuthData();
      apiClient.clearToken();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    if (kDebugMode) debugPrint('👤 [AuthRepository] getCurrentUser() appelé');
    try {
      final token = await localDataSource.getToken();
      if (kDebugMode) debugPrint('👤 [AuthRepository] Token local: ${token != null ? "present" : "null"}');
      
      if (token != null) {
        apiClient.setToken(token);
      }

      final localUser = await localDataSource.getUser();
      if (kDebugMode) debugPrint('👤 [AuthRepository] User local: ${localUser?.email ?? "null"}');
      
      if (localUser != null) {
        if (kDebugMode) debugPrint('👤 [AuthRepository] Retour user depuis cache local');
        return Right(localUser.toEntity());
      }
      
      // If no local user but has token, try fetch from remote
      if (token != null) {
        if (kDebugMode) debugPrint('👤 [AuthRepository] Pas de user local, tentative fetch remote...');
        if (await networkInfo.isConnected) {
          try {
            final remoteUser = await remoteDataSource.getCurrentUser(token);
            await localDataSource.cacheUser(remoteUser);
            if (kDebugMode) debugPrint('👤 [AuthRepository] User récupéré du serveur: ${remoteUser.email}');
            return Right(remoteUser.toEntity());
          } catch (e) {
            if (kDebugMode) debugPrint('❌ [AuthRepository] Échec fetch user remote: $e');
             return Left(ServerFailure('Failed to fetch user profile'));
          }
        }
      }

      if (kDebugMode) debugPrint('👤 [AuthRepository] Pas d\'utilisateur connecté');
      return Left(CacheFailure('No user logged in'));
    } catch (e) {
      if (kDebugMode) debugPrint('💥 [AuthRepository] Exception getCurrentUser: $e');
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async {
    try {
      final hasToken = await localDataSource.hasToken();
      
      if (!hasToken) {
        return const Right(false);
      }

      // Récupérer et définir le token sur l'ApiClient
      final token = await localDataSource.getToken();
      if (token != null) {
        apiClient.setToken(token);
        if (kDebugMode) debugPrint('🔑 [AuthRepository] Token restauré sur ApiClient');
      }

      // Optional: Verify token validity with server if online
      if (await networkInfo.isConnected) {
         try {
           if(token != null){
              await remoteDataSource.getCurrentUser(token);
              return const Right(true);
           }
         } catch(e) {
           // Token invalid
           await localDataSource.clearAuthData();
           apiClient.clearToken();
           return const Right(false);
         }
      }

      return const Right(true);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    try {
      if (!await networkInfo.isConnected) {
        return Left(NetworkFailure('Pas de connexion internet'));
      }
      await remoteDataSource.forgotPassword(email: email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return Left(NetworkFailure('Pas de connexion internet'));
      }
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      await apiClient.put('/pharmacy/profile', data: data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
