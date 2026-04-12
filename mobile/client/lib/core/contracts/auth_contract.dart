import 'package:dartz/dartz.dart';
import '../errors/failures.dart';
import '../../features/auth/domain/entities/user_entity.dart';

/// Contract définissant les capacités d'authentification
/// Permet le découplage et facilite les tests
abstract class AuthContract {
  /// État de l'authentification en temps réel
  Stream<AuthStatus> get authStateStream;

  /// Utilisateur courant (null si non connecté)
  UserEntity? get currentUser;

  /// Token d'accès actuel (synchrone, cache)
  String? get accessToken;

  /// Login par email/password ou phone/password (auto-détection)
  Future<Either<Failure, AuthResult>> loginWithCredentials({
    required String identifier,
    required String password,
  });

  /// Initier OTP (envoie le code)
  Future<Either<Failure, OtpSession>> initiateOtp({
    required String phone,
    OtpChannel channel = OtpChannel.sms,
  });

  /// Vérifier OTP
  Future<Either<Failure, AuthResult>> verifyOtp({
    required String verificationId,
    required String code,
  });

  /// Rafraîchir le token
  Future<Either<Failure, AuthResult>> refreshToken();

  /// Déconnexion
  Future<Either<Failure, Unit>> logout();

  /// Restaurer la session depuis le stockage local
  Future<Either<Failure, AuthResult>> restoreSession();

  /// Vérifier si une session est valide
  Future<bool> isSessionValid();
  
  /// Dispose des ressources
  void dispose();
}

/// Statuts possibles de l'authentification
enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  sessionExpired,
}

/// Canal pour l'envoi OTP
enum OtpChannel { sms, whatsapp, firebase }

/// Résultat d'une authentification réussie
class AuthResult {
  final UserEntity user;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthResult({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });
}

/// Session OTP en cours
class OtpSession {
  final String verificationId;
  final DateTime expiresAt;
  final int resendAfterSeconds;

  const OtpSession({
    required this.verificationId,
    required this.expiresAt,
    required this.resendAfterSeconds,
  });
}
