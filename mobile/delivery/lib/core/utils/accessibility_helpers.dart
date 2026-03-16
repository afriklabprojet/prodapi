import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Helpers pour l'accessibilité de l'application
/// Fournit des widgets et fonctions pour améliorer l'expérience
/// des utilisateurs avec lecteurs d'écran (TalkBack/VoiceOver)

/// Widget accessible pour les boutons d'action
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final bool excludeFromSemantics;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: excludeFromSemantics,
      child: InkWell(
        onTap: onPressed,
        child: child,
      ),
    );
  }
}

/// Widget pour les images accessibles
class AccessibleImage extends StatelessWidget {
  final ImageProvider image;
  final String semanticLabel;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AccessibleImage({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Widget pour les statistiques accessibles
class AccessibleStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Widget? child;

  const AccessibleStat({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: child ?? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 16),
          if (icon != null) const SizedBox(width: 4),
          Text('$label: $value'),
        ],
      ),
    );
  }
}

/// Widget pour les notifications/alertes accessibles
class AccessibleAlert extends StatelessWidget {
  final String message;
  final AlertType type;
  final Widget? child;

  const AccessibleAlert({
    super.key,
    required this.message,
    this.type = AlertType.info,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${_getAlertPrefix()}: $message',
      liveRegion: true,
      child: child ?? Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(_getIcon(), color: _getIconColor()),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  String _getAlertPrefix() {
    switch (type) {
      case AlertType.success:
        return 'Succès';
      case AlertType.warning:
        return 'Attention';
      case AlertType.error:
        return 'Erreur';
      case AlertType.info:
        return 'Information';
    }
  }

  IconData _getIcon() {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle;
      case AlertType.warning:
        return Icons.warning;
      case AlertType.error:
        return Icons.error;
      case AlertType.info:
        return Icons.info;
    }
  }

  Color _getBackgroundColor() {
    switch (type) {
      case AlertType.success:
        return Colors.green.shade50;
      case AlertType.warning:
        return Colors.orange.shade50;
      case AlertType.error:
        return Colors.red.shade50;
      case AlertType.info:
        return Colors.blue.shade50;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case AlertType.success:
        return Colors.green;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.error:
        return Colors.red;
      case AlertType.info:
        return Colors.blue;
    }
  }
}

enum AlertType { success, warning, error, info }

/// Widget pour les cartes de livraison accessibles
class AccessibleDeliveryCard extends StatelessWidget {
  final String orderId;
  final String pharmacyName;
  final String customerName;
  final String status;
  final String? distance;
  final String? eta;
  final VoidCallback? onTap;
  final Widget child;

  const AccessibleDeliveryCard({
    super.key,
    required this.orderId,
    required this.pharmacyName,
    required this.customerName,
    required this.status,
    this.distance,
    this.eta,
    this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final distanceInfo = distance != null ? ', $distance' : '';
    final etaInfo = eta != null ? ', arrivée estimée $eta' : '';
    
    return Semantics(
      label: 'Livraison $orderId. '
          'De $pharmacyName vers $customerName. '
          'Statut: $status$distanceInfo$etaInfo',
      button: onTap != null,
      onTap: onTap,
      child: child,
    );
  }
}

/// Widget pour les champs de formulaire accessibles
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const AccessibleTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: labelText,
      textField: true,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          errorText: errorText,
        ),
      ),
    );
  }
}

/// Widget pour les switch/toggle accessibles
class AccessibleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? hint;

  const AccessibleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, ${value ? "activé" : "désactivé"}',
      hint: hint,
      toggled: value,
      child: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// Widget pour les indicateurs de progression accessibles
class AccessibleProgressIndicator extends StatelessWidget {
  final double? value;
  final String label;

  const AccessibleProgressIndicator({
    super.key,
    this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progressText = value != null 
        ? '${(value! * 100).toInt()}%' 
        : 'en cours';
    
    return Semantics(
      label: '$label: $progressText',
      child: value != null
          ? LinearProgressIndicator(value: value)
          : const CircularProgressIndicator(),
    );
  }
}

/// Widget pour le statut en ligne/hors ligne accessible
class AccessibleOnlineStatus extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onToggle;
  final Widget child;

  const AccessibleOnlineStatus({
    super.key,
    required this.isOnline,
    this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isOnline 
          ? 'Statut: En ligne. Double tap pour passer hors ligne.'
          : 'Statut: Hors ligne. Double tap pour passer en ligne.',
      button: true,
      onTap: onToggle,
      child: child,
    );
  }
}

/// Widget pour les badges de niveau/gamification
class AccessibleBadge extends StatelessWidget {
  final String name;
  final String description;
  final bool isUnlocked;
  final Widget child;

  const AccessibleBadge({
    super.key,
    required this.name,
    required this.description,
    required this.isUnlocked,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Badge $name. $description. ${isUnlocked ? "Débloqué" : "Verrouillé"}',
      child: child,
    );
  }
}

/// Extension pour ajouter facilement des semantics
extension AccessibilityExtensions on Widget {
  /// Ajoute un label sémantique à un widget
  Widget withSemanticLabel(String label) {
    return Semantics(
      label: label,
      child: this,
    );
  }

  /// Marque le widget comme un bouton
  Widget asSemanticButton(String label, {VoidCallback? onTap}) {
    return Semantics(
      label: label,
      button: true,
      onTap: onTap,
      child: this,
    );
  }

  /// Marque le widget comme un header
  Widget asSemanticHeader(String label) {
    return Semantics(
      label: label,
      header: true,
      child: this,
    );
  }

  /// Exclut le widget de la navigation sémantique
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }

  /// Fusionne les semantics des enfants
  Widget mergeSemantics() {
    return MergeSemantics(child: this);
  }
}

/// Classe utilitaire pour les annonces d'accessibilité
class AccessibilityAnnouncer {
  /// Annonce un message aux utilisateurs de lecteurs d'écran
  static void announce(BuildContext context, String message) {
    SemanticsService.sendAnnouncement(View.of(context), message, TextDirection.ltr);
  }

  /// Annonce un succès
  static void announceSuccess(BuildContext context, String message) {
    announce(context, 'Succès: $message');
  }

  /// Annonce une erreur
  static void announceError(BuildContext context, String message) {
    announce(context, 'Erreur: $message');
  }

  /// Annonce une mise à jour de statut
  static void announceStatus(BuildContext context, String status) {
    announce(context, 'Statut: $status');
  }
}

/// Constantes pour les durées d'animation accessibles
class AccessibleAnimationDurations {
  /// Durée pour les utilisateurs avec préférence de mouvement réduit
  static const Duration reduced = Duration(milliseconds: 50);
  
  /// Durée normale
  static const Duration normal = Duration(milliseconds: 300);
  
  /// Durée longue
  static const Duration long = Duration(milliseconds: 500);
  
  /// Obtient la durée appropriée selon les préférences utilisateur
  static Duration getDuration(BuildContext context, Duration normalDuration) {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.disableAnimations) {
      return reduced;
    }
    return normalDuration;
  }
}

/// Classe pour les tailles de texte accessibles
class AccessibleTextSizes {
  static const double small = 12.0;
  static const double medium = 14.0;
  static const double large = 16.0;
  static const double extraLarge = 20.0;
  static const double heading = 24.0;
  
  /// Obtient la taille minimum pour l'accessibilité
  static double getMinimumTappableSize(BuildContext context) {
    // La taille minimum recommandée est de 48x48 pixels
    return 48.0;
  }
}
