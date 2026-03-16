import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Badge de statut coloré
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final bool showDot;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.showDot = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusColors _getColors() {
    switch (type) {
      case StatusType.success:
        return _StatusColors(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          textColor: Colors.green.shade700,
          dotColor: Colors.green,
        );
      case StatusType.warning:
        return _StatusColors(
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          textColor: const Color(0xFFB8860B),
          dotColor: Colors.orange,
        );
      case StatusType.error:
        return _StatusColors(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          textColor: Colors.red.shade700,
          dotColor: Colors.red,
        );
      case StatusType.info:
        return _StatusColors(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          textColor: Colors.blue.shade700,
          dotColor: Colors.blue,
        );
      case StatusType.pending:
        return _StatusColors(
          backgroundColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
          dotColor: const Color(0xFFFF9800),
        );
      case StatusType.neutral:
        return _StatusColors(
          backgroundColor: const Color(0xFFF5F5F5),
          textColor: Colors.grey.shade600,
          dotColor: Colors.grey.shade600,
        );
    }
  }
}

enum StatusType { success, warning, error, info, pending, neutral }

class _StatusColors {
  final Color backgroundColor;
  final Color textColor;
  final Color dotColor;

  _StatusColors({
    required this.backgroundColor,
    required this.textColor,
    required this.dotColor,
  });
}

/// Avatar avec initiales ou image
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 48,
    this.backgroundColor,
  });

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty || parts[0].isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    final lastPart = parts[parts.length - 1];
    if (lastPart.isEmpty) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${lastPart[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryLight = primaryColor.withValues(alpha: 0.1);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? primaryLight,
        shape: BoxShape.circle,
        image: imageUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                _initials,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}

/// Indicateur de progression circulaire
class CircularProgressWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Color? progressColor;
  final Color? backgroundColor;
  final double strokeWidth;
  final Widget? child;

  const CircularProgressWidget({
    super.key,
    required this.progress,
    this.size = 80,
    this.progressColor,
    this.backgroundColor,
    this.strokeWidth = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              backgroundColor: backgroundColor ?? Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? primaryColor,
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Indicateur de stock avec couleur
class StockIndicator extends StatelessWidget {
  final int quantity;
  final int lowStockThreshold;
  final int outOfStockThreshold;

  const StockIndicator({
    super.key,
    required this.quantity,
    this.lowStockThreshold = 10,
    this.outOfStockThreshold = 0,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    StatusType type;

    if (quantity <= outOfStockThreshold) {
      label = 'Rupture';
      type = StatusType.error;
    } else if (quantity <= lowStockThreshold) {
      label = 'Stock bas';
      type = StatusType.warning;
    } else {
      label = 'En stock';
      type = StatusType.success;
    }

    return StatusBadge(label: label, type: type);
  }
}

/// Icône avec notification badge animé
class IconWithBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final double iconSize;
  final Color? iconColor;
  final Color? badgeColor;

  const IconWithBadge({
    super.key,
    required this.icon,
    required this.count,
    this.iconSize = 24,
    this.iconColor,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor = isDark ? Colors.white : Colors.black87;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: iconColor ?? defaultIconColor,
        ),
        if (count > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (badgeColor ?? Colors.red).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 16,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Séparateur avec texte
class TextDivider extends StatelessWidget {
  final String text;
  final double thickness;
  final Color? color;

  const TextDivider({
    super.key,
    required this.text,
    this.thickness = 1,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: thickness,
            color: color ?? Colors.grey.shade200,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            thickness: thickness,
            color: color ?? Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryLight = primaryColor.withValues(alpha: 0.1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}