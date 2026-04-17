import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../providers/dashboard_tab_provider.dart';
import '../../../core/services/delivery_proof_service.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/delivery.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../core/utils/number_formatter.dart';
import '../common/delivery_photo_capture.dart';
import '../common/signature_pad.dart';
import 'qr_code_scanner.dart';

/// Gère la logique de preuve de livraison : photo, signature, vérification wallet
class DeliveryProofHelper {
  final BuildContext context;
  final WidgetRef ref;
  final Delivery delivery;

  DeliveryProofHelper({
    required this.context,
    required this.ref,
    required this.delivery,
  });

  /// Vérifier le solde avant de permettre la livraison
  Future<bool> checkBalanceForDelivery() async {
    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final result = await walletRepo.canDeliver();

      final bool canDeliver = result['can_deliver'] ?? false;
      final double balance = (result['balance'] ?? 0).toDouble();
      final double required = (result['commission_amount'] ?? 200).toDouble();

      if (!canDeliver) {
        if (!context.mounted) return false;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.orange.shade700,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Solde Insuffisant',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  'Votre solde actuel (${balance.toInt().formatCurrency()}) ne couvre pas la commission de ${required.toInt().formatCurrency()}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.secondaryText, height: 1.4),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rechargez votre wallet pour continuer à livrer.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Plus tard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(dashboardTabProvider.notifier).setTab(3);
                          context.go(AppRoutes.dashboard);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Recharger'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        return false;
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Impossible de vérifier le solde, vérification côté serveur...',
            ),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
      return true;
    }
  }

  /// Dialog pour capturer la preuve de livraison (photo + signature optionnelle)
  Future<Map<String, dynamic>?> showDeliveryProofDialog() async {
    File? photo;
    Uint8List? signature;
    final notesController = TextEditingController();
    final isDark = context.isDark;

    try {
      return await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.verified_outlined,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preuve de livraison',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Client: ${delivery.customerName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '📷 Photo du colis livré',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DeliveryPhotoCapture(
                      initialPhoto: photo,
                      onPhotoChanged: (p) => setState(() => photo = p),
                      required: false,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '✍️ Signature du client (optionnel)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (signature == null)
                          TextButton.icon(
                            onPressed: () async {
                              final sig = await SignatureDialog.show(
                                context,
                                title: 'Signature du client',
                                subtitle: delivery.customerName,
                              );
                              if (sig != null) setState(() => signature = sig);
                            },
                            icon: const Icon(Icons.draw, size: 18),
                            label: const Text('Signer'),
                          ),
                      ],
                    ),
                    if (signature != null)
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.memory(
                                signature!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              onPressed: () => setState(() => signature = null),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Text(
                      '📝 Notes (optionnel)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ex: Colis laissé à la réception...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, null),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context, {
                              'photo': photo,
                              'signature': signature,
                              'notes': notesController.text.trim(),
                            }),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Continuer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 10,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      notesController.dispose();
    }
  }

  /// Upload la preuve de livraison (avec fallback offline)
  Future<void> uploadProof({
    required int deliveryId,
    File? photo,
    Uint8List? signatureBytes,
  }) async {
    if (photo == null && signatureBytes == null) return;

    try {
      final proofService = ref.read(deliveryProofServiceProvider);
      await proofService.uploadProof(
        deliveryId: deliveryId,
        proof: DeliveryProof(photo: photo, signatureBytes: signatureBytes),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Proof upload failed, queuing offline: $e');
      }
      try {
        String? photoBase64;
        String? signatureBase64;
        if (photo != null) {
          photoBase64 = base64Encode(await photo.readAsBytes());
        }
        if (signatureBytes != null) {
          signatureBase64 = base64Encode(signatureBytes);
        }
        await OfflineService.instance.addPendingProof(
          deliveryId: deliveryId,
          photoBase64: photoBase64,
          signatureBase64: signatureBase64,
        );
        if (kDebugMode) {
          debugPrint('💾 Proof queued offline for delivery #$deliveryId');
        }
      } catch (offlineError) {
        if (kDebugMode) {
          debugPrint('❌ Failed to queue proof offline: $offlineError');
        }
      }
    }
  }

  /// Afficher le dialog de confirmation (code + QR)
  Future<String?> showConfirmationDialog() async {
    return DeliveryConfirmationDialog.show(context, deliveryId: delivery.id);
  }
}
