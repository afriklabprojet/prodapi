import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';

// =============================================================================
// EMOTIONAL COPY - Ton conversationnel pour les livreurs
// =============================================================================

/// Messages émotionnels contextuels pour les états vides.
/// Ton motivant et compréhensif pour les livreurs.
class _EmotionalCopy {
  _EmotionalCopy._();

  static const deliveries = (
    title: 'C\'est calme pour l\'instant 🌙',
    subtitle:
        'Les courses arrivent généralement vers 11h30 et 18h30.\nOn te notifie dès qu\'il y en a une !',
    actionLabel: 'Actualiser',
  );

  static const activeDeliveries = (
    title: 'Pas de course en cours',
    subtitle: 'Passe en ligne pour recevoir des livraisons près de toi.',
    actionLabel: 'Passer en ligne',
  );

  static const history = (
    title: 'Ton historique est vide',
    subtitle:
        'Tes courses terminées apparaîtront ici.\nCommence à livrer pour voir tes stats !',
    actionLabel: null,
  );

  static const earnings = (
    title: 'Aucun gain encore 💰',
    subtitle:
        'Tes revenus s\'afficheront ici dès ta première course.\nChaque livraison compte !',
    actionLabel: null,
  );

  static const chat = (
    title: 'Pas de message',
    subtitle:
        'Les conversations avec les clients et pharmacies apparaissent ici.',
    actionLabel: null,
  );

  static const challenges = (
    title: 'Pas de défi disponible',
    subtitle:
        'Les nouveaux défis arrivent chaque jour à minuit.\nReviens demain pour de nouvelles récompenses !',
    actionLabel: 'Voir mes badges',
  );

  static const support = (
    title: 'Aucun ticket',
    subtitle:
        'Tu as une question ou un souci ?\nNotre équipe est dispo 24h/24.',
    actionLabel: 'Contacter le support',
  );

  static const batch = (
    title: 'Aucune course groupée',
    subtitle:
        'Les courses regroupables apparaîtront ici.\nOptimise ton temps en livrant plusieurs commandes !',
    actionLabel: null,
  );

  static const notifications = (
    title: 'Tout est lu ! ✓',
    subtitle: 'Tu es à jour. Les nouvelles alertes apparaîtront ici.',
    actionLabel: null,
  );

  static String searchEmpty(String? query) =>
      query != null ? 'Rien trouvé pour "$query"' : 'Aucun résultat';

  static const searchSubtitle =
      'Essaie avec d\'autres mots ou vérifie l\'orthographe.';
}

// =============================================================================
// APP EMPTY WIDGET - Widget d'état vide émotionnel
// =============================================================================

/// Widget d'état vide réutilisable avec ton émotionnel et animations.
///
/// Design moderne avec animation d'entrée subtile et microcopy
/// motivant pour les livreurs.
///
/// Utiliser les factory constructors pour les cas courants :
/// ```dart
/// AppEmptyWidget.deliveries(onRefresh: () => ref.refresh(deliveriesProvider))
/// AppEmptyWidget.earnings()
/// AppEmptyWidget.chat()
/// ```
class AppEmptyWidget extends StatefulWidget {
  const AppEmptyWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.iconSize = 64,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.animate = true,
  });

  /// Message principal affiché.
  final String message;

  /// Icône affichée en haut.
  final IconData icon;

  /// Couleur de l'icône (accent color par défaut).
  final Color? iconColor;

  /// Taille de l'icône.
  final double iconSize;

  /// Sous-titre optionnel affiché sous le message.
  final String? subtitle;

  /// Libellé du bouton d'action optionnel.
  final String? actionLabel;

  /// Callback du bouton d'action.
  final VoidCallback? onAction;

  /// Icône du bouton d'action.
  final IconData? actionIcon;

  /// Animer l'apparition (défaut: true).
  final bool animate;

  // ===========================================================================
  // FACTORY CONSTRUCTORS - Cas d'usage courants
  // ===========================================================================

  /// Empty state pour liste de livraisons disponibles
  factory AppEmptyWidget.deliveries({VoidCallback? onRefresh}) {
    return AppEmptyWidget(
      icon: Icons.local_shipping_outlined,
      message: _EmotionalCopy.deliveries.title,
      subtitle: _EmotionalCopy.deliveries.subtitle,
      actionLabel: onRefresh != null
          ? _EmotionalCopy.deliveries.actionLabel
          : null,
      actionIcon: Icons.refresh_rounded,
      onAction: onRefresh,
      iconColor: Colors.blue,
    );
  }

  /// Empty state pour livraisons en cours
  factory AppEmptyWidget.activeDeliveries({VoidCallback? onGoOnline}) {
    return AppEmptyWidget(
      icon: Icons.delivery_dining_rounded,
      message: _EmotionalCopy.activeDeliveries.title,
      subtitle: _EmotionalCopy.activeDeliveries.subtitle,
      actionLabel: onGoOnline != null
          ? _EmotionalCopy.activeDeliveries.actionLabel
          : null,
      actionIcon: Icons.power_settings_new_rounded,
      onAction: onGoOnline,
      iconColor: Colors.green,
    );
  }

  /// Empty state pour historique de courses
  factory AppEmptyWidget.history() {
    return AppEmptyWidget(
      icon: Icons.history_rounded,
      message: _EmotionalCopy.history.title,
      subtitle: _EmotionalCopy.history.subtitle,
      iconColor: Colors.grey,
    );
  }

  /// Empty state pour gains/wallet
  factory AppEmptyWidget.earnings() {
    return AppEmptyWidget(
      icon: Icons.account_balance_wallet_outlined,
      message: _EmotionalCopy.earnings.title,
      subtitle: _EmotionalCopy.earnings.subtitle,
      iconColor: Colors.amber,
    );
  }

  /// Empty state pour chat
  factory AppEmptyWidget.chat() {
    return AppEmptyWidget(
      icon: Icons.chat_bubble_outline_rounded,
      message: _EmotionalCopy.chat.title,
      subtitle: _EmotionalCopy.chat.subtitle,
      iconColor: Colors.cyan,
    );
  }

  /// Empty state pour défis/gamification
  factory AppEmptyWidget.challenges({VoidCallback? onViewBadges}) {
    return AppEmptyWidget(
      icon: Icons.emoji_events_outlined,
      message: _EmotionalCopy.challenges.title,
      subtitle: _EmotionalCopy.challenges.subtitle,
      actionLabel: onViewBadges != null
          ? _EmotionalCopy.challenges.actionLabel
          : null,
      actionIcon: Icons.military_tech_rounded,
      onAction: onViewBadges,
      iconColor: Colors.orange,
    );
  }

  /// Empty state pour support/tickets
  factory AppEmptyWidget.support({VoidCallback? onContact}) {
    return AppEmptyWidget(
      icon: Icons.support_agent_outlined,
      message: _EmotionalCopy.support.title,
      subtitle: _EmotionalCopy.support.subtitle,
      actionLabel: onContact != null
          ? _EmotionalCopy.support.actionLabel
          : null,
      actionIcon: Icons.headset_mic_rounded,
      onAction: onContact,
      iconColor: Colors.purple,
    );
  }

  /// Empty state pour courses groupées
  factory AppEmptyWidget.batch() {
    return AppEmptyWidget(
      icon: Icons.layers_outlined,
      message: _EmotionalCopy.batch.title,
      subtitle: _EmotionalCopy.batch.subtitle,
      iconColor: Colors.indigo,
    );
  }

  /// Empty state pour notifications
  factory AppEmptyWidget.notifications() {
    return AppEmptyWidget(
      icon: Icons.notifications_none_rounded,
      message: _EmotionalCopy.notifications.title,
      subtitle: _EmotionalCopy.notifications.subtitle,
      iconColor: Colors.teal,
    );
  }

  /// Empty state pour résultats de recherche
  factory AppEmptyWidget.search({String? query}) {
    return AppEmptyWidget(
      icon: Icons.search_off_rounded,
      message: _EmotionalCopy.searchEmpty(query),
      subtitle: _EmotionalCopy.searchSubtitle,
      iconColor: Colors.grey,
    );
  }

  @override
  State<AppEmptyWidget> createState() => _AppEmptyWidgetState();
}

class _AppEmptyWidgetState extends State<AppEmptyWidget>
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
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
    final isDark = context.isDark;
    final accentColor = widget.iconColor ?? Theme.of(context).primaryColor;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône avec fond coloré
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.iconSize,
                    color: accentColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 24),

                // Titre
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Sous-titre
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Bouton d'action
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: widget.onAction,
                    icon: Icon(
                      widget.actionIcon ?? Icons.refresh_rounded,
                      size: 18,
                    ),
                    label: Text(widget.actionLabel!),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
