import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/advanced_battery_service.dart';
import '../widgets/battery/advanced_battery_widgets.dart';

/// Écran de gestion avancée de la batterie
class BatteryOptimizationScreen extends ConsumerWidget {
  const BatteryOptimizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Économie de batterie'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // État actuel de la batterie
          const AdvancedBatteryWidget(
            showGraph: true,
            showProfile: true,
          ),
          const SizedBox(height: 24),

          // Optimisation automatique
          const AutoOptimizeSwitch(),
          const SizedBox(height: 24),

          // Conseils d'optimisation
          const OptimizationTipsList(),
          const SizedBox(height: 16),

          // Sélection du profil
          const PowerProfileSelector(),
          const SizedBox(height: 24),

          // Paramètres avancés
          _AdvancedSettingsSection(isDark: isDark),
          const SizedBox(height: 24),

          // Informations
          _InfoSection(isDark: isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Section des paramètres avancés
class _AdvancedSettingsSection extends ConsumerWidget {
  final bool isDark;

  const _AdvancedSettingsSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryAsync = ref.watch(advancedBatteryStateProvider);

    return batteryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Paramètres du profil actuel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.gps_fixed,
                  title: 'Intervalle GPS',
                  value: '${state.activeProfile.gpsIntervalSeconds} secondes',
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _SettingRow(
                  icon: Icons.straighten,
                  title: 'Filtre de distance',
                  value: '${state.activeProfile.distanceFilterMeters} mètres',
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _SettingRow(
                  icon: Icons.my_location,
                  title: 'Précision GPS',
                  value: _formatAccuracy(state.activeProfile.accuracy),
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _SettingRow(
                  icon: Icons.animation,
                  title: 'Animations',
                  value: state.activeProfile.enableAnimations ? 'Activées' : 'Désactivées',
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _SettingRow(
                  icon: Icons.vibration,
                  title: 'Vibrations',
                  value: state.activeProfile.enableVibration ? 'Activées' : 'Désactivées',
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _SettingRow(
                  icon: Icons.sync,
                  title: 'Sync auto',
                  value: state.activeProfile.enableAutoSync
                      ? 'Toutes les ${state.activeProfile.syncIntervalMinutes} min'
                      : 'Désactivée',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAccuracy(dynamic accuracy) {
    final accStr = accuracy.toString();
    if (accStr.contains('bestForNavigation')) return 'Navigation';
    if (accStr.contains('high')) return 'Haute';
    if (accStr.contains('medium')) return 'Moyenne';
    if (accStr.contains('low')) return 'Basse';
    return 'Standard';
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Section d'informations
class _InfoSection extends StatelessWidget {
  final bool isDark;

  const _InfoSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Comment ça marche',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoItem(
            title: 'Performance',
            description: 'GPS précis toutes les 3 secondes. Idéal pour les livraisons rapides.',
          ),
          const SizedBox(height: 8),
          _InfoItem(
            title: 'Équilibré',
            description: 'Bon compromis entre précision et autonomie. GPS toutes les 10 secondes.',
          ),
          const SizedBox(height: 8),
          _InfoItem(
            title: 'Économie',
            description: 'Réduit la fréquence GPS à 20 secondes pour préserver la batterie.',
          ),
          const SizedBox(height: 8),
          _InfoItem(
            title: 'Ultra économie',
            description: 'Mode minimal. GPS toutes les 45 secondes. Animations désactivées.',
          ),
          const SizedBox(height: 12),
          Text(
            '💡 L\'optimisation automatique ajuste le profil selon votre niveau de batterie.',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String title;
  final String description;

  const _InfoItem({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
