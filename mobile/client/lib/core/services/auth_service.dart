import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/auth_contract.dart';
import '../errors/failures.dart';
import '../errors/auth_failures.dart';
import '../services/app_logger.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/domain/entities/user_entity.dart';

/// ─────────────────────────────────────────────────────────
/// AuthService — Production-Ready Authentication
/// ─────────────────────────────────────────────────────────
///
/// Features:
/// - Login with email OR phone (auto-detection)
/// - OTP verification with configurable timeout
/// - Secure session persistence (token + user)
/// - Session restoration at startup
/// - Real-time auth state stream
/// - Comprehensive error handling
///
/// Usage:
/// ```dart
/// final authService = ref.watch(authServiceProvider);
///
/// // Listen to auth state changes
/// authService.authStateStream.listen((status) {
///   if (status == AuthStatus.unauthenticated) {
///     // Redirect to login
///   }
/// });
///
/// // Login
/// final result = await authService.loginWithCredentials(
///   identifier: 'user@email.com', // or '+2250700000000'
///   password: 'secret',
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (authResult) => navigateToHome(),
/// );
/// ```
class AuthService implements AuthContract {
  final AuthRemoteDataSource _remoteDataSource;

  /// StreamController pour l'état d'authentification
  final _authStateController = StreamController<AuthStatus>.broadcast();

  /// Cache local de l'utilisateur connecté
  UserEntity? _currentUser;

  /// Cache local du token
  String? _accessToken;

  /// Session OTP en cours
  OtpSession? _currentOtpSession;

  /// Timer pour expiration automatique de l'OTP
  Timer? _otpExpirationTimer;

  /// Configuration du timeout OTP (défaut: 2 minutes)
  final Duration otpTimeout;

  /// Configuration du délai minimum entre deux envois OTP
  final Duration otpResendDelay;

  AuthService({
    required AuthRemoteDataSource remoteDataSource,
    this.otpTimeout = const Duration(minutes: 2),
    this.otpResendDelay = const Duration(seconds: 30),
  }) : _remoteDataSource = remoteDataSource;

  // ─────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────

  @override
  Stream<AuthStatus> get authStateStream => _authStateController.stream;

  @override
  UserEntity? get currentUser => _currentUser;

  @override
  String? get accessToken => _accessToken;

  /// Session OTP active
  OtpSession? get currentOtpSession => _currentOtpSession;

  // ─────────────────────────────────────────────────────────
  // Login with Credentials
  // ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthResult>> loginWithCredentials({
    required String identifier,
    required String password,
  }) async {
    try {
      final normalizedIdentifier = _normalizeIdentifier(identifier);
      final isPhone = _isPhoneNumber(normalizedIdentifier);

      AppLogger.auth(
        '[AuthService] Login attempt with ${isPhone ? 'phone' : 'email'}',
      );

      // L'API backend auto-détecte email vs phone
      final response = await _remoteDataSource.login(
        email: normalizedIdentifier,
        password: password,
      );

      final authResult = AuthResult(
        user: response.user.toEntity(),
        accessToken: response.token,
        refreshToken: null, // API ne retourne pas de refresh token séparé
        expiresAt: null,
      );

      // Persister la session
      await _persistSession(authResult, response.user);

      // Mettre à jour l'état
      _currentUser = response.user.toEntity();
      _accessToken = response.token;
      _emitAuthState(AuthStatus.authenticated);

      AppLogger.auth('[AuthService] Login successful');
      return Right(authResult);
    } on NetworkFailure catch (e) {
      AppLogger.warning('[AuthService] Network error during login', error: e);
      return Left(e);
    } on ValidationFailure catch (e) {
      AppLogger.warning(
        '[AuthService] Validation error during login',
        error: e,
      );
      return Left(InvalidCredentialsFailure(message: e.message));
    } on UnauthorizedFailure {
      return const Left(InvalidCredentialsFailure());
    } on ServerFailure catch (e) {
      // Parse specific error codes from backend
      if (e.statusCode == 401) {
        return const Left(InvalidCredentialsFailure());
      }
      if (e.statusCode == 403) {
        return const Left(AccountLockedFailure());
      }
      if (e.statusCode == 404) {
        return const Left(AccountNotFoundFailure());
      }
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.warning(
        '[AuthService] Unexpected error during login',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure(message: 'Erreur lors de la connexion: $e'));
    }
  }

  // ─────────────────────────────────────────────────────────
  // OTP Flow
  // ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, OtpSession>> initiateOtp({
    required String phone,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    try {
      final normalizedPhone = _normalizePhone(phone);

      AppLogger.auth('[AuthService] Initiating OTP via $channel');

      // Appeler l'API pour envoyer l'OTP
      final response = await _remoteDataSource.resendOtp(
        identifier: normalizedPhone,
      );

      // Créer la session OTP
      final session = OtpSession(
        verificationId: normalizedPhone, // Le phone sert d'ID de vérification
        expiresAt: DateTime.now().add(otpTimeout),
        resendAfterSeconds: otpResendDelay.inSeconds,
      );

      _currentOtpSession = session;
      _startOtpExpirationTimer(session);

      AppLogger.auth(
        '[AuthService] OTP sent successfully. Channel: ${response['channel']}',
      );
      return Right(session);
    } on ServerFailure catch (e) {
      if (e.statusCode == 429) {
        return const Left(TooManyOtpAttemptsFailure());
      }
      if (e.message.contains('invalid') || e.message.contains('numéro')) {
        return const Left(
          OtpSendFailure(
            message: 'Numéro de téléphone invalide.',
            reason: OtpSendError.invalidPhoneNumber,
          ),
        );
      }
      return Left(OtpSendFailure(message: e.message));
    } on NetworkFailure catch (e) {
      return Left(
        OtpSendFailure(
          message: e.message,
          reason: OtpSendError.serviceUnavailable,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        '[AuthService] Error initiating OTP',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(OtpSendFailure(message: 'Impossible d\'envoyer le code: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    try {
      // Vérifier si l'OTP n'est pas expiré
      if (_currentOtpSession != null) {
        if (DateTime.now().isAfter(_currentOtpSession!.expiresAt)) {
          _clearOtpSession();
          return const Left(ExpiredOtpFailure());
        }
      }

      AppLogger.auth('[AuthService] Verifying OTP');

      final response = await _remoteDataSource.verifyOtp(
        identifier: verificationId,
        otp: code,
      );

      final authResult = AuthResult(
        user: response.user.toEntity(),
        accessToken: response.token,
        refreshToken: null,
        expiresAt: null,
      );

      // Persister la session
      await _persistSession(authResult, response.user);

      // Mettre à jour l'état
      _currentUser = response.user.toEntity();
      _accessToken = response.token;
      _clearOtpSession();
      _emitAuthState(AuthStatus.authenticated);

      AppLogger.auth('[AuthService] OTP verified successfully');
      return Right(authResult);
    } on ValidationFailure catch (e) {
      // Code invalide
      AppLogger.warning('[AuthService] Invalid OTP code', error: e);
      return Left(InvalidOtpFailure(message: e.message));
    } on ServerFailure catch (e) {
      if (e.statusCode == 400 || e.statusCode == 422) {
        // Check specific error messages
        if (e.message.toLowerCase().contains('expir')) {
          _clearOtpSession();
          return const Left(ExpiredOtpFailure());
        }
        return Left(InvalidOtpFailure(message: e.message));
      }
      if (e.statusCode == 429) {
        return const Left(TooManyOtpAttemptsFailure());
      }
      return Left(e);
    } on NetworkFailure catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.warning(
        '[AuthService] Error verifying OTP',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure(message: 'Erreur de vérification: $e'));
    }
  }

  // ─────────────────────────────────────────────────────────
  // Session Management
  // ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthResult>> restoreSession() async {
    try {
      AppLogger.auth('[AuthService] Restoring session');

      // Récupérer le token depuis le stockage sécurisé
      final token = await SecureStorageService.getToken();
      if (token == null || token.isEmpty) {
        AppLogger.auth('[AuthService] No stored token found');
        _emitAuthState(AuthStatus.unauthenticated);
        return const Left(
          SessionExpiredFailure(message: 'Aucune session trouvée.'),
        );
      }

      // Valider le token avec l'API
      try {
        final userModel = await _remoteDataSource.getCurrentUser(token);
        final userEntity = userModel.toEntity();

        final authResult = AuthResult(
          user: userEntity,
          accessToken: token,
          refreshToken: null,
          expiresAt: null,
        );

        // Mettre à jour le cache avec les données fraîches
        await _persistSession(authResult, userModel);

        _currentUser = userEntity;
        _accessToken = token;
        _emitAuthState(AuthStatus.authenticated);

        AppLogger.auth('[AuthService] Session restored successfully');
        return Right(authResult);
      } on UnauthorizedFailure {
        // Token invalide ou expiré
        AppLogger.warning('[AuthService] Token invalid or expired');
        await _clearSession();
        _emitAuthState(AuthStatus.sessionExpired);
        return const Left(SessionExpiredFailure());
      }
    } on NetworkFailure catch (e) {
      // Pas de connexion, utiliser le cache si disponible
      final userJson = await SecureStorageService.getCachedUserJson();
      final token = await SecureStorageService.getToken();

      if (userJson != null && token != null) {
        try {
          final cachedUserEntity = UserModel.fromJson(
            jsonDecode(userJson),
          ).toEntity();
          _currentUser = cachedUserEntity;
          _accessToken = token;
          _emitAuthState(AuthStatus.authenticated);

          AppLogger.auth(
            '[AuthService] Session restored from cache (offline mode)',
          );
          return Right(
            AuthResult(
              user: cachedUserEntity,
              accessToken: token,
              refreshToken: null,
              expiresAt: null,
            ),
          );
        } catch (e) {
          AppLogger.debug(
            '[AuthService] Impossible de lire le cache utilisateur: $e',
          );
          // Fall through to error
        }
      }

      _emitAuthState(AuthStatus.unknown);
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.warning(
        '[AuthService] Error restoring session',
        error: e,
        stackTrace: stackTrace,
      );
      _emitAuthState(AuthStatus.unknown);
      return Left(UnknownFailure(message: 'Erreur de restauration: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> refreshToken() async {
    // L'API actuelle n'utilise pas de refresh token séparé
    // Donc on re-valide simplement la session existante
    return restoreSession();
  }

  @override
  Future<bool> isSessionValid() async {
    if (_accessToken == null) {
      final token = await SecureStorageService.getToken();
      if (token == null) return false;
    }

    try {
      await _remoteDataSource.getCurrentUser(_accessToken!);
      return true;
    } catch (e) {
      AppLogger.debug('[AuthService] isSessionValid check failed: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      AppLogger.auth('[AuthService] Logging out');

      // Notifier l'API si on a un token
      if (_accessToken != null) {
        try {
          await _remoteDataSource.logout(_accessToken!);
        } catch (e, stackTrace) {
          // Ignorer les erreurs de logout côté serveur
          AppLogger.warning(
            '[AuthService] Server logout failed (ignored)',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      // Nettoyer la session locale
      await _clearSession();
      _emitAuthState(AuthStatus.unauthenticated);

      AppLogger.auth('[AuthService] Logout complete');
      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.warning(
        '[AuthService] Error during logout',
        error: e,
        stackTrace: stackTrace,
      );
      // Même en cas d'erreur, on nettoie localement
      await _clearSession();
      _emitAuthState(AuthStatus.unauthenticated);
      return const Right(unit);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Dispose
  // ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    AppLogger.auth('[AuthService] Disposing');
    _otpExpirationTimer?.cancel();
    _authStateController.close();
  }

  // ─────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────

  void _emitAuthState(AuthStatus status) {
    if (!_authStateController.isClosed) {
      _authStateController.add(status);
    }
  }

  Future<void> _persistSession(
    AuthResult result, [
    UserModel? userModel,
  ]) async {
    await SecureStorageService.setToken(result.accessToken);
    if (userModel != null) {
      await SecureStorageService.setCachedUserJson(
        jsonEncode(userModel.toJson()),
      );
    }
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    _accessToken = null;
    _clearOtpSession();
    await SecureStorageService.clearAll();
  }

  void _clearOtpSession() {
    _otpExpirationTimer?.cancel();
    _otpExpirationTimer = null;
    _currentOtpSession = null;
  }

  void _startOtpExpirationTimer(OtpSession session) {
    _otpExpirationTimer?.cancel();
    final duration = session.expiresAt.difference(DateTime.now());
    _otpExpirationTimer = Timer(duration, () {
      AppLogger.auth('[AuthService] OTP session expired');
      _clearOtpSession();
    });
  }

  /// Normalise l'identifiant (email ou téléphone)
  String _normalizeIdentifier(String identifier) {
    final trimmed = identifier.trim();

    // Si c'est un email, mettre en minuscules
    if (trimmed.contains('@')) {
      return trimmed.toLowerCase();
    }

    // Si c'est un téléphone, normaliser le format
    return _normalizePhone(trimmed);
  }

  /// Normalise un numéro de téléphone au format +225XXXXXXXXXX
  String _normalizePhone(String phone) {
    // Supprimer les espaces et caractères non numériques (sauf +)
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Ajouter le préfixe +225 si absent
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('225')) {
        cleaned = '+$cleaned';
      } else if (cleaned.startsWith('0')) {
        cleaned = '+225${cleaned.substring(1)}';
      } else {
        cleaned = '+225$cleaned';
      }
    }

    return cleaned;
  }

  /// Détecte si l'identifiant est un numéro de téléphone
  bool _isPhoneNumber(String identifier) {
    // Si ça contient @ c'est un email
    if (identifier.contains('@')) return false;

    // Si ça commence par + ou contient principalement des chiffres
    final digitsOnly = identifier.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.length >= 8;
  }
}

// ─────────────────────────────────────────────────────────
// Riverpod Provider
// ─────────────────────────────────────────────────────────

/// Provider pour AuthService
/// Usage: final authService = ref.watch(authServiceProvider);
final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError(
    'authServiceProvider must be overridden in ProviderScope. '
    'See main.dart for proper initialization.',
  );
});

/// Stream provider pour l'état d'authentification
/// Usage: final authStatus = ref.watch(authStatusStreamProvider);
final authStatusStreamProvider = StreamProvider<AuthStatus>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateStream;
});

/// Provider pour l'utilisateur courant
/// Usage: final user = ref.watch(currentUserProvider);
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});
