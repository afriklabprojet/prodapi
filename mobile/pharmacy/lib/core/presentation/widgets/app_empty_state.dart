import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Messages émotionnels contextuels pour les états vides.
/// Ton conversationnel et rassurant, pas informatif froid.
class _EmotionalCopy {
  static const orders = (
    title: 'Calme plat pour l\'instant',
    subtitle: 'On te notifie dès qu\'un client passe commande. Profite pour vérifier ton stock !',
    actionLabel: 'Vérifier l\'inventaire',
  );
  
  static const prescriptions = (
    title: 'Pas d\'ordonnance en attente',
    subtitle: 'Les nouvelles ordonnances apparaîtront ici. Tu seras alerté instantanément.',
    actionLabel: 'Actualiser',
  );
  
  static const inventory = (
    title: 'Ton inventaire est vide',
    subtitle: 'Ajoute tes premiers produits pour que les clients puissent commander. Ça prend 2 minutes !',
    actionLabel: 'Ajouter un produit',
  );
  
  static const notifications = (
    title: 'Tout est lu !',
    subtitle: 'Bravo, tu es à jour. Les nouvelles alertes apparaîtront ici.',
    actionLabel: null,
  );
  
  static const team = (
    title: 'Travaille en équipe',
    subtitle: 'Invite tes collègues pour partager la charge de travail et ne jamais rater une commande.',
    actionLabel: 'Inviter quelqu\'un',
  );
  
  static const chat = (
    title: 'Aucun message',
    subtitle: 'Quand un client te contacte, la conversation apparaît ici. Réponds vite pour un bon service !',
    actionLabel: null,
  );
  
  static const transactions = (
    title: 'Aucune transaction encore',
    subtitle: 'Tes revenus et mouvements financiers s\'afficheront ici dès ta première vente.',
    actionLabel: null,
  );
  
  static String searchEmpty(String? query) => query != null 
      ? 'Rien trouvé pour "$query"'
      : 'Aucun résultat';
  
  static const searchSubtitle = 'Essaie avec d\'autres mots ou vérifie l\'orthographe.';
}

/// Widget réutilisable pour afficher un état vide avec style émotionnel.
/// 
/// Design moderne avec animation d'entrée et ton conversationnel
/// pour humaniser l'expérience et réduire l'anxiété utilisateur.
class AppEmptyState extends StatefulWidget {
  /// Icône illustrative de l'état vide
  final IconData icon;
  
  /// Titre principal (ton conversationnel)
  final String title;
  
  /// Sous-titre explicatif optionnel
  final String? subtitle;
  
  /// Label du bouton d'action optionnel
  final String? actionLabel;
  
  /// Callback du bouton d'action
  final VoidCallback? onAction;
  
  /// Icône du bouton d'action (défaut: refresh)
  final IconData? actionIcon;
  
  /// Couleur d'accent (optionnelle)
  final Color? accentColor;

  const AppEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.accentColor,
    super.key,
  });

  // Factory constructors avec microcopy émotionnel
  
  /// Empty state pour liste de commandes
  factory AppEmptyState.orders({VoidCallback? onRefresh, VoidCallback? onInventory}) {
    return AppEmptyState(
      icon: Icons.shopping_bag_outlined,
      title: _EmotionalCopy.orders.title,
      subtitle: _EmotionalCopy.orders.subtitle,
      actionLabel: onInventory != null ? _EmotionalCopy.orders.actionLabel : (onRefresh != null ? 'Actualiser' : null),
      actionIcon: onInventory != null ? Icons.inventory_2_rounded : Icons.refresh_rounded,
      onAction: onInventory ?? onRefresh,
      accentColor: Colors.orange,
    );
  }

  /// Empty state pour inventaire
  factory AppEmptyState.inventory({VoidCallback? onAdd}) {
    return AppEmptyState(
      icon: Icons.inventory_2_outlined,
      title: _EmotionalCopy.inventory.title,
      subtitle: _EmotionalCopy.inventory.subtitle,
      actionLabel: onAdd != null ? _EmotionalCopy.inventory.actionLabel : null,
      actionIcon: Icons.add_rounded,
      onAction: onAdd,
      accentColor: Colors.indigo,
    );
  }

  /// Empty state pour ordonnances
  factory AppEmptyState.prescriptions({VoidCallback? onRefresh}) {
    return AppEmptyState(
      icon: Icons.description_outlined,
      title: _EmotionalCopy.prescriptions.title,
      subtitle: _EmotionalCopy.prescriptions.subtitle,
      actionLabel: onRefresh != null ? _EmotionalCopy.prescriptions.actionLabel : null,
      onAction: onRefresh,
      accentColor: Colors.teal,
    );
  }

  /// Empty state pour notifications
  factory AppEmptyState.notifications() {
    return AppEmptyState(
      icon: Icons.notifications_none_outlined,
      title: _EmotionalCopy.notifications.title,
      subtitle: _EmotionalCopy.notifications.subtitle,
      accentColor: Colors.blue,
    );
  }

  /// Empty state pour équipe
  factory AppEmptyState.team({VoidCallback? onAdd}) {
    return AppEmptyState(
      icon: Icons.people_outline,
      title: _EmotionalCopy.team.title,
      subtitle: _EmotionalCopy.team.subtitle,
      actionLabel: onAdd != null ? _EmotionalCopy.team.actionLabel : null,
      actionIcon: Icons.person_add_rounded,
      onAction: onAdd,
      accentColor: Colors.purple,
    );
  }

  /// Empty state pour chat
  factory AppEmptyState.chat() {
    return AppEmptyState(
      icon: Icons.chat_bubble_outline,
      title: _EmotionalCopy.chat.title,
      subtitle: _EmotionalCopy.chat.subtitle,
      accentColor: Colors.cyan,
    );
  }

  /// Empty state pour résultats de recherche
  factory AppEmptyState.search({String? query}) {
    return AppEmptyState(
      icon: Icons.search_off_rounded,
      title: _EmotionalCopy.searchEmpty(query),
      subtitle: _EmotionalCopy.searchSubtitle,
      accentColor: Colors.grey,
    );
  }

  /// Empty state pour transactions wallet
  factory AppEmptyState.transactions() {
    return AppEmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: _EmotionalCopy.transactions.title,
      subtitle: _EmotionalCopy.transactions.subtitle,
      accentColor: Colors.green,
    );
  }

  @override
  State<AppEmptyState> createState() => _AppEmptyStateState();
}

class _AppEmptyStateState extends State<AppEmptyState> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accentColor = widget.accentColor ?? AppColors.primary;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône avec animation de scale
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 0.15),
                          accentColor.withValues(alpha: 0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 48,
                      color: accentColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                
                // Titre avec style émotionnel
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Sous-titre optionnel
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                // Bouton d'action avec style amélioré
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: widget.onAction,
                    icon: Icon(widget.actionIcon ?? Icons.refresh_rounded, size: 18),
                    label: Text(widget.actionLabel!),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
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
