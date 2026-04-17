import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/ui_constants.dart';

/// États possibles du bouton d'action.
enum ActionButtonState { idle, loading, success, error }

/// Bouton d'action avec feedback visuel intégré.
/// Montre l'état pending → success/error directement sur le bouton.
/// Élimine l'incertitude "mon tap a-t-il été enregistré ?".
class ActionButton extends StatefulWidget {
  /// Callback qui retourne true si l'action a réussi.
  final Future<bool> Function() onPressed;
  
  /// Label affiché à l'état idle.
  final String label;
  
  /// Icône affichée à l'état idle.
  final IconData? icon;
  
  /// Couleur de fond à l'état idle (défaut: primary).
  final Color? backgroundColor;
  
  /// Durée d'affichage de l'état success/error avant retour à idle.
  final Duration feedbackDuration;
  
  /// Callback appelé après le feedback success.
  final VoidCallback? onSuccess;
  
  /// Callback appelé après le feedback error.
  final VoidCallback? onError;
  
  /// Désactiver le bouton.
  final bool disabled;
  
  /// Taille du bouton.
  final ActionButtonSize size;

  const ActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.feedbackDuration = AnimationConstants.feedbackDisplay,
    this.onSuccess,
    this.onError,
    this.disabled = false,
    this.size = ActionButtonSize.medium,
  });

  /// Factory pour un bouton de validation.
  factory ActionButton.validate({
    required Future<bool> Function() onPressed,
    String label = 'Valider',
    VoidCallback? onSuccess,
    bool disabled = false,
  }) {
    return ActionButton(
      onPressed: onPressed,
      label: label,
      icon: Icons.check_rounded,
      backgroundColor: Colors.green,
      onSuccess: onSuccess,
      disabled: disabled,
    );
  }

  /// Factory pour un bouton d'envoi.
  factory ActionButton.send({
    required Future<bool> Function() onPressed,
    String label = 'Envoyer',
    VoidCallback? onSuccess,
    bool disabled = false,
  }) {
    return ActionButton(
      onPressed: onPressed,
      label: label,
      icon: Icons.send_rounded,
      onSuccess: onSuccess,
      disabled: disabled,
    );
  }

  /// Factory pour un bouton de confirmation commande.
  factory ActionButton.confirmOrder({
    required Future<bool> Function() onPressed,
    VoidCallback? onSuccess,
    bool disabled = false,
  }) {
    return ActionButton(
      onPressed: onPressed,
      label: 'Confirmer la commande',
      icon: Icons.shopping_bag_outlined,
      backgroundColor: Colors.teal,
      onSuccess: onSuccess,
      disabled: disabled,
    );
  }

  /// Factory pour un bouton d'envoi de devis.
  factory ActionButton.sendQuote({
    required Future<bool> Function() onPressed,
    VoidCallback? onSuccess,
    bool disabled = false,
  }) {
    return ActionButton(
      onPressed: onPressed,
      label: 'Envoyer le devis',
      icon: Icons.receipt_long_outlined,
      backgroundColor: Colors.indigo,
      onSuccess: onSuccess,
      disabled: disabled,
    );
  }

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  ActionButtonState _state = ActionButtonState.idle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_state != ActionButtonState.idle || widget.disabled) return;

    // État loading
    setState(() => _state = ActionButtonState.loading);
    HapticFeedback.lightImpact();
    _controller.forward();

    try {
      final success = await widget.onPressed();
      
      if (!mounted) return;
      
      // État résultat
      setState(() => _state = success ? ActionButtonState.success : ActionButtonState.error);
      HapticFeedback.mediumImpact();
      
      // Attendre le feedback visuel
      await Future.delayed(widget.feedbackDuration);
      
      if (!mounted) return;
      
      // Callbacks
      if (success) {
        widget.onSuccess?.call();
      } else {
        widget.onError?.call();
      }
      
      // Retour à idle
      _controller.reverse();
      setState(() => _state = ActionButtonState.idle);
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _state = ActionButtonState.error);
      HapticFeedback.heavyImpact();
      
      await Future.delayed(widget.feedbackDuration);
      
      if (!mounted) return;
      
      widget.onError?.call();
      _controller.reverse();
      setState(() => _state = ActionButtonState.idle);
    }
  }

  Color get _backgroundColor {
    if (widget.disabled) return Colors.grey.shade400;
    
    return switch (_state) {
      ActionButtonState.success => Colors.green,
      ActionButtonState.error => Colors.red.shade600,
      _ => widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
    };
  }

  double get _borderRadius {
    return switch (_state) {
      ActionButtonState.loading => 50.0,
      ActionButtonState.success => 50.0,
      ActionButtonState.error => 50.0,
      _ => 14.0,
    };
  }

  EdgeInsets get _padding {
    final base = switch (widget.size) {
      ActionButtonSize.small => const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ActionButtonSize.medium => const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ActionButtonSize.large => const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    };
    
    if (_state == ActionButtonState.loading || 
        _state == ActionButtonState.success || 
        _state == ActionButtonState.error) {
      return EdgeInsets.all(base.vertical);
    }
    
    return base;
  }

  double get _iconSize {
    return switch (widget.size) {
      ActionButtonSize.small => 16.0,
      ActionButtonSize.medium => 20.0,
      ActionButtonSize.large => 24.0,
    };
  }

  double get _fontSize {
    return switch (widget.size) {
      ActionButtonSize.small => 13.0,
      ActionButtonSize.medium => 15.0,
      ActionButtonSize.large => 17.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !widget.disabled && _state == ActionButtonState.idle,
      label: switch (_state) {
        ActionButtonState.idle => widget.label,
        ActionButtonState.loading => 'Chargement en cours',
        ActionButtonState.success => 'Action réussie',
        ActionButtonState.error => 'Erreur, réessayez',
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _state == ActionButtonState.loading ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(_borderRadius),
            boxShadow: widget.disabled || _state != ActionButtonState.idle
                ? []
                : [
                    BoxShadow(
                      color: _backgroundColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _state == ActionButtonState.idle && !widget.disabled
                  ? _handlePress
                  : null,
              borderRadius: BorderRadius.circular(_borderRadius),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                padding: _padding,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return switch (_state) {
      ActionButtonState.idle => Row(
        key: const ValueKey('idle'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: _iconSize),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      ActionButtonState.loading => SizedBox(
        key: const ValueKey('loading'),
        width: _iconSize + 4,
        height: _iconSize + 4,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      ),
      ActionButtonState.success => Icon(
        key: const ValueKey('success'),
        Icons.check_rounded,
        color: Colors.white,
        size: _iconSize + 4,
      ),
      ActionButtonState.error => Icon(
        key: const ValueKey('error'),
        Icons.close_rounded,
        color: Colors.white,
        size: _iconSize + 4,
      ),
    };
  }
}

/// Tailles disponibles pour ActionButton.
enum ActionButtonSize { small, medium, large }

/// Version étendue du bouton qui prend toute la largeur.
class ActionButtonExpanded extends StatelessWidget {
  final Future<bool> Function() onPressed;
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final bool disabled;

  const ActionButtonExpanded({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.onSuccess,
    this.onError,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ActionButton(
        onPressed: onPressed,
        label: label,
        icon: icon,
        backgroundColor: backgroundColor,
        onSuccess: onSuccess,
        onError: onError,
        disabled: disabled,
        size: ActionButtonSize.large,
      ),
    );
  }
}
