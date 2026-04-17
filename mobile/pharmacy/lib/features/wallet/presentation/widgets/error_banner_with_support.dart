import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/support_helper.dart';

// =============================================================================
// ERROR BANNER - Bannière d'erreur inline avec action support
// =============================================================================

/// Bannière d'erreur inline avec bouton support intégré.
///
/// Utilisation:
/// ```dart
/// if (errorMessage != null)
///   ErrorBannerWithSupport(
///     message: errorMessage!,
///     onDismiss: () => setState(() => errorMessage = null),
///   ),
/// ```
class ErrorBannerWithSupport extends StatelessWidget {
  const ErrorBannerWithSupport({
    super.key,
    required this.message,
    this.errorCode,
    this.onDismiss,
    this.showSupportButton = true,
  });

  /// Message d'erreur à afficher
  final String message;

  /// Code d'erreur optionnel (affiché en petit et inclus dans le message support)
  final String? errorCode;

  /// Callback pour fermer la bannière
  final VoidCallback? onDismiss;

  /// Afficher le bouton "Support" (défaut: true)
  final bool showSupportButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ligne principale: icône + message + close
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (errorCode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Code: $errorCode',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDismiss != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDismiss!();
                    },
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.red.shade400, size: 18),
                    ),
                  ),
                ),
            ],
          ),

          // Bouton support si l'erreur semble critique
          if (showSupportButton && _shouldShowSupportButton(message)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _contactSupport(context),
                icon: const Icon(Icons.headset_mic_rounded, size: 16),
                label: const Text('Contacter le support'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Déterminer si on doit afficher le bouton support
  /// (pour les erreurs critiques ou non explicatives)
  bool _shouldShowSupportButton(String msg) {
    final lower = msg.toLowerCase();
    // Afficher support pour erreurs serveur, session, ou génériques
    return lower.contains('support') ||
        lower.contains('serveur') ||
        lower.contains('erreur est survenue') ||
        lower.contains('session') ||
        lower.contains('autorisé') ||
        lower.contains('bloqué') ||
        lower.contains('maintenance');
  }

  void _contactSupport(BuildContext context) {
    SupportHelper.contactSupportWithError(
      errorCode: errorCode,
      errorMessage: message,
      details: 'Depuis l\'écran de retrait',
    );
  }
}

// =============================================================================
// ERROR MESSAGE PARSER - Parse et catégorise les erreurs
// =============================================================================

/// Résultat du parsing d'erreur avec message et code
class ParsedError {
  final String message;
  final String? code;
  final ErrorSeverity severity;

  const ParsedError({
    required this.message,
    this.code,
    this.severity = ErrorSeverity.normal,
  });
}

/// Niveau de sévérité de l'erreur
enum ErrorSeverity {
  /// Erreur normale, réessayable
  normal,

  /// Erreur critique nécessitant support
  critical,

  /// Erreur de session/auth
  auth,
}

/// Parse une erreur brute en message user-friendly avec métadonnées
ParsedError parseWalletError(String error) {
  final errorLower = error.toLowerCase();

  // ===== ERREURS PIN =====
  if (errorLower.contains('pin_invalid') ||
      errorLower.contains('pin incorrect') ||
      errorLower.contains('wrong pin') ||
      errorLower.contains('invalid pin')) {
    final match = RegExp(r'(\d+)\s*tentative').firstMatch(error);
    if (match != null) {
      return ParsedError(
        message: 'Code PIN incorrect. Il vous reste ${match.group(1)} tentative(s).',
        code: 'PIN_INVALID',
      );
    }
    return const ParsedError(
      message: 'Code PIN incorrect. Vérifiez votre code et réessayez.',
      code: 'PIN_INVALID',
    );
  }

  if (errorLower.contains('pin_locked') ||
      errorLower.contains('verrouillé') ||
      errorLower.contains('locked') ||
      errorLower.contains('bloqué')) {
    return const ParsedError(
      message: 'Compte temporairement bloqué suite à plusieurs tentatives incorrectes. '
          'Utilisez "PIN oublié ?" pour réinitialiser.',
      code: 'PIN_LOCKED',
      severity: ErrorSeverity.critical,
    );
  }

  if (errorLower.contains('pin_not_configured') ||
      errorLower.contains('configurer un code pin')) {
    return const ParsedError(
      message: 'Vous devez d\'abord configurer votre code PIN pour effectuer un retrait.',
      code: 'PIN_NOT_CONFIGURED',
    );
  }

  // ===== ERREURS SOLDE =====
  if (errorLower.contains('insufficient') ||
      errorLower.contains('insuffisant') ||
      errorLower.contains('solde')) {
    return const ParsedError(
      message: 'Solde insuffisant pour effectuer ce retrait.',
      code: 'INSUFFICIENT_BALANCE',
    );
  }

  if (errorLower.contains('minimum')) {
    return const ParsedError(
      message: 'Le montant minimum de retrait est de 1 000 FCFA.',
      code: 'MIN_AMOUNT',
    );
  }

  if (errorLower.contains('maximum') ||
      errorLower.contains('limit') ||
      errorLower.contains('plafond')) {
    return const ParsedError(
      message: 'Vous avez atteint la limite de retrait. Réessayez plus tard.',
      code: 'MAX_LIMIT',
    );
  }

  // ===== ERREURS TÉLÉPHONE =====
  if (errorLower.contains('phone') ||
      errorLower.contains('numéro') ||
      errorLower.contains('téléphone')) {
    return const ParsedError(
      message: 'Le numéro de téléphone saisi est invalide.',
      code: 'INVALID_PHONE',
    );
  }

  // ===== ERREURS RÉSEAU =====
  if (errorLower.contains('network') ||
      errorLower.contains('connection') ||
      errorLower.contains('timeout') ||
      errorLower.contains('socket') ||
      errorLower.contains('internet') ||
      errorLower.contains('offline')) {
    return const ParsedError(
      message: 'Problème de connexion internet. Vérifiez votre réseau et réessayez.',
      code: 'NETWORK_ERROR',
    );
  }

  // ===== ERREURS SERVEUR =====
  if (errorLower.contains('500') ||
      errorLower.contains('server error') ||
      errorLower.contains('internal')) {
    return const ParsedError(
      message: 'Le serveur rencontre un problème temporaire. Réessayez dans quelques minutes.',
      code: 'SERVER_ERROR',
      severity: ErrorSeverity.critical,
    );
  }

  if (errorLower.contains('503') ||
      errorLower.contains('unavailable') ||
      errorLower.contains('maintenance')) {
    return const ParsedError(
      message: 'Service en maintenance. Réessayez plus tard.',
      code: 'SERVICE_UNAVAILABLE',
      severity: ErrorSeverity.critical,
    );
  }

  // ===== ERREURS AUTH =====
  if (errorLower.contains('401') ||
      errorLower.contains('unauthenticated') ||
      errorLower.contains('session')) {
    return const ParsedError(
      message: 'Votre session a expiré. Veuillez vous reconnecter.',
      code: 'SESSION_EXPIRED',
      severity: ErrorSeverity.auth,
    );
  }

  if (errorLower.contains('403') ||
      errorLower.contains('forbidden') ||
      errorLower.contains('non autorisé')) {
    return const ParsedError(
      message: 'Vous n\'êtes pas autorisé à effectuer cette opération.',
      code: 'FORBIDDEN',
      severity: ErrorSeverity.critical,
    );
  }

  // ===== ERREURS VALIDATION =====
  if (errorLower.contains('400') ||
      errorLower.contains('422') ||
      errorLower.contains('validation') ||
      errorLower.contains('invalid')) {
    return const ParsedError(
      message: 'Les informations saisies sont incorrectes. Vérifiez et réessayez.',
      code: 'VALIDATION_ERROR',
    );
  }

  // ===== ERREURS PAIEMENT =====
  if (errorLower.contains('payment') ||
      errorLower.contains('transaction') ||
      errorLower.contains('failed')) {
    return const ParsedError(
      message: 'La transaction a échoué. Veuillez réessayer.',
      code: 'PAYMENT_FAILED',
    );
  }

  if (errorLower.contains('pending') || errorLower.contains('en attente')) {
    return const ParsedError(
      message: 'Vous avez déjà une demande de retrait en cours de traitement.',
      code: 'PENDING_WITHDRAWAL',
    );
  }

  // Message générique
  return const ParsedError(
    message: 'Une erreur est survenue. Veuillez réessayer ou contacter le support.',
    code: 'UNKNOWN',
    severity: ErrorSeverity.critical,
  );
}
