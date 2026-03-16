import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_detail_sheet.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  /// Formattage intelligent de la date (ex: "Il y a 5 min")
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd MMM yyyy', 'fr').format(date);
    }
  }

  /// Détermine l'icône et la couleur en fonction du type de notification
  ({IconData icon, Color color}) _getNotificationStyle(String type, String title) {
    return switch (type) {
      'new_order' || 'new_order_received' => (icon: Icons.shopping_bag_outlined, color: Colors.blue),
      'order_status' => (icon: Icons.sync_outlined, color: Colors.indigo),
      'delivery_assigned' => (icon: Icons.delivery_dining_outlined, color: Colors.teal),
      'courier_arrived' || 'courier_arrived_at_client' => (icon: Icons.location_on_outlined, color: Colors.deepOrange),
      'delivery_timeout_cancelled' => (icon: Icons.timer_off_outlined, color: Colors.red),
      'order_delivered' => (icon: Icons.check_circle_outline, color: Colors.green),
      'low_stock' => (icon: Icons.inventory_2_outlined, color: Colors.orange),
      'payment' || 'payout_completed' => (icon: Icons.account_balance_wallet_outlined, color: Colors.green),
      'new_prescription' || 'prescription_status' => (icon: Icons.medical_services_outlined, color: Colors.purple),
      'chat_message' => (icon: Icons.chat_bubble_outline, color: Colors.cyan),
      'kyc_status_update' => (icon: Icons.verified_user_outlined, color: Colors.amber),
      _ => (icon: Icons.notifications_outlined, color: Colors.teal),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
             // En-tête amélioré
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: isDark ? null : const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Bouton retour
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => context.pop(),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Icône et titre
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade600,
                          Colors.orange.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Texte
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          '${state.notifications.where((n) => !n.isRead).length} non lues',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bouton marquer tout comme lu
                  if (state.notifications.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.done_all_rounded, color: primaryColor),
                        tooltip: 'Tout marquer comme lu',
                        onPressed: () {
                          ref.read(notificationsProvider.notifier).markAllAsRead();
                        },
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: Builder(
                builder: (context) {
                  // --- LOADING ---
                  if (state.isLoading) {
                    return Center(child: CircularProgressIndicator(color: primaryColor));
                  }

                  // --- ERREUR (Senior Design) ---
                  if (state.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.orange.withValues(alpha: 0.2) : const Color(0xFFFFF3E0),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 48,
                                color: Colors.orange[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Erreur de chargement',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Impossible de récupérer les notifications pour le moment.\nVérifiez votre connexion et réessayez.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ref.read(notificationsProvider.notifier).loadNotifications();
                                },
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                label: const Text(
                                  'Réessayer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shadowColor: primaryColor.withValues(alpha: 0.3),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // --- EMPTY ---
                  if (state.notifications.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.notifications_none_rounded, size: 48, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Aucune notification',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Vous êtes à jour. Les commandes, alertes stock et paiements apparaîtront ici.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // --- LISTE ---
                  return RefreshIndicator(
                    color: primaryColor,
                    backgroundColor: isDark ? AppColors.cardColor(context) : Colors.white,
                    onRefresh: () => ref.read(notificationsProvider.notifier).loadNotifications(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: state.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = state.notifications[index];
                        final isUnread = !notification.isRead;
                        final style = _getNotificationStyle(notification.type, notification.title);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isUnread 
                                ? (isDark ? AppColors.cardColor(context) : Colors.white)
                                : (isDark ? Colors.grey[850] : const Color(0xFFFCFCFC)),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isDark ? [] : [
                              BoxShadow(
                                color: const Color(0xFF8D8D8D).withValues(alpha: isUnread ? 0.08 : 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: isUnread 
                              ? Border.all(color: primaryColor.withValues(alpha: 0.1), width: 1.5) 
                              : Border.all(color: isDark ? Colors.grey[700]! : Colors.transparent),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (!notification.isRead) {
                                  ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                                }
                                NotificationDetailSheet.show(context, notification);
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icône dynamique
                                    Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isUnread 
                                                ? style.color.withValues(alpha: isDark ? 0.2 : 0.1) 
                                                : (isDark ? Colors.grey[800] : Colors.grey[100]),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            style.icon,
                                            color: isUnread ? style.color : (isDark ? Colors.grey[400] : Colors.grey[500]),
                                            size: 24,
                                          ),
                                        ),
                                        if (isUnread)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: isDark ? AppColors.cardColor(context) : Colors.white, width: 2),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    // Texte
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification.title,
                                                  style: TextStyle(
                                                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                                    fontSize: 16,
                                                    color: isUnread 
                                                        ? (isDark ? Colors.white : Colors.black87) 
                                                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _formatDate(notification.createdAt),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isUnread ? primaryColor : (isDark ? Colors.grey[500] : Colors.grey[400]),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notification.body,
                                            style: TextStyle(
                                              color: isUnread 
                                                  ? (isDark ? Colors.grey[300] : Colors.grey[800]) 
                                                  : (isDark ? Colors.grey[500] : Colors.grey[500]),
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
