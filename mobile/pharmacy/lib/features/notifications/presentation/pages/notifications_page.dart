import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../core/presentation/widgets/app_error_state.dart';
import '../../../../core/presentation/widgets/skeleton_screens.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_detail_sheet.dart';
import '../../../dashboard/presentation/providers/dashboard_tab_provider.dart';
import '../../../dashboard/presentation/providers/activity_sub_tab_provider.dart';

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

  /// Détermine la section de date pour le groupage
  String _getDateSection(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isAtSameMomentAs(today) || dateOnly.isAfter(today)) {
      return "Aujourd'hui";
    } else if (dateOnly.isAtSameMomentAs(yesterday)) {
      return 'Hier';
    } else if (dateOnly.isAfter(weekAgo)) {
      return 'Cette semaine';
    } else {
      return 'Plus ancien';
    }
  }

  /// Groupe les notifications par section de date
  Map<String, List<dynamic>> _groupNotificationsByDate(List<dynamic> notifications) {
    final Map<String, List<dynamic>> grouped = {
      "Aujourd'hui": [],
      'Hier': [],
      'Cette semaine': [],
      'Plus ancien': [],
    };

    for (final notification in notifications) {
      final section = _getDateSection(notification.createdAt);
      grouped[section]!.add(notification);
    }

    // Retirer les sections vides
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  /// Détermine l'icône et la couleur en fonction du type de notification
  ({IconData icon, Color color}) _getNotificationStyle(
    String type,
    String title,
  ) {
    return switch (type) {
      'new_order' || 'new_order_received' => (
        icon: Icons.shopping_bag_outlined,
        color: Colors.blue.shade700,
      ),
      'order_status' => (icon: Icons.sync_outlined, color: Colors.indigo),
      'delivery_assigned' => (
        icon: Icons.delivery_dining_outlined,
        color: Colors.teal,
      ),
      'courier_arrived' || 'courier_arrived_at_client' => (
        icon: Icons.location_on_outlined,
        color: Colors.deepOrange,
      ),
      'delivery_timeout_cancelled' => (
        icon: Icons.timer_off_outlined,
        color: Colors.red,
      ),
      'order_delivered' => (
        icon: Icons.check_circle_outline,
        color: Colors.green,
      ),
      'low_stock' => (icon: Icons.inventory_2_outlined, color: Colors.orange),
      'payment' || 'payout_completed' => (
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.green,
      ),
      'new_prescription' || 'prescription_status' => (
        icon: Icons.medical_services_outlined,
        color: Colors.purple,
      ),
      'chat_message' => (icon: Icons.chat_bubble_outline, color: Colors.cyan),
      'kyc_status_update' => (
        icon: Icons.verified_user_outlined,
        color: Colors.amber,
      ),
      _ => (icon: Icons.notifications_outlined, color: Colors.teal),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête amélioré
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: isDark
                    ? null
                    : const [
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
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => context.pop(),
                      tooltip: 'Retour',
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
                        colors: [Colors.amber.shade600, Colors.orange.shade400],
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
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
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
                          ref
                              .read(notificationsProvider.notifier)
                              .markAllAsRead();
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
                    return SkeletonListBuilder.notifications();
                  }

                  // --- ERREUR ---
                  if (state.error != null) {
                    return AppErrorState.loadFailed(
                      onRetry: () => ref
                          .read(notificationsProvider.notifier)
                          .loadNotifications(),
                      what: 'les notifications',
                    );
                  }

                  // --- EMPTY ---
                  if (state.notifications.isEmpty) {
                    return AppEmptyState.notifications();
                  }

                  // --- LISTE GROUPÉE PAR JOUR ---
                  final groupedNotifications = _groupNotificationsByDate(state.notifications);
                  final sectionOrder = ["Aujourd'hui", 'Hier', 'Cette semaine', 'Plus ancien'];
                  final orderedSections = sectionOrder.where((s) => groupedNotifications.containsKey(s)).toList();
                  
                  // Créer une liste plate avec headers et items
                  final List<dynamic> flatList = [];
                  for (final section in orderedSections) {
                    flatList.add({'type': 'header', 'section': section});
                    for (final notification in groupedNotifications[section]!) {
                      flatList.add({'type': 'item', 'notification': notification});
                    }
                  }
                  
                  return RefreshIndicator(
                    color: primaryColor,
                    backgroundColor: isDark
                        ? AppColors.cardColor(context)
                        : Colors.white,
                    onRefresh: () => ref
                        .read(notificationsProvider.notifier)
                        .loadNotifications(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: flatList.length,
                      itemBuilder: (context, index) {
                        final item = flatList[index];
                        
                        // Section header
                        if (item['type'] == 'header') {
                          return Padding(
                            padding: EdgeInsets.only(
                              top: index == 0 ? 0 : 24,
                              bottom: 12,
                            ),
                            child: Text(
                              item['section'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }
                        
                        // Notification item
                        final notification = item['notification'];
                        final isUnread = !notification.isRead;
                        final style = _getNotificationStyle(
                          notification.type,
                          notification.title,
                        );

                        return Semantics(
                          button: true,
                          label:
                              '${isUnread ? "Non lue : " : ""}${notification.title}, ${notification.body}, ${_formatDate(notification.createdAt)}',
                          hint: 'Appuyer pour voir les détails',
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? (isDark
                                        ? AppColors.cardColor(context)
                                        : Colors.white)
                                  : (isDark
                                        ? Colors.grey[850]
                                        : const Color(0xFFFCFCFC)),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF8D8D8D)
                                            .withValues(
                                              alpha: isUnread ? 0.08 : 0.03,
                                            ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                              border: isUnread
                                  ? Border.all(
                                      color: primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      width: 1.5,
                                    )
                                  : Border.all(
                                      color: isDark
                                          ? Colors.grey[700]!
                                          : Colors.transparent,
                                    ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (!notification.isRead) {
                                    ref
                                        .read(notificationsProvider.notifier)
                                        .markAsRead(notification.id);
                                  }
                                  final type = notification.type;
                                  final data = notification.data ?? {};
                                  if (type == 'new_order' ||
                                      type == 'new_order_received') {
                                    final orderId = int.tryParse(
                                      data['order_id']?.toString() ?? '',
                                    );
                                    if (orderId != null) {
                                      context.push('/orders/$orderId');
                                      return;
                                    }
                                  }
                                  if (type == 'new_prescription' ||
                                      type == 'prescription_status') {
                                    ref
                                            .read(
                                              activitySubTabProvider.notifier,
                                            )
                                            .state =
                                        1;
                                    ref
                                            .read(dashboardTabProvider.notifier)
                                            .state =
                                        1;
                                    context.pop();
                                    return;
                                  }
                                  if (type == 'low_stock') {
                                    ref
                                            .read(dashboardTabProvider.notifier)
                                            .state =
                                        2;
                                    context.pop();
                                    return;
                                  }
                                  NotificationDetailSheet.show(
                                    context,
                                    notification,
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Icône dynamique
                                      Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isUnread
                                                  ? style.color.withValues(
                                                      alpha: isDark ? 0.2 : 0.1,
                                                    )
                                                  : (isDark
                                                        ? Colors.grey[800]
                                                        : Colors.grey[100]),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              style.icon,
                                              color: isUnread
                                                  ? style.color
                                                  : (isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[500]),
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
                                                  border: Border.all(
                                                    color: isDark
                                                        ? AppColors.cardColor(
                                                            context,
                                                          )
                                                        : Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      // Texte
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notification.title,
                                                    style: TextStyle(
                                                      fontWeight: isUnread
                                                          ? FontWeight.w800
                                                          : FontWeight.w600,
                                                      fontSize: 16,
                                                      color: isUnread
                                                          ? (isDark
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87)
                                                          : (isDark
                                                                ? Colors
                                                                      .grey[300]
                                                                : Colors
                                                                      .grey[700]),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _formatDate(
                                                    notification.createdAt,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isUnread
                                                        ? primaryColor
                                                        : (isDark
                                                              ? Colors.grey[500]
                                                              : Colors
                                                                    .grey[400]),
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
                                                    ? (isDark
                                                          ? Colors.grey[300]
                                                          : Colors.grey[800])
                                                    : (isDark
                                                          ? Colors.grey[500]
                                                          : Colors.grey[500]),
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
