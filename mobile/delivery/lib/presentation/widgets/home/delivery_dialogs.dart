import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/snackbar_extension.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../providers/delivery_providers.dart';
import '../../screens/rating_screen.dart';

/// Dialogs liés aux livraisons (confirmation de livraison, succès)
class DeliveryDialogs {
  DeliveryDialogs._();

  /// Affiche le dialog de confirmation avec code OTP
  static void showConfirmation(
    BuildContext context,
    WidgetRef ref,
    int deliveryId, {
    String? customerName,
    String? customerAddress,
    double? deliveryFee,
    double? commission,
  }) {
    final TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Code de confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Demandez le code au client pour valider la livraison.'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.r.sp(24), letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: '0000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = otpController.text.trim();
              if (code.length != 4) {
                context.showWarning('Le code doit contenir 4 chiffres');
                return;
              }

              try {
                await ref
                    .read(deliveryRepositoryProvider)
                    .completeDelivery(deliveryId, code);

                if (ctx.mounted) Navigator.pop(ctx);

                ref.invalidate(deliveriesProvider('active'));
                ref.invalidate(deliveriesProvider('history'));

                if (context.mounted) {
                  showSuccess(
                    context,
                    commission: commission?.toInt() ?? 200,
                    earnings: deliveryFee,
                    deliveryId: deliveryId,
                    customerName: customerName,
                    customerAddress: customerAddress,
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(userFriendlyError(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('VALIDER'),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialog de succès après une livraison
  static void showSuccess(
    BuildContext context, {
    int commission = 200,
    double? earnings,
    int? deliveryId,
    String? customerName,
    String? customerAddress,
  }) {
    final netGain = earnings != null ? (earnings - commission) : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Livraison Terminée !',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),

            // Résumé financier clair
            if (netGain != null && netGain > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gain livraison',
                          style: TextStyle(color: context.secondaryText),
                        ),
                        Text(
                          '+${earnings!.formatCurrency(symbol: 'F')}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Commission',
                          style: TextStyle(color: context.secondaryText),
                        ),
                        Text(
                          '-${commission.toDouble().formatCurrency(symbol: 'F')}',
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Net pour vous',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '+${netGain.formatCurrency(symbol: 'F')}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'La commission de $commission FCFA a été déduite de votre wallet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.secondaryText, height: 1.4),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (deliveryId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RatingScreen(
                          deliveryId: deliveryId,
                          customerName: customerName ?? 'Client',
                          customerAddress: customerAddress,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  deliveryId != null ? 'ÉVALUER LE CLIENT' : 'CONTINUER',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (deliveryId != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Passer',
                  style: TextStyle(color: context.secondaryText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
