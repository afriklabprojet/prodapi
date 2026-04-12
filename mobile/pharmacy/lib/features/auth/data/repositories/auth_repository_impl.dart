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
import '../models/auth_response_model.dart';

/// Implémentation du repository d'authentification.
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

  // ============================================================
  // HELPERS
  // ============================================================

  void _log(String message) {
    if (kDebugMode) debugPrint('[AuthRepo] $message');
  }

  /// Vérifie la connexion réseau et retourne une Failure si non connecté.
  Future<Failure?> _checkNetwork() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) return NetworkFailure('No internet connection');
    return null;
  }

  /// Sauvegarde les données d'authentification localement et met à jour l'ApiClient.
  Future<void> _saveAuth(AuthResponseModel auth) async {
    await localDataSource.cacheToken(auth.token);
    await localDataSource.cacheUser(auth.user);
    _log('✅ Token et user mis en cache');
  }

  /// Mappe les exceptions vers les Failures appropriées.
  Failure _mapException(Object error) {
    return switch (error) {
      ServerException e => ServerFailure(e.message),
      UnauthorizedException e => UnauthorizedFailure(e.message),
      ForbiddenException e => ForbiddenFailure(
        e.message,
        errorCode: e.errorCode,
      ),
      ValidationException e => ValidationFailure(e.errors),
      _ => ServerFailure(error.toString()),
    };
  }

  // ============================================================
  // LOGIN
  // ============================================================

  @override
  Future<Either<Failure, AuthResponseEntity>> login({
    required String email,
    required String password,
  }) async {
    _log('🔑 login($email)');

    final networkError = await _checkNetwork();
    if (networkError != null) return Left(networkError);

    try {
      final auth = await remoteDataSource.login(
        email: email,
        password: password,
      );
      await _saveAuth(auth);
      return Right(auth.toEntity());
    } catch (e, stack) {
      _log('❌ login error: $e');
      if (kDebugMode) debugPrint('$stack');
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> loginWithBiometric({
    required String email,
  }) async {
    _log('🔐 loginWithBiometric($email)');

    final networkError = await _checkNetwork();
    if (networkError != null) return Left(networkError);

    try {
      final cachedToken = await localDataSource.getToken();
      if (cachedToken == null || cachedToken.isEmpty) {
        return Left(
          UnauthorizedFailure(
            'Veuillez vous connecter d\'abord avec email et mot de passe',
          ),
        );
      }

      final auth = await remoteDataSource.refreshSession(token: cachedToken);
      await _saveAuth(auth);
      _log('✅ Biometric login OK');
      return Right(auth.toEntity());
    } on UnauthorizedException {
      return Left(
        UnauthorizedFailure(
          'Session expirée. Veuillez vous reconnecter avec votre mot de passe.',
        ),
      );
    } catch (e) {
      _log('❌ Biometric error: $e');
      return Left(ServerFailure('Erreur de connexion biométrique'));
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

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
    _log('📝 register($email)');

    final networkError = await _checkNetwork();
    if (networkError != null) return Left(networkError);

    try {
      final auth = await remoteDataSource.register(
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
      // NE PAS stocker le token - le compte doit être approuvé par l'admin
      return Right(auth.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  @override
  Future<Either<Failure, void>> logout() async {
    _log('🚪 logout()');
    try {
      if (await networkInfo.isConnected) {
        final token = await localDataSource.getToken();
        if (token != null) {
          await remoteDataSource.logout(token);
        }
      }
    } catch (_) {
      // Ignore server errors - always clear local data
    }
    await localDataSource.clearAuthData();
    return const Right(null);
  }

  // ============================================================
  // USER
  // ============================================================

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    _log('👤 getCurrentUser()');
    try {
      final token = await localDataSource.getToken();

      // 1. Try local cache first
      final localUser = await localDataSource.getUser();
      if (localUser != null) {
        _log('👤 User from cache: ${localUser.email}');
        return Right(localUser.toEntity());
      }

      // 2. If token exists, try remote
      if (token != null && await networkInfo.isConnected) {
        try {
          final remoteUser = await remoteDataSource.getCurrentUser(token);
          await localDataSource.cacheUser(remoteUser);
          _log('👤 User from server: ${remoteUser.email}');
          return Right(remoteUser.toEntity());
        } catch (e) {
          _log('❌ Remote user fetch failed: $e');
          return Left(ServerFailure('Failed to fetch user profile'));
        }
      }

      return Left(CacheFailure('No user logged in'));
    } catch (e) {
      _log('❌ getCurrentUser error: $e');
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async {
    try {
      final hasToken = await localDataSource.hasToken();
      if (!hasToken) return const Right(false);

      final token = await localDataSource.getToken();
      if (token != null) {
        _log('🔑 Token restauré');
      }

      // Verify token with server if online
      if (await networkInfo.isConnected && token != null) {
        try {
          await remoteDataSource.getCurrentUser(token);
          return const Right(true);
        } catch (_) {
          // Token invalid - clear
          await localDataSource.clearAuthData();
          return const Right(false);
        }
      }

      return const Right(true);
    } catch (_) {
      return const Right(false);
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    _log('🔑 forgotPassword($email)');

    final networkError = await _checkNetwork();
    if (networkError != null) return Left(networkError);

    try {
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
    _log('✏️ updateProfile()');

    final networkError = await _checkNetwork();
    if (networkError != null) return Left(networkError);

    try {
      final data = <String, dynamic>{
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };
      await apiClient.put('/pharmacy/profile', data: data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
