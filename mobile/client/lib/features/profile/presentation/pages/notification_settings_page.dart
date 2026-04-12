import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_logger.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _prescriptionUpdates = true;
  bool _deliveryAlerts = true;
  bool _loaded = false;
  bool _syncing = false;

  static const _keyOrderUpdates = 'notif_order_updates';
  static const _keyPromotions = 'notif_promotions';
  static const _keyPrescriptions = 'notif_prescriptions';
  static const _keyDelivery = 'notif_delivery';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _fetchFromServer();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _orderUpdates = prefs.getBool(_keyOrderUpdates) ?? true;
        _promotions = prefs.getBool(_keyPromotions) ?? true;
        _prescriptionUpdates = prefs.getBool(_keyPrescriptions) ?? true;
        _deliveryAlerts = prefs.getBool(_keyDelivery) ?? true;
        _loaded = true;
      });
    }
  }

  Future<void> _fetchFromServer() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        ApiConstants.notificationPreferences,
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null || !mounted) return;

      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _orderUpdates = data['order_updates'] as bool? ?? true;
        _promotions = data['promotions'] as bool? ?? true;
        _prescriptionUpdates = data['prescriptions'] as bool? ?? true;
        _deliveryAlerts = data['delivery_alerts'] as bool? ?? true;
      });
      await prefs.setBool(_keyOrderUpdates, _orderUpdates);
      await prefs.setBool(_keyPromotions, _promotions);
      await prefs.setBool(_keyPrescriptions, _prescriptionUpdates);
      await prefs.setBool(_keyDelivery, _deliveryAlerts);
    } catch (e) {
      AppLogger.debug('[NotifSettings] Failed to fetch from server: $e');
    }
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _syncToServer() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.put(
        ApiConstants.notificationPreferences,
        data: {
          'order_updates': _orderUpdates,
          'promotions': _promotions,
          'prescriptions': _prescriptionUpdates,
          'delivery_alerts': _deliveryAlerts,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Préférences synchronisées'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      AppLogger.debug('[NotifSettings] Failed to sync to server: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Synchronisation échouée (sauvegardé localement)'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Gérez vos préférences de notifications',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                _buildSwitch(
                  title: 'Mises à jour des commandes',
                  subtitle: 'Recevez des notifications sur vos commandes',
                  icon: Icons.shopping_bag_outlined,
                  value: _orderUpdates,
                  onChanged: (v) {
                    setState(() => _orderUpdates = v);
                    _savePref(_keyOrderUpdates, v);
                    _syncToServer();
                  },
                ),
                const Divider(height: 1, indent: 72),
                _buildSwitch(
                  title: 'Promotions',
                  subtitle: 'Offres et réductions',
                  icon: Icons.local_offer_outlined,
                  value: _promotions,
                  onChanged: (v) {
                    setState(() => _promotions = v);
                    _savePref(_keyPromotions, v);
                    _syncToServer();
                  },
                ),
                const Divider(height: 1, indent: 72),
                _buildSwitch(
                  title: 'Ordonnances',
                  subtitle: 'Statut de vos ordonnances',
                  icon: Icons.description_outlined,
                  value: _prescriptionUpdates,
                  onChanged: (v) {
                    setState(() => _prescriptionUpdates = v);
                    _savePref(_keyPrescriptions, v);
                    _syncToServer();
                  },
                ),
                const Divider(height: 1, indent: 72),
                _buildSwitch(
                  title: 'Alertes livraison',
                  subtitle: 'Suivi de livraison en temps réel',
                  icon: Icons.delivery_dining_outlined,
                  value: _deliveryAlerts,
                  onChanged: (v) {
                    setState(() => _deliveryAlerts = v);
                    _savePref(_keyDelivery, v);
                    _syncToServer();
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}
