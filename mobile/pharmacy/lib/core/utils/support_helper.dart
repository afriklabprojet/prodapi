import 'package:flutter/material.dart';
import '../services/whatsapp_service.dart';

// =============================================================================
// SUPPORT HELPER - Utilitaires pour contacter le support depuis les erreurs
// =============================================================================

/// Helper pour faciliter le contact support depuis n'importe quel écran.
///
/// Utilisation typique dans les error handlers:
/// ```dart
/// SupportHelper.showErrorWithSupport(
///   context,
///   message: 'Erreur lors du retrait',
///   errorCode: 'WITHDRAW_001',
/// );
/// ```
class SupportHelper {
  SupportHelper._();

  // ===========================================================================
  // SNACKBARS AVEC ACTION SUPPORT
  // ===========================================================================

  /// Affiche un snackbar d'erreur avec bouton "Contacter support"
  static void showErrorWithSupport(
    BuildContext context, {
    required String message,
    String? errorCode,
    String? details,
    Duration duration = const Duration(seconds: 8),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (errorCode != null)
                    Text(
                      'Code: $errorCode',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Support',
          textColor: Colors.white,
          onPressed: () => contactSupportWithError(
            errorCode: errorCode,
            errorMessage: message,
            details: details,
          ),
        ),
      ),
    );
  }

  /// Affiche un dialog d'erreur avec boutons "Réessayer" et "Contacter support"
  static Future<bool?> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? errorCode,
    String? details,
    VoidCallback? onRetry,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.error_outline_rounded,
          color: Colors.red.shade400,
          size: 48,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (errorCode != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Code: $errorCode',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Fermer'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx, false);
              contactSupportWithError(
                errorCode: errorCode,
                errorMessage: message,
                details: details,
              );
            },
            icon: const Icon(Icons.headset_mic_rounded, size: 18),
            label: const Text('Support'),
          ),
          if (onRetry != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx, true);
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CONTACT SUPPORT
  // ===========================================================================

  /// Ouvre WhatsApp avec un message pré-rempli incluant le code d'erreur
  static Future<bool> contactSupportWithError({
    String? errorCode,
    String? errorMessage,
    String? details,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Bonjour, je suis pharmacien partenaire DR-PHARMA.');
    buffer.writeln();
    buffer.writeln('J\'ai rencontré un problème dans l\'application :');

    if (errorMessage != null) {
      buffer.writeln('• Erreur : $errorMessage');
    }
    if (errorCode != null) {
      buffer.writeln('• Code : $errorCode');
    }
    if (details != null) {
      buffer.writeln('• Détails : $details');
    }

    buffer.writeln();
    buffer.writeln('Pouvez-vous m\'aider ?');

    return WhatsAppService.contactSupport(message: buffer.toString());
  }

  /// Ouvre WhatsApp pour une question générale
  static Future<bool> contactSupportGeneral() {
    return WhatsAppService.contactSupport();
  }

  // ===========================================================================
  // BOUTON SUPPORT RÉUTILISABLE
  // ===========================================================================

  /// Widget bouton "Contacter le support" stylisé
  static Widget supportButton({
    VoidCallback? onPressed,
    String label = 'Contacter le support',
    bool outlined = false,
  }) {
    final callback = onPressed ?? () => contactSupportGeneral();

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: callback,
        icon: const Icon(Icons.headset_mic_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green.shade700,
          side: BorderSide(color: Colors.green.shade700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: callback,
      icon: const Icon(Icons.headset_mic_rounded, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
