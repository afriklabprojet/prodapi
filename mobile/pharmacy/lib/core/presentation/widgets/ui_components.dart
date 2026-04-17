import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_text_styles.dart';
import 'app_empty_state.dart';
import 'buttons.dart' show PrimaryButton;

// --- CARDS ---
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: color ?? (isDark ? Colors.grey.shade900 : Colors.white),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// --- BADGES ---
// @deprecated Use StatusBadge from 'indicators.dart' instead
// This duplicate will be removed in a future version
@Deprecated('Use StatusBadge from indicators.dart with StatusType enum instead')
enum BadgeType { success, error, warning, info, neutral }

@Deprecated(
  'Use StatusBadge from indicators.dart instead. This duplicate exists for backwards compatibility.',
)
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
  });

  String _getSemanticType() {
    switch (type) {
      case BadgeType.success:
        return 'Succès';
      case BadgeType.error:
        return 'Erreur';
      case BadgeType.warning:
        return 'Attention';
      case BadgeType.info:
        return 'Information';
      default:
        return 'Statut';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (type) {
      case BadgeType.success:
        bg = Colors.green.withValues(alpha: 0.1);
        text = Colors.green;
        break;
      case BadgeType.error:
        bg = Colors.red.withValues(alpha: 0.1);
        text = Colors.red;
        break;
      case BadgeType.warning:
        bg = Colors.orange.withValues(alpha: 0.1);
        text = Colors.orange;
        break;
      case BadgeType.info:
        bg = Colors.blue.withValues(alpha: 0.1);
        text = Colors.blue;
        break;
      default:
        bg = Colors.grey[100]!;
        text = Colors.grey[700]!;
    }

    return Semantics(
      label: '${_getSemanticType()}: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: text.withValues(alpha: 0.1)),
        ),
        child: Text(label, style: AppTextStyles.label.copyWith(color: text)),
      ),
    );
  }
}

// --- EMPTY STATE ---
// @deprecated Use EmptyStateWidget from 'indicators.dart' or AppEmptyState instead
@Deprecated(
  'Use EmptyStateWidget from indicators.dart or AppEmptyState widget instead.',
)
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '$title. $message${actionLabel != null ? '. Action disponible: $actionLabel' : ''}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  label: actionLabel,
                  child: TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(actionLabel!),
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

// --- ERROR STATE ---
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'Erreur de chargement',
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTextStyles.h2),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Réessayer',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// --- LOADING STATE ---
class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// --- ASYNC VALUE WIDGET ---
/// Widget générique pour gérer les états AsyncValue (loading, error, data)
/// Réduit la duplication de code dans toute l'application
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final VoidCallback? onRetry;
  final String? emptyTitle;
  final String? emptyMessage;
  final bool Function(T data)? isEmpty;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
    this.emptyTitle,
    this.emptyMessage,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (dataValue) {
        // Check if data is empty
        if (isEmpty != null && isEmpty!(dataValue)) {
          return AppEmptyState(
            icon: Icons.inbox_outlined,
            title: emptyTitle ?? 'Aucune donnée',
            subtitle:
                emptyMessage ?? 'Aucun élément à afficher pour le moment.',
            actionLabel: onRetry != null ? 'Actualiser' : null,
            onAction: onRetry,
          );
        }
        return data(dataValue);
      },
      loading: () => loading?.call() ?? const LoadingStateWidget(),
      error: (err, stack) {
        if (error != null) {
          return error!(err, stack);
        }
        return ErrorStateWidget(
          message: err.toString(),
          onRetry: onRetry ?? () {},
        );
      },
    );
  }
}

// --- CUSTOM HEADER ---
class CustomHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? action;

  const CustomHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showBack) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Retour',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 48),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h2),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ],
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// --- ENHANCED PAGE HEADER ---
/// Widget de titre de page amélioré avec icône, sous-titre et design moderne
class EnhancedPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final Color? iconBackgroundColor;
  final bool showIcon;
  final EdgeInsetsGeometry padding;

  const EnhancedPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.dashboard_rounded,
    this.trailing,
    this.iconBackgroundColor,
    this.showIcon = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = iconBackgroundColor ?? primaryColor;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          // Icône avec fond dégradé
          if (showIcon) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgColor, bgColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
          ],

          // Titre et sous-titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Widget trailing (optionnel)
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// --- ANIMATED PAGE TITLE ---
/// Titre de page avec animation subtile et design premium
class AnimatedPageTitle extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final List<Color>? gradientColors;

  const AnimatedPageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.gradientColors,
  });

  @override
  State<AnimatedPageTitle> createState() => _AnimatedPageTitleState();
}

class _AnimatedPageTitleState extends State<AnimatedPageTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors =
        widget.gradientColors ??
        [primaryColor, primaryColor.withValues(alpha: 0.6)];

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Barre décorative avec dégradé
              Container(
                width: 5,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: primaryColor, size: 28),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: colors,
                            ).createShader(bounds),
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (widget.action != null) widget.action!,
            ],
          ),
        ),
      ),
    );
  }
}

// --- SECTION HEADER ---
/// En-tête de section avec style moderne
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final IconData? icon;
  final Color? accentColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = accentColor ?? Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: primaryColor),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (actionText != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
