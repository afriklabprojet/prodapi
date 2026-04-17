import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bouton principal avec animation et feedback haptique
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onPressed != null && !widget.isLoading) {
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = widget.backgroundColor ?? primaryColor;
    final fgColor = widget.foregroundColor ?? Colors.white;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.isLoading
          ? '${widget.label}, chargement en cours'
          : widget.label,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: isEnabled ? bgColor : bgColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: bgColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: fgColor, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: fgColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton secondaire avec bordure
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? borderColor;
  final Color? foregroundColor;
  final double? width;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.borderColor,
    this.foregroundColor,
    this.width,
    this.height = 56,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final borderColor = widget.borderColor ?? primaryColor;
    final fgColor = widget.foregroundColor ?? primaryColor;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.isLoading
          ? '${widget.label}, chargement en cours'
          : widget.label,
      child: GestureDetector(
        onTapDown: (_) {
          if (isEnabled) {
            _controller.forward();
            HapticFeedback.lightImpact();
          }
        },
        onTapUp: (_) {
          _controller.reverse();
          if (isEnabled) widget.onPressed!();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEnabled
                    ? borderColor
                    : borderColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: fgColor, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: fgColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon Button animé avec badge
class AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final int? badgeCount;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.badgeCount,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryLight = primaryColor.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed?.call();
      },
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor ?? primaryLight,
              borderRadius: BorderRadius.circular(size / 3),
            ),
            child: Icon(
              icon,
              color: iconColor ?? primaryColor,
              size: size * 0.5,
            ),
          ),
          if (badgeCount != null && badgeCount! > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badgeCount! > 99 ? '99+' : badgeCount.toString(),
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
      ),
    );
  }
}

/// Floating Action Button avec animation
class AnimatedFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool extended;

  const AnimatedFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.extended = false,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
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

    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.extended && widget.label != null
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onPressed?.call();
              },
              backgroundColor: primaryColor,
              icon: Icon(widget.icon),
              label: Text(widget.label!),
            )
          : FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onPressed?.call();
              },
              backgroundColor: primaryColor,
              child: Icon(widget.icon),
            ),
    );
  }
}

/// État du bouton async compact
enum _AsyncButtonState { idle, loading, success, error }

/// Bouton async compact pour utilisation dans les cartes
/// Affiche un spinner pendant l'action et feedback visuel succès/erreur
class AsyncSmallButton extends StatefulWidget {
  /// Callback async qui retourne true si succès
  final Future<bool> Function()? onPressed;

  /// Label du bouton
  final String label;

  /// Icône du bouton
  final IconData icon;

  /// Couleur du bouton
  final Color color;

  /// Style outline (bordure) ou filled
  final bool isOutlined;

  /// Prend toute la largeur
  final bool isFullWidth;

  /// Callback appelé après succès
  final VoidCallback? onSuccess;

  /// Callback appelé après erreur
  final VoidCallback? onError;

  const AsyncSmallButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.color,
    this.isOutlined = false,
    this.isFullWidth = false,
    this.onSuccess,
    this.onError,
  });

  @override
  State<AsyncSmallButton> createState() => _AsyncSmallButtonState();
}

class _AsyncSmallButtonState extends State<AsyncSmallButton> {
  _AsyncButtonState _state = _AsyncButtonState.idle;

  Future<void> _handlePress() async {
    if (_state != _AsyncButtonState.idle || widget.onPressed == null) return;

    setState(() => _state = _AsyncButtonState.loading);
    HapticFeedback.lightImpact();

    try {
      final success = await widget.onPressed!();

      if (!mounted) return;

      setState(
        () => _state = success
            ? _AsyncButtonState.success
            : _AsyncButtonState.error,
      );

      if (success) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }

      // Feedback visuel pendant 800ms
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      if (success) {
        widget.onSuccess?.call();
      } else {
        widget.onError?.call();
      }

      setState(() => _state = _AsyncButtonState.idle);
    } catch (e) {
      if (!mounted) return;

      setState(() => _state = _AsyncButtonState.error);
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      widget.onError?.call();
      setState(() => _state = _AsyncButtonState.idle);
    }
  }

  Color get _backgroundColor {
    if (_state == _AsyncButtonState.success) return Colors.green;
    if (_state == _AsyncButtonState.error) return Colors.red;
    return widget.color;
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled =
        widget.onPressed != null && _state == _AsyncButtonState.idle;
    final bgColor = _backgroundColor;
    final fgColor = widget.isOutlined ? bgColor : Colors.white;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: switch (_state) {
        _AsyncButtonState.idle => widget.label,
        _AsyncButtonState.loading => 'Chargement en cours',
        _AsyncButtonState.success => 'Action réussie',
        _AsyncButtonState.error => 'Erreur',
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: widget.isOutlined ? Colors.transparent : bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isEnabled ? _handlePress : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: widget.isOutlined
                    ? Border.all(color: bgColor, width: 1.5)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: widget.isFullWidth
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _state == _AsyncButtonState.loading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                fgColor,
                              ),
                            ),
                          )
                        : Icon(
                            key: ValueKey(_state),
                            _state == _AsyncButtonState.success
                                ? Icons.check_circle
                                : _state == _AsyncButtonState.error
                                ? Icons.error
                                : widget.icon,
                            size: 18,
                            color: fgColor,
                          ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      key: ValueKey(_state),
                      _state == _AsyncButtonState.loading
                          ? 'Chargement...'
                          : _state == _AsyncButtonState.success
                          ? 'Fait !'
                          : _state == _AsyncButtonState.error
                          ? 'Erreur'
                          : widget.label,
                      style: TextStyle(
                        color: fgColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
