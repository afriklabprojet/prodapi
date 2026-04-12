import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/services/cache_service.dart';
import '../../core/theme/theme_provider.dart';
import '../providers/wallet_provider.dart';

/// Écran de callback pour les deep links de paiement JEKO.
/// Affiche brièvement le résultat et redirige vers le dashboard.
class PaymentCallbackScreen extends ConsumerStatefulWidget {
  final bool isSuccess;
  final String? reference;
  final String? reason;

  const PaymentCallbackScreen({
    super.key,
    required this.isSuccess,
    this.reference,
    this.reason,
  });

  @override
  ConsumerState<PaymentCallbackScreen> createState() =>
      _PaymentCallbackScreenState();
}

class _PaymentCallbackScreenState extends ConsumerState<PaymentCallbackScreen> {
  @override
  void initState() {
    super.initState();

    // Invalider le cache local ET le provider pour refresh instantané du solde
    CacheService.instance.invalidateWallet();
    ref.invalidate(walletProvider);
    ref.invalidate(walletDataProvider);

    // Feedback haptique
    if (widget.isSuccess) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    // Rediriger vers le dashboard après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: widget.isSuccess ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isSuccess ? Colors.green : Colors.red)
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isSuccess ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 32),

                // Titre
                Text(
                  widget.isSuccess ? 'Paiement réussi !' : 'Paiement échoué',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  widget.isSuccess
                      ? 'Votre compte a été crédité avec succès.'
                      : widget.reason ??
                            'Le paiement a échoué ou a été annulé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: context.secondaryText),
                ),

                if (widget.reference != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 16,
                          color: context.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Réf: ${widget.reference}',
                          style: TextStyle(
                            color: context.secondaryText,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Indication de redirection
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Redirection en cours...',
                      style: TextStyle(
                        color: context.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
