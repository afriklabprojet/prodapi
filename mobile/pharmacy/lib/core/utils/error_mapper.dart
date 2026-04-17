import 'error_translator.dart';

/// Mapper les codes d'erreur API vers des messages utilisateur lisibles.
class ErrorMapper {
  ErrorMapper._();

  /// Formate un message d'erreur à partir du code erreur et du message serveur.
  static String format(String? errorCode, String? serverMessage) {
    // Priorité au code d'erreur structuré
    if (errorCode != null) {
      final mapped = _mapErrorCode(errorCode);
      if (mapped != null) return mapped;
    }

    // Sinon on utilise le message serveur traduit en français
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return ErrorTranslator.toFrench(serverMessage);
    }

    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  static String? _mapErrorCode(String code) {
    switch (code) {
      case 'ACCOUNT_PENDING':
        return 'Votre compte est en cours de vérification. Vous serez notifié dès son approbation.';
      case 'ACCOUNT_SUSPENDED':
        return 'Votre compte a été suspendu. Contactez le support pour plus d\'informations.';
      case 'ACCOUNT_REJECTED':
        return 'Votre demande d\'inscription a été rejetée. Contactez le support.';
      case 'ACCOUNT_NOT_APPROVED':
        return 'Votre compte n\'est pas encore approuvé.';
      case 'INVALID_CREDENTIALS':
        return 'Identifiants incorrects. Vérifiez votre numéro et mot de passe.';
      case 'TOKEN_EXPIRED':
        return 'Votre session a expiré. Veuillez vous reconnecter.';
      case 'TOKEN_INVALID':
        return 'Session invalide. Veuillez vous reconnecter.';
      case 'PHONE_NOT_VERIFIED':
        return 'Votre numéro n\'est pas vérifié. Veuillez le vérifier d\'abord.';
      case 'OTP_INVALID':
        return 'Code de vérification invalide.';
      case 'OTP_EXPIRED':
        return 'Le code de vérification a expiré. Demandez un nouveau code.';
      case 'RATE_LIMITED':
        return 'Trop de tentatives. Veuillez patienter quelques minutes.';
      default:
        return null;
    }
  }
}
