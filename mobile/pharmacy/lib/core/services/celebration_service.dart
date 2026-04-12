import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../presentation/widgets/success_animation.dart';

/// Types de célébrations pour différents moments
enum CelebrationType {
  orderConfirmed,
  orderReady,
  orderDelivered,
  prescriptionValidated,
  paymentReceived,
  milestoneReached,
  firstSaleToday,
}

/// Configuration d'une célébration
class CelebrationConfig {
  final String message;
  final String? subtitle;
  final Color color;
  final IconData? badgeIcon;
  final Duration displayDuration;
  
  const CelebrationConfig({
    required this.message,
    this.subtitle,
    this.color = const Color(0xFF2E7D32),
    this.badgeIcon,
    this.displayDuration = const Duration(milliseconds: 2000),
  });
  
  static CelebrationConfig fromType(CelebrationType type, {int? count}) {
    switch (type) {
      case CelebrationType.orderConfirmed:
        return const CelebrationConfig(
          message: 'Commande confirmée ! 🎉',
          subtitle: 'Le client a été notifié',
          color: Color(0xFF2E7D32),
          badgeIcon: Icons.check_circle,
        );
      case CelebrationType.orderReady:
        return const CelebrationConfig(
          message: 'Commande prête ! 📦',
          subtitle: 'En attente du livreur',
          color: Color(0xFF7B1FA2),
          badgeIcon: Icons.inventory_2,
        );
      case CelebrationType.orderDelivered:
        return const CelebrationConfig(
          message: 'Livraison réussie ! 🚀',
          subtitle: 'Client satisfait',
          color: Color(0xFF1976D2),
          badgeIcon: Icons.local_shipping,
        );
      case CelebrationType.prescriptionValidated:
        return const CelebrationConfig(
          message: 'Ordonnance validée ! 📋',
          subtitle: 'Devis envoyé au client',
          color: Color(0xFF00796B),
          badgeIcon: Icons.medical_services,
        );
      case CelebrationType.paymentReceived:
        return const CelebrationConfig(
          message: 'Paiement reçu ! 💰',
          subtitle: 'Crédité sur votre solde',
          color: Color(0xFF388E3C),
          badgeIcon: Icons.payments,
        );
      case CelebrationType.milestoneReached:
        return CelebrationConfig(
          message: 'Objectif atteint ! 🏆',
          subtitle: count != null ? '$count commandes aujourd\'hui' : null,
          color: const Color(0xFFF57C00),
          badgeIcon: Icons.emoji_events,
        );
      case CelebrationType.firstSaleToday:
        return const CelebrationConfig(
          message: 'Première vente du jour ! ☀️',
          subtitle: 'C\'est parti !',
          color: Color(0xFFFFB300),
          badgeIcon: Icons.wb_sunny,
        );
    }
  }
}

/// Service pour afficher des célébrations micro-animées.
/// 
/// Usage:
/// ```dart
/// CelebrationService.celebrate(
///   context: context,
///   type: CelebrationType.orderConfirmed,
/// );
/// ```
class CelebrationService {
  /// Affiche une célébration overlay avec animation
  static Future<void> celebrate({
    required BuildContext context,
    required CelebrationType type,
    int? count,
    VoidCallback? onComplete,
  }) async {
    final config = CelebrationConfig.fromType(type, count: count);
    
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Célébration',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return _CelebrationOverlay(
          config: config,
          onComplete: () {
            Navigator.of(context, rootNavigator: true).pop();
            onComplete?.call();
          },
        );
      },
    );
  }
  
  /// Célébration rapide sans overlay (juste haptic + snackbar amélioré)
  static void quickCelebrate({
    required BuildContext context,
    required String message,
    Color? color,
  }) {
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color ?? const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _CelebrationOverlay extends StatefulWidget {
  final CelebrationConfig config;
  final VoidCallback onComplete;
  
  const _CelebrationOverlay({
    required this.config,
    required this.onComplete,
  });

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> {
  bool _animationComplete = false;
  
  @override
  void initState() {
    super.initState();
    // Auto-dismiss après la durée configurée
    Future.delayed(widget.config.displayDuration, () {
      if (mounted && _animationComplete) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.config.color.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SuccessAnimation(
                size: 100,
                color: widget.config.color,
                onComplete: () {
                  setState(() => _animationComplete = true);
                },
              ),
              const SizedBox(height: 24),
              Text(
                widget.config.message,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.config.color,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.config.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.config.subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.config.badgeIcon != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.config.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.config.badgeIcon,
                        size: 16,
                        color: widget.config.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Continuer',
                        style: TextStyle(
                          color: widget.config.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
