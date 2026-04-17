import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Widget pour afficher un état vide avec illustration
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon avec cercle en arrière-plan
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
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
    );
  }
}

/// État vide pour les produits
class EmptyProductsState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const EmptyProductsState({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Aucun produit',
      message: 'Nous n\'avons trouvé aucun produit.\nVeuillez réessayer plus tard.',
      actionLabel: 'Actualiser',
      onAction: onRefresh,
      iconColor: AppColors.primary,
    );
  }
}

/// État vide pour la recherche de produits
class EmptySearchState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onClear;

  const EmptySearchState({
    super.key,
    required this.searchQuery,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'Aucun résultat',
      message: 'Nous n\'avons trouvé aucun produit pour "$searchQuery".\nEssayez avec d\'autres mots-clés.',
      actionLabel: 'Effacer la recherche',
      onAction: onClear,
      iconColor: AppColors.secondary,
    );
  }
}

/// État vide pour les commandes
class EmptyOrdersState extends StatelessWidget {
  final VoidCallback? onBrowseProducts;

  const EmptyOrdersState({super.key, this.onBrowseProducts});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Aucune commande',
      message: 'Vous n\'avez pas encore passé de commande.\nCommencez à parcourir nos produits !',
      actionLabel: 'Parcourir les produits',
      onAction: onBrowseProducts,
      iconColor: AppColors.accent,
    );
  }
}

/// État vide pour le panier
class EmptyCartState extends StatelessWidget {
  final VoidCallback? onBrowseProducts;

  const EmptyCartState({super.key, this.onBrowseProducts});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Panier vide',
      message: 'Votre panier est vide.\nAjoutez des produits pour commencer vos achats !',
      actionLabel: 'Voir les produits',
      onAction: onBrowseProducts,
      iconColor: AppColors.primary,
    );
  }
}

/// État vide pour les notifications
class EmptyNotificationsState extends StatelessWidget {
  const EmptyNotificationsState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.notifications_none,
      title: 'Aucune notification',
      message: 'Vous n\'avez aucune notification pour le moment.\nNous vous tiendrons informé !',
      iconColor: AppColors.accent,
    );
  }
}
