import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/delivery_providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/services/rich_notification_service.dart';
import '../../../core/services/kyc_guard_service.dart';

/// ══════════════════════════════════════════════════════════════════════════
/// BADGES DE NAVIGATION
/// ══════════════════════════════════════════════════════════════════════════
/// 
/// Composants pour afficher des badges de notification sur la bottom nav.
/// ══════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════
// PROVIDERS DE BADGES
// ══════════════════════════════════════════════════════════════════════════

/// Compte les livraisons actives (en cours).
final pendingDeliveriesCountProvider = Provider<int>((ref) {
  final activeDeliveries = ref.watch(deliveriesProvider('active'));
  
  return activeDeliveries.maybeWhen(
    data: (list) => list.length,
    orElse: () => 0,
  );
});

/// Compte les notifications non lues (pour la navigation).
/// Connecté au service de notifications riches.
final navNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(unreadNotificationCountProvider);
});

/// Badge combiné pour les profils (notifications de profil, alertes KYC, etc.)
/// Affiche un badge si le KYC n'est pas vérifié ou si des documents sont manquants.
final profileAlertCountProvider = Provider<int>((ref) {
  final kycStatus = ref.watch(kycStatusProvider);
  
  // Compteur d'alertes profil
  int alertCount = 0;
  
  // Alerte KYC non vérifié
  switch (kycStatus) {
    case KycStatus.incomplete:
      alertCount++; // Documents manquants
    case KycStatus.rejected:
      alertCount++; // Documents refusés - action requise
    case KycStatus.pendingReview:
      // Pas d'alerte, en attente de validation
      break;
    case KycStatus.verified:
      // Aucune alerte
      break;
    case KycStatus.unknown:
      alertCount++; // Statut inconnu - vérification requise
  }
  
  return alertCount;
});

// ══════════════════════════════════════════════════════════════════════════
// WIDGET BADGE
// ══════════════════════════════════════════════════════════════════════════

/// Type de badge avec style prédéfini.
enum NavBadgeType {
  /// Badge rouge standard pour les notifications urgentes.
  notification,
  
  /// Badge bleu pour les compteurs informatifs (livraisons en cours).
  info,
  
  /// Badge vert pour les indicateurs positifs.
  success,
  
  /// Badge orange pour les alertes.
  warning,
}

/// Badge configurable pour les icônes de navigation.
class NavBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showZero;
  final NavBadgeType type;
  final double size;
  final Offset offset;
  
  const NavBadge({
    super.key,
    required this.child,
    required this.count,
    this.showZero = false,
    this.type = NavBadgeType.notification,
    this.size = 16,
    this.offset = const Offset(8, -4),
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !showZero) return child;

    final Color badgeColor;
    switch (type) {
      case NavBadgeType.notification:
        badgeColor = Colors.red;
      case NavBadgeType.info:
        badgeColor = DesignTokens.primary;
      case NavBadgeType.success:
        badgeColor = DesignTokens.success;
      case NavBadgeType.warning:
        badgeColor = DesignTokens.warning;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -offset.dx,
          top: offset.dy,
          child: _BadgeIndicator(
            count: count,
            color: badgeColor,
            size: size,
          ),
        ),
      ],
    );
  }
}

/// Indicateur de badge interne.
class _BadgeIndicator extends StatelessWidget {
  final int count;
  final Color color;
  final double size;

  const _BadgeIndicator({
    required this.count,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = count > 99 ? '99+' : count.toString();
    final isSmall = count < 10;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 0 : 4,
        vertical: 0,
      ),
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// WIDGET D'ICÔNE AVEC BADGE POUR LA NAVIGATION
// ══════════════════════════════════════════════════════════════════════════

/// Icône de navigation avec badge intégré basé sur un provider.
class NavIconWithBadge extends ConsumerWidget {
  final IconData icon;
  final Provider<int> countProvider;
  final NavBadgeType badgeType;
  final double iconSize;
  final Color? iconColor;
  final bool showZero;

  const NavIconWithBadge({
    super.key,
    required this.icon,
    required this.countProvider,
    this.badgeType = NavBadgeType.notification,
    this.iconSize = 24,
    this.iconColor,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(countProvider);
    
    return NavBadge(
      count: count,
      type: badgeType,
      showZero: showZero,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}

/// Badge de point simple (sans compteur) pour indiquer un changement.
class NavDotBadge extends StatelessWidget {
  final Widget child;
  final bool show;
  final Color? color;
  final double size;
  final Offset offset;

  const NavDotBadge({
    super.key,
    required this.child,
    this.show = true,
    this.color,
    this.size = 8,
    this.offset = const Offset(0, 0),
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -offset.dx,
          top: offset.dy,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color ?? Colors.red,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ANIMATIONS DE BADGE
// ══════════════════════════════════════════════════════════════════════════

/// Badge avec animation de pulse pour attirer l'attention.
class AnimatedNavBadge extends StatefulWidget {
  final Widget child;
  final int count;
  final bool showZero;
  final NavBadgeType type;
  final bool animate;

  const AnimatedNavBadge({
    super.key,
    required this.child,
    required this.count,
    this.showZero = false,
    this.type = NavBadgeType.notification,
    this.animate = true,
  });

  @override
  State<AnimatedNavBadge> createState() => _AnimatedNavBadgeState();
}

class _AnimatedNavBadgeState extends State<AnimatedNavBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _previousCount = widget.count;
  }

  @override
  void didUpdateWidget(AnimatedNavBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animer quand le count augmente
    if (widget.count > _previousCount && widget.animate) {
      _controller.forward(from: 0);
    }
    _previousCount = widget.count;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0 && !widget.showZero) return widget.child;

    final Color badgeColor;
    switch (widget.type) {
      case NavBadgeType.notification:
        badgeColor = Colors.red;
      case NavBadgeType.info:
        badgeColor = DesignTokens.primary;
      case NavBadgeType.success:
        badgeColor = DesignTokens.success;
      case NavBadgeType.warning:
        badgeColor = DesignTokens.warning;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          right: -8,
          top: -4,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _BadgeIndicator(
              count: widget.count,
              color: badgeColor,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}
