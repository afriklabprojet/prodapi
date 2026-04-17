import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_translator.dart';
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
          await fb.FirebaseAuth.instance.signInWithCustomToken(
            result.firebaseToken!,
          );
          debugPrint('🔥 [Firebase Auth] Client connecté');
        } catch (e) {
          debugPrint('⚠️ [Firebase Auth] Erreur signIn: $e');
        }
      }

      return Right(result.toEntity());
    } on ValidationException catch (e) {
      final translated = ErrorTranslator.translateErrors(e.errors);
      String errorMessage = 'Veuillez vérifier les informations saisies.';
      if (translated.isNotEmpty) {
        final firstKey = translated.keys.first;
        if (translated[firstKey]!.isNotEmpty) {
          errorMessage = translated[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: translated));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: 401));
    } catch (e) {
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue. Réessayez.'));
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
      final translated = ErrorTranslator.translateErrors(e.errors);
      String errorMessage = 'Veuillez vérifier les informations saisies.';
      if (translated.isNotEmpty) {
        final firstKey = translated.keys.first;
        if (translated[firstKey]!.isNotEmpty) {
          errorMessage = translated[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: translated));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: 401));
    } catch (e) {
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue. Réessayez.'));
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
      } catch (e) {
        AppLogger.warning(
          '[Auth] Firebase signOut failed (logout still complete)',
          error: e,
        );
      }

      return const Right(null);
    } on ServerException catch (e) {
      // Even if server logout fails, clear local data
      await localDataSource.clearToken();
      await localDataSource.clearUser();
      apiClient.clearToken();
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (e) {
        AppLogger.warning(
          '[Auth] Firebase signOut failed (ServerException path)',
          error: e,
        );
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      // Always clear local data
      await localDataSource.clearToken();
      await localDataSource.clearUser();
      apiClient.clearToken();
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (e) {
        AppLogger.warning(
          '[Auth] Firebase signOut failed (catch-all path)',
          error: e,
        );
      }
      return Left(ServerFailure(message: 'Erreur lors de la déconnexion.'));
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
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
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
      final translated = ErrorTranslator.translateErrors(e.errors);
      String errorMessage = 'Veuillez vérifier les informations saisies.';
      if (translated.isNotEmpty) {
        final firstKey = translated.keys.first;
        if (translated[firstKey]!.isNotEmpty) {
          errorMessage = translated[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: translated));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: 401));
    } catch (e) {
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
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
      final translated = ErrorTranslator.translateErrors(e.errors);
      String errorMessage = 'Code OTP invalide';
      if (translated.isNotEmpty) {
        final firstKey = translated.keys.first;
        if (translated[firstKey]!.isNotEmpty) {
          errorMessage = translated[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: translated));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> verifyFirebaseOtp({
    required String phone,
    required String firebaseUid,
    required String firebaseIdToken,
  }) async {
    try {
      final result = await remoteDataSource.verifyFirebaseOtp(
        phone: phone,
        firebaseUid: firebaseUid,
        firebaseIdToken: firebaseIdToken,
      );

      // Update cached token and user
      await localDataSource.cacheToken(result.token);
      await localDataSource.cacheUser(result.user);

      // Configure ApiClient with the new token
      apiClient.setToken(result.token);

      return Right(result.toEntity());
    } on ValidationException catch (e) {
      final translated = ErrorTranslator.translateErrors(e.errors);
      String errorMessage = 'Vérification Firebase échouée';
      if (translated.isNotEmpty) {
        final firstKey = translated.keys.first;
        if (translated[firstKey]!.isNotEmpty) {
          errorMessage = translated[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: translated));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
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
      return Left(ServerFailure(message: 'Impossible de renvoyer le code. Réessayez.'));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({
    String? email,
    String? phone,
  }) async {
    try {
      await remoteDataSource.forgotPassword(email: email, phone: phone);
      return const Right(null);
    } on ValidationException catch (e) {
      final translated = ErrorTranslator.translateErrors(e.errors);
      String errorMessage = 'Compte non trouvé';
      if (translated.isNotEmpty) {
        final firstKey = translated.keys.first;
        if (translated[firstKey]!.isNotEmpty) {
          errorMessage = translated[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: translated));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyResetOtp({
    String? email,
    String? phone,
    required String otp,
  }) async {
    try {
      await remoteDataSource.verifyResetOtp(
        email: email,
        phone: phone,
        otp: otp,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      final translated = ErrorTranslator.translateErrors(e.errors);
      String errorMessage = 'Code invalide';
      if (translated.isNotEmpty) {
        final firstKey = translated.keys.first;
        if (translated[firstKey]!.isNotEmpty) {
          errorMessage = translated[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: translated));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    String? email,
    String? phone,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await remoteDataSource.resetPassword(
        email: email,
        phone: phone,
        otp: otp,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      final translated = ErrorTranslator.translateErrors(e.errors);
      String errorMessage = 'Erreur de réinitialisation';
      if (translated.isNotEmpty) {
        final firstKey = translated.keys.first;
        if (translated[firstKey]!.isNotEmpty) {
          errorMessage = translated[firstKey]!.first;
        }
      }
      return Left(ValidationFailure(message: errorMessage, errors: translated));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

    try {
      // ── 1. Trigger the Google sign-in flow ──────────────────────────────
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in dialog
        return const Left(ServerFailure(message: 'Connexion Google annulée'));
      }

      // ── 2. Get Google auth tokens and sign into Firebase ─────────────────
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebaseUser = await fb.FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final firebaseIdToken = await firebaseUser.user?.getIdToken();

      if (firebaseIdToken == null) {
        await googleSignIn.signOut();
        return const Left(
          ServerFailure(message: 'Impossible d\'obtenir le token Firebase'),
        );
      }

      // ── 3. Authenticate on the backend ───────────────────────────────────
      final result = await remoteDataSource.loginWithGoogle(
        firebaseIdToken: firebaseIdToken,
      );

      // Cache token and user
      await localDataSource.cacheToken(result.token);
      await localDataSource.cacheUser(result.user);
      apiClient.setToken(result.token);

      return Right(result.toEntity());
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.warning('[Auth] Google Firebase sign-in failed', error: e);
      try {
        await googleSignIn.signOut();
      } catch (signOutError) {
        AppLogger.debug('[Auth] Cleanup signOut failed: $signOutError');
      }
      return Left(ServerFailure(message: e.message ?? 'Erreur Firebase'));
    } on ServerException catch (e) {
      try {
        await googleSignIn.signOut();
      } catch (signOutError) {
        AppLogger.debug('[Auth] Cleanup signOut failed: $signOutError');
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      try {
        await googleSignIn.signOut();
      } catch (signOutError) {
        AppLogger.debug('[Auth] Cleanup signOut failed: $signOutError');
      }
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      try {
        await googleSignIn.signOut();
      } catch (signOutError) {
        AppLogger.debug('[Auth] Cleanup signOut failed: $signOutError');
      }
      return Left(ServerFailure(message: 'Erreur lors de la connexion Google.'));
    }
  }
}
