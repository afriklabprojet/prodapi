import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../l10n/app_localizations.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _orderNotifications = true;
  bool _stockAlerts = true;
  bool _promotionNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '07:00';
  bool _quietHoursEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushEnabled = prefs.getBool('notif_push_enabled') ?? true;
      _emailEnabled = prefs.getBool('notif_email_enabled') ?? false;
      _orderNotifications = prefs.getBool('notif_orders') ?? true;
      _stockAlerts = prefs.getBool('notif_stock') ?? true;
      _promotionNotifications = prefs.getBool('notif_promotions') ?? true;
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
      _quietHoursEnabled = prefs.getBool('notif_quiet_hours') ?? false;
      _quietHoursStart = prefs.getString('notif_quiet_start') ?? '22:00';
      _quietHoursEnd = prefs.getString('notif_quiet_end') ?? '07:00';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_push_enabled', _pushEnabled);
    await prefs.setBool('notif_email_enabled', _emailEnabled);
    await prefs.setBool('notif_orders', _orderNotifications);
    await prefs.setBool('notif_stock', _stockAlerts);
    await prefs.setBool('notif_promotions', _promotionNotifications);
    await prefs.setBool('notif_sound', _soundEnabled);
    await prefs.setBool('notif_vibration', _vibrationEnabled);
    await prefs.setBool('notif_quiet_hours', _quietHoursEnabled);
    await prefs.setString('notif_quiet_start', _quietHoursStart);
    await prefs.setString('notif_quiet_end', _quietHoursEnd);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres sauvegardés')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(AppLocalizations.of(context).save, style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Section Canaux
          _buildSectionHeader('Canaux de notification'),
          _buildSwitchTile(
            'Notifications push',
            'Recevoir des notifications sur cet appareil',
            Icons.notifications_active_outlined,
            _pushEnabled,
            (v) => setState(() => _pushEnabled = v),
          ),
          _buildSwitchTile(
            'Notifications email',
            'Recevoir des résumés par email',
            Icons.email_outlined,
            _emailEnabled,
            (v) => setState(() => _emailEnabled = v),
          ),

          const Divider(height: 32),

          // Section Types
          _buildSectionHeader('Types de notifications'),
          _buildSwitchTile(
            'Commandes',
            'Nouvelles commandes, mises à jour de statut',
            Icons.shopping_bag_outlined,
            _orderNotifications,
            (v) => setState(() => _orderNotifications = v),
            enabled: _pushEnabled,
          ),
          _buildSwitchTile(
            'Alertes de stock',
            'Stock bas, produits expirés',
            Icons.inventory_2_outlined,
            _stockAlerts,
            (v) => setState(() => _stockAlerts = v),
            enabled: _pushEnabled,
          ),
          _buildSwitchTile(
            'Promotions',
            'Offres spéciales, événements',
            Icons.local_offer_outlined,
            _promotionNotifications,
            (v) => setState(() => _promotionNotifications = v),
            enabled: _pushEnabled,
          ),

          const Divider(height: 32),

          // Section Son et Vibration
          _buildSectionHeader('Son et vibration'),
          _buildSwitchTile(
            'Son',
            'Jouer un son pour les notifications',
            Icons.volume_up_outlined,
            _soundEnabled,
            (v) => setState(() => _soundEnabled = v),
            enabled: _pushEnabled,
          ),
          _buildSwitchTile(
            'Vibration',
            'Vibrer pour les notifications',
            Icons.vibration,
            _vibrationEnabled,
            (v) => setState(() => _vibrationEnabled = v),
            enabled: _pushEnabled,
          ),

          const Divider(height: 32),

          // Section Heures silencieuses
          _buildSectionHeader('Heures silencieuses'),
          _buildSwitchTile(
            'Activer les heures silencieuses',
            'Pas de notifications pendant certaines heures',
            Icons.bedtime_outlined,
            _quietHoursEnabled,
            (v) => setState(() => _quietHoursEnabled = v),
            enabled: _pushEnabled,
          ),
          if (_quietHoursEnabled && _pushEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      'Début',
                      _quietHoursStart,
                      (time) => setState(() => _quietHoursStart = time),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      'Fin',
                      _quietHoursEnd,
                      (time) => setState(() => _quietHoursEnd = time),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled
              ? (isDark ? Colors.white : Colors.black87)
              : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
      trailing: Switch.adaptive(
        value: value && enabled,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTimePicker(String label, String time, ValueChanged<String> onChanged) {
    return InkWell(
      onTap: () async {
        final parts = time.split(':');
        final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
        final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final initialTime = TimeOfDay(hour: hour, minute: minute);
        
        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        
        if (picked != null) {
          onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
