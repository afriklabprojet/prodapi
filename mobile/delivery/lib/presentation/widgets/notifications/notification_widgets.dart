import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/rich_notification_service.dart';
import '../../../core/theme/theme_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CARTE DE PRÉFÉRENCES DE NOTIFICATION
// ══════════════════════════════════════════════════════════════════════════════

/// Carte complète de configuration des notifications
class NotificationPreferencesCard extends ConsumerStatefulWidget {
  const NotificationPreferencesCard({super.key});

  @override
  ConsumerState<NotificationPreferencesCard> createState() => _NotificationPreferencesCardState();
}

class _NotificationPreferencesCardState extends ConsumerState<NotificationPreferencesCard> {
  @override
  Widget build(BuildContext context) {
    final service = ref.watch(richNotificationProvider.notifier);
    final prefs = service.preferences;
    final isDark = ref.watch(isDarkModeProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF54AB70), Color(0xFF3D8C57)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'Personnalisez vos alertes',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Son et vibration
          _buildSwitchTile(
            icon: Icons.volume_up,
            iconColor: Colors.blue,
            title: 'Sons',
            subtitle: 'Jouer un son pour les alertes',
            value: prefs.soundEnabled,
            onChanged: (value) => _updatePrefs(prefs.copyWith(soundEnabled: value)),
          ),
          _buildSwitchTile(
            icon: Icons.vibration,
            iconColor: Colors.purple,
            title: 'Vibration',
            subtitle: 'Vibrer à la réception',
            value: prefs.vibrationEnabled,
            onChanged: (value) => _updatePrefs(prefs.copyWith(vibrationEnabled: value)),
          ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
            child: Text(
              'TYPES DE NOTIFICATIONS',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),

          // Types de notifications
          _buildSwitchTile(
            icon: Icons.local_shipping,
            iconColor: Colors.green,
            title: 'Nouvelles commandes',
            subtitle: 'Alertes pour les courses disponibles',
            value: prefs.newOrdersEnabled,
            onChanged: (value) => _updatePrefs(prefs.copyWith(newOrdersEnabled: value)),
          ),
          _buildSwitchTile(
            icon: Icons.chat_bubble,
            iconColor: Colors.blue,
            title: 'Messages',
            subtitle: 'Messages des clients et pharmacies',
            value: prefs.chatEnabled,
            onChanged: (value) => _updatePrefs(prefs.copyWith(chatEnabled: value)),
          ),
          _buildSwitchTile(
            icon: Icons.attach_money,
            iconColor: Colors.amber,
            title: 'Gains',
            subtitle: 'Notifications de paiements et revenus',
            value: prefs.earningsEnabled,
            onChanged: (value) => _updatePrefs(prefs.copyWith(earningsEnabled: value)),
          ),
          _buildSwitchTile(
            icon: Icons.local_offer,
            iconColor: Colors.orange,
            title: 'Promotions',
            subtitle: 'Offres spéciales et bonus',
            value: prefs.promosEnabled,
            onChanged: (value) => _updatePrefs(prefs.copyWith(promosEnabled: value)),
          ),
          _buildSwitchTile(
            icon: Icons.warning_amber,
            iconColor: Colors.red,
            title: 'Alertes urgentes',
            subtitle: 'Notifications importantes (recommandé)',
            value: prefs.urgentEnabled,
            onChanged: (value) => _updatePrefs(prefs.copyWith(urgentEnabled: value)),
          ),

          const Divider(height: 1),
          
          // Heures calmes
          _buildQuietHoursSection(prefs, isDark),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = ref.watch(isDarkModeProvider);
    
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF54AB70),
      ),
    );
  }

  Widget _buildQuietHoursSection(NotificationPreferences prefs, bool isDark) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.nightlight_round, color: Colors.indigo, size: 20),
      ),
      title: const Text('Heures calmes', style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        prefs.quietHoursEnabled
            ? 'Actif: ${prefs.quietHoursStart}h - ${prefs.quietHoursEnd}h'
            : 'Désactivé',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      children: [
        SwitchListTile(
          title: const Text('Activer les heures calmes'),
          subtitle: const Text('Réduire les notifications pendant la nuit'),
          value: prefs.quietHoursEnabled,
          onChanged: (value) => _updatePrefs(prefs.copyWith(quietHoursEnabled: value)),
          activeTrackColor: const Color(0xFF54AB70),
        ),
        if (prefs.quietHoursEnabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    label: 'Début',
                    hour: prefs.quietHoursStart,
                    onChanged: (hour) => _updatePrefs(prefs.copyWith(quietHoursStart: hour)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimePicker(
                    label: 'Fin',
                    hour: prefs.quietHoursEnd,
                    onChanged: (hour) => _updatePrefs(prefs.copyWith(quietHoursEnd: hour)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required int hour,
    required ValueChanged<int> onChanged,
  }) {
    final isDark = ref.watch(isDarkModeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: hour,
            isExpanded: true,
            underline: const SizedBox(),
            items: List.generate(24, (i) => DropdownMenuItem(
              value: i,
              child: Text('${i.toString().padLeft(2, '0')}:00'),
            )),
            onChanged: (value) => onChanged(value ?? hour),
          ),
        ),
      ],
    );
  }

  void _updatePrefs(NotificationPreferences newPrefs) {
    ref.read(richNotificationProvider.notifier).savePreferences(newPrefs);
    setState(() {});
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INDICATEUR DE NOTIFICATIONS NON LUES
// ══════════════════════════════════════════════════════════════════════════════

/// Badge de compteur de notifications non lues
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.child,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationCountProvider);
    
    if (count == 0 && !showZero) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              count > 99 ? '99+' : count.toString(),
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
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CENTRE DE NOTIFICATIONS
// ══════════════════════════════════════════════════════════════════════════════

/// Écran du centre de notifications
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(richNotificationProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(richNotificationProvider.notifier).markAllAsRead();
              },
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return NotificationCard(
                  notification: notifications[index],
                  onTap: () {
                    ref.read(richNotificationProvider.notifier)
                        .markAsRead(notifications[index].id);
                  },
                  onDismiss: () {
                    ref.read(richNotificationProvider.notifier)
                        .removeNotification(notifications[index].id);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous recevrez ici vos alertes\net nouvelles commandes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'une notification individuelle
class NotificationCard extends StatelessWidget {
  final RichNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: notification.isRead
            ? (isDark ? Colors.grey.shade900 : Colors.white)
            : (isDark ? Colors.grey.shade800 : Colors.blue.shade50),
        elevation: notification.isRead ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: notification.isRead
              ? BorderSide.none
              : BorderSide(color: notification.type.priority == Priority.max 
                  ? Colors.orange.shade300 
                  : Colors.blue.shade200),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    notification.type.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                      if (notification.actions != null && 
                          notification.actions!.isNotEmpty &&
                          !notification.isRead) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: notification.actions!.map((action) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _ActionButton(
                                action: action,
                                notificationId: notification.id,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Colors.green;
      case NotificationType.orderAssigned:
        return Colors.blue;
      case NotificationType.urgent:
        return Colors.red;
      case NotificationType.earnings:
        return Colors.amber;
      case NotificationType.chat:
        return Colors.purple;
      case NotificationType.promo:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _ActionButton extends ConsumerWidget {
  final NotificationAction action;
  final String notificationId;

  const _ActionButton({
    required this.action,
    required this.notificationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () {
        // Trigger l'action
        ref.read(richNotificationProvider.notifier).onNotificationAction?.call(
          notificationId,
          action.id,
          null,
        );
        ref.read(richNotificationProvider.notifier).markAsRead(notificationId);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: action.destructive ? Colors.red : const Color(0xFF54AB70),
        side: BorderSide(
          color: action.destructive ? Colors.red : const Color(0xFF54AB70),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        action.label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BOUTON DE NOTIFICATIONS POUR L'APPBAR
// ══════════════════════════════════════════════════════════════════════════════

/// Bouton de notifications avec badge pour l'AppBar
class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationBadge(
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
          );
        },
      ),
    );
  }
}
