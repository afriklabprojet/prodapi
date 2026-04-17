import 'failures.dart';

/// ─────────────────────────────────────────────────────────
/// Auth-specific Failures
/// Gestion granulaire des erreurs d'authentification
/// ─────────────────────────────────────────────────────────

/// Identifiants invalides (email/téléphone ou mot de passe incorrect)
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'Identifiants incorrects. Vérifiez votre email/téléphone et mot de passe.',
  });
}

/// Compte non trouvé
class AccountNotFoundFailure extends Failure {
  const AccountNotFoundFailure({
    super.message = 'Aucun compte trouvé avec cet identifiant.',
  });
}

/// Compte bloqué (trop de tentatives, etc.)
class AccountLockedFailure extends Failure {
  final Duration? lockDuration;
  
  const AccountLockedFailure({
    super.message = 'Compte temporairement bloqué. Réessayez plus tard.',
    this.lockDuration,
  });

  @override
  List<Object?> get props => [message, lockDuration];
}

/// ─────────────────────────────────────────────────────────
/// OTP Failures
/// ─────────────────────────────────────────────────────────

/// Code OTP incorrect
class InvalidOtpFailure extends Failure {
  final int? attemptsRemaining;
  
  const InvalidOtpFailure({
    super.message = 'Code incorrect. Veuillez vérifier et réessayer.',
    this.attemptsRemaining,
  });

  @override
  List<Object?> get props => [message, attemptsRemaining];
}

/// Code OTP expiré
class ExpiredOtpFailure extends Failure {
  const ExpiredOtpFailure({
    super.message = 'Code expiré. Demandez un nouveau code.',
  });
}

/// Trop de tentatives OTP
class TooManyOtpAttemptsFailure extends Failure {
  final Duration? retryAfter;
  
  const TooManyOtpAttemptsFailure({
    super.message = 'Vous avez fait trop de demandes de code.\n\nPour des raisons de sécurité, veuillez patienter 5 à 15 minutes avant de réessayer.',
    this.retryAfter,
  });

  @override
  List<Object?> get props => [message, retryAfter];
}

/// Échec d'envoi OTP
class OtpSendFailure extends Failure {
  final OtpSendError reason;
  
  const OtpSendFailure({
    super.message = 'Impossible d\'envoyer le code.',
    this.reason = OtpSendError.unknown,
  });

  @override
  List<Object?> get props => [message, reason];
}

enum OtpSendError {
  invalidPhoneNumber,
  quotaExceeded,
  serviceUnavailable,
  unknown,
}

/// ─────────────────────────────────────────────────────────
/// Session Failures
/// ─────────────────────────────────────────────────────────

/// Session expirée
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure({
    super.message = 'Votre session a expiré. Veuillez vous reconnecter.',
  });
}

/// Token invalide
class InvalidTokenFailure extends Failure {
  const InvalidTokenFailure({
    super.message = 'Session invalide. Veuillez vous reconnecter.',
  });
}

/// Refresh token expiré
class RefreshTokenExpiredFailure extends Failure {
  const RefreshTokenExpiredFailure({
    super.message = 'Session prolongée expirée. Veuillez vous reconnecter.',
  });
}

/// ─────────────────────────────────────────────────────────
/// Phone Verification Failures
/// ─────────────────────────────────────────────────────────

/// Téléphone non vérifié
class PhoneNotVerifiedFailure extends Failure {
  final String phone;
  
  const PhoneNotVerifiedFailure({
    super.message = 'Numéro de téléphone non vérifié.',
    required this.phone,
  });

  @override
  List<Object?> get props => [message, phone];
}

/// ─────────────────────────────────────────────────────────
/// Registration Failures  
/// ─────────────────────────────────────────────────────────

/// Email déjà utilisé
class EmailAlreadyExistsFailure extends Failure {
  const EmailAlreadyExistsFailure({
    super.message = 'Cette adresse email est déjà utilisée.',
  });
}

/// Téléphone déjà utilisé
class PhoneAlreadyExistsFailure extends Failure {
  const PhoneAlreadyExistsFailure({
    super.message = 'Ce numéro de téléphone est déjà utilisé.',
  });
}
