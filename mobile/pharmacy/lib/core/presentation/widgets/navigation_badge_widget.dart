import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Badge de notification uniforme pour la navigation.
///
/// Affiche un badge numérique ou un point coloré pour indiquer
/// des notifications, commandes en attente, messages non lus, etc.
///
/// Usage:
/// ```dart
/// NavigationBadge(
///   count: 3,
///   child: Icon(Icons.notifications),
/// )
/// ```
class NavigationBadge extends StatelessWidget {
  const NavigationBadge({
    super.key,
    required this.child,
    this.count = 0,
    this.showDot = false,
    this.maxCount = 99,
    this.backgroundColor,
    this.textColor,
    this.position = BadgePosition.topRight,
    this.size = BadgeSize.small,
    this.animate = true,
    this.semanticLabel,
  });

  /// Widget enfant (icône, texte, etc.).
  final Widget child;

  /// Nombre à afficher dans le badge.
  final int count;

  /// Afficher juste un point au lieu d'un nombre.
  final bool showDot;

  /// Nombre maximum à afficher (99+ si dépassé).
  final int maxCount;

  /// Couleur de fond du badge.
  final Color? backgroundColor;

  /// Couleur du texte.
  final Color? textColor;

  /// Position du badge.
  final BadgePosition position;

  /// Taille du badge.
  final BadgeSize size;

  /// Animer l'apparition du badge.
  final bool animate;

  /// Label sémantique pour l'accessibilité.
  final String? semanticLabel;

  bool get _shouldShow => count > 0 || showDot;

  String get _displayText {
    if (showDot) return '';
    if (count > maxCount) return '$maxCount+';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = backgroundColor ?? AppColors.error;
    final textStyle = textColor ?? Colors.white;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final (top, right, bottom, left) = _getPositionOffsets();

    return Semantics(
      label: semanticLabel ?? (_shouldShow ? '$count notifications' : null),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (_shouldShow)
            Positioned(
              top: top,
              right: right,
              bottom: bottom,
              left: left,
              child: _buildBadge(
                context: context,
                badgeColor: badgeColor,
                textColor: textStyle,
                reduceMotion: reduceMotion,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required BuildContext context,
    required Color badgeColor,
    required Color textColor,
    required bool reduceMotion,
  }) {
    final badgeSize = _getBadgeSize();

    if (showDot) {
      return _AnimatedBadge(
        animate: animate && !reduceMotion,
        child: Container(
          width: badgeSize.dotSize,
          height: badgeSize.dotSize,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
          ),
        ),
      );
    }

    return _AnimatedBadge(
      animate: animate && !reduceMotion,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: badgeSize.horizontalPadding,
          vertical: badgeSize.verticalPadding,
        ),
        constraints: BoxConstraints(
          minWidth: badgeSize.minWidth,
          minHeight: badgeSize.minWidth,
        ),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(badgeSize.borderRadius),
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          _displayText,
          style: TextStyle(
            color: textColor,
            fontSize: badgeSize.fontSize,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  (double?, double?, double?, double?) _getPositionOffsets() {
    switch (position) {
      case BadgePosition.topRight:
        return (-4, -4, null, null);
      case BadgePosition.topLeft:
        return (-4, null, null, -4);
      case BadgePosition.bottomRight:
        return (null, -4, -4, null);
      case BadgePosition.bottomLeft:
        return (null, null, -4, -4);
      case BadgePosition.topCenter:
        return (-8, null, null, null);
    }
  }

  _BadgeSizeConfig _getBadgeSize() {
    switch (size) {
      case BadgeSize.small:
        return const _BadgeSizeConfig(
          minWidth: 16,
          fontSize: 10,
          horizontalPadding: 4,
          verticalPadding: 2,
          borderRadius: 8,
          dotSize: 8,
        );
      case BadgeSize.medium:
        return const _BadgeSizeConfig(
          minWidth: 20,
          fontSize: 12,
          horizontalPadding: 6,
          verticalPadding: 3,
          borderRadius: 10,
          dotSize: 10,
        );
      case BadgeSize.large:
        return const _BadgeSizeConfig(
          minWidth: 24,
          fontSize: 14,
          horizontalPadding: 8,
          verticalPadding: 4,
          borderRadius: 12,
          dotSize: 12,
        );
    }
  }
}

/// Position du badge.
enum BadgePosition {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
  topCenter,
}

/// Taille du badge.
enum BadgeSize {
  small,
  medium,
  large,
}

class _BadgeSizeConfig {
  const _BadgeSizeConfig({
    required this.minWidth,
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
    required this.dotSize,
  });

  final double minWidth;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double dotSize;
}

/// Widget animé pour l'apparition du badge.
class _AnimatedBadge extends StatefulWidget {
  const _AnimatedBadge({
    required this.child,
    required this.animate,
  });

  final Widget child;
  final bool animate;

  @override
  State<_AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<_AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return widget.child;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

/// Badge spécialisé pour la barre de navigation.
///
/// Optimisé pour s'intégrer dans BottomNavigationBar ou CupertinoTabBar.
class NavigationBarBadge extends StatelessWidget {
  const NavigationBarBadge({
    super.key,
    required this.icon,
    this.count = 0,
    this.activeIcon,
    this.isSelected = false,
    this.selectedColor,
    this.unselectedColor,
    this.showDot = false,
    this.label,
  });

  /// Icône de la tab.
  final IconData icon;

  /// Icône active (optionnel).
  final IconData? activeIcon;

  /// Nombre de notifications.
  final int count;

  /// La tab est sélectionnée.
  final bool isSelected;

  /// Couleur quand sélectionné.
  final Color? selectedColor;

  /// Couleur quand non sélectionné.
  final Color? unselectedColor;

  /// Afficher un point au lieu d'un nombre.
  final bool showDot;

  /// Label pour l'accessibilité.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedColor = selectedColor ?? AppColors.primary;
    final effectiveUnselectedColor =
        unselectedColor ?? AppColors.textSecondary;

    return NavigationBadge(
      count: count,
      showDot: showDot,
      semanticLabel: label != null
          ? (count > 0 ? '$label, $count notifications' : label)
          : null,
      child: Icon(
        isSelected ? (activeIcon ?? icon) : icon,
        color: isSelected ? effectiveSelectedColor : effectiveUnselectedColor,
      ),
    );
  }
}
