import 'package:flutter/material.dart';

/// Widgets d'accessibilité pour l'application DR-PHARMA
/// Facilite l'intégration de VoiceOver et TalkBack

/// Bouton accessible avec sémantiques appropriées
class AccessibleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String semanticLabel;
  final String? semanticHint;
  final bool isEnabled;
  final bool isLoading;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.semanticLabel,
    this.semanticHint,
    this.isEnabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled && !isLoading,
      label: isLoading ? '$semanticLabel, chargement en cours' : semanticLabel,
      hint: semanticHint,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: isEnabled && !isLoading ? onPressed : null,
        child: child,
      ),
    );
  }
}

/// Image accessible avec description
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
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
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

/// Card accessible avec rôle de bouton ou container
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final String? semanticHint;
  final VoidCallback? onTap;
  final bool isButton;

  const AccessibleCard({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.semanticHint,
    this.onTap,
    this.isButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: isButton && onTap != null,
      container: true,
      label: semanticLabel,
      hint: semanticHint,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

/// En-tête accessible (pour les titres de section)
class AccessibleHeader extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? headerLevel; // 1-6 comme en HTML

  const AccessibleHeader({
    super.key,
    required this.text,
    this.style,
    this.headerLevel = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: text,
      child: Text(
        text,
        style: style ?? Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

/// Champ de formulaire accessible
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool isRequired;

  const AccessibleTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    String semanticLabel = label;
    if (isRequired) {
      semanticLabel += ', obligatoire';
    }
    if (errorText != null) {
      semanticLabel += ', erreur: $errorText';
    }

    return Semantics(
      textField: true,
      label: semanticLabel,
      hint: hint,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          hintText: hint,
          errorText: errorText,
        ),
      ),
    );
  }
}

/// Liste accessible avec navigation
class AccessibleList extends StatelessWidget {
  final List<Widget> children;
  final String listLabel;
  final int itemCount;

  const AccessibleList({
    super.key,
    required this.children,
    required this.listLabel,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$listLabel, $itemCount éléments',
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          return Semantics(
            label: 'Élément ${index + 1} sur $itemCount',
            child: child,
          );
        }).toList(),
      ),
    );
  }
}

/// Badge de notification accessible
class AccessibleBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final String itemLabel;

  const AccessibleBadge({
    super.key,
    required this.count,
    required this.child,
    this.itemLabel = 'notifications',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: count > 0 ? '$count $itemLabel non lues' : 'Aucune $itemLabel',
      child: child,
    );
  }
}

/// Icône d'action accessible
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color? color;
  final double? size;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: onPressed,
        tooltip: semanticLabel,
      ),
    );
  }
}

/// Indicateur de chargement accessible
class AccessibleLoading extends StatelessWidget {
  final String? message;

  const AccessibleLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message ?? 'Chargement en cours, veuillez patienter',
      liveRegion: true,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// État vide accessible
class AccessibleEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AccessibleEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              AccessibleButton(
                onPressed: onAction,
                semanticLabel: actionLabel!,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État d'erreur accessible avec live region
class AccessibleErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AccessibleErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Erreur: $message',
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AccessibleButton(
                onPressed: onRetry,
                semanticLabel: 'Réessayer',
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Extension pour ajouter facilement des sémantiques
extension SemanticsExtension on Widget {
  /// Ajoute un label sémantique à n'importe quel widget
  Widget withSemantics({
    required String label,
    String? hint,
    bool? button,
    bool? header,
    bool? image,
    bool? liveRegion,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      header: header,
      image: image,
      liveRegion: liveRegion,
      excludeSemantics: excludeSemantics,
      child: this,
    );
  }

  /// Marque un widget comme bouton accessible
  Widget asAccessibleButton(String label, {String? hint}) {
    return Semantics(button: true, label: label, hint: hint, child: this);
  }

  /// Exclut un widget de l'arbre sémantique
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }
}
