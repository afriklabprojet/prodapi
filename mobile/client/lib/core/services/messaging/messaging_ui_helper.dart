import 'package:flutter/material.dart';

import 'messaging_service.dart';

/// UI-layer helper for [MessagingService].
///
/// This is the **only** file in the messaging module that depends on
/// BuildContext / Flutter widgets. Everything else is pure Dart.
abstract final class MessagingUiHelper {
  /// Send a message via [MessagingService] and show a SnackBar on failure.
  ///
  /// Returns the [MessagingResult] on success, or `null` if all channels
  /// failed (after showing the error SnackBar).
  static Future<MessagingResult?> sendWithFeedback({
    required BuildContext context,
    required Future<dynamic> Function() action,
    String errorMessage = 'Impossible d\'ouvrir la messagerie',
    String emptyNumberMessage = 'Numéro non disponible',
  }) async {
    final either = await action();

    // `action` returns Either<Failure, MessagingResult>
    return either.fold(
      (failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message ?? errorMessage),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return null;
      },
      (MessagingResult result) {
        if (!result.isSuccess && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return result;
      },
    );
  }

  /// Show a channel picker bottom sheet when multiple channels are available.
  /// Returns the chosen channel name, or `null` if dismissed.
  static Future<String?> showChannelPicker(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choisir un canal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
              title: const Text('WhatsApp'),
              subtitle: const Text('Messagerie instantanée'),
              onTap: () => Navigator.pop(ctx, 'whatsapp'),
            ),
            ListTile(
              leading: Icon(Icons.sms, color: Colors.blue.shade600),
              title: const Text('SMS'),
              subtitle: const Text('Message texte classique'),
              onTap: () => Navigator.pop(ctx, 'sms'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
