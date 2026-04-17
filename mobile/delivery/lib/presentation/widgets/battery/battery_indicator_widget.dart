import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/battery_saver_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/responsive.dart';

/// Widget d'affichage de l'état de la batterie avec mode économie
class BatteryIndicatorWidget extends ConsumerWidget {
  final bool compact;

  const BatteryIndicatorWidget({super.key, this.compact = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryAsync = ref.watch(batteryStateProvider);
    final isDark = context.isDark;

    return batteryAsync.when(
      loading: () => compact
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const _LoadingCard(),
      error: (_, e) => compact
          ? Tooltip(
              message: 'Batterie indisponible',
              child: Icon(
                Icons.battery_unknown,
                size: 20,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            )
          : _ErrorCard(isDark: isDark),
      data: (state) => compact
          ? _CompactBatteryIndicator(state: state, isDark: isDark)
          : _BatteryCard(state: state, isDark: isDark),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Chargement...'),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final bool isDark;

  const _ErrorCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.battery_unknown,
              color: Colors.red.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batterie indisponible',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Impossible de lire le niveau de batterie',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactBatteryIndicator extends StatelessWidget {
  final BatteryStatus state;
  final bool isDark;

  const _CompactBatteryIndicator({required this.state, required this.isDark});

  Color get _batteryColor {
    if (state.isCharging) return Colors.green;
    if (state.level <= BatteryThresholds.critical) return Colors.red;
    if (state.level <= BatteryThresholds.low) return Colors.orange;
    return Colors.green;
  }

  IconData get _batteryIcon {
    if (state.isCharging) return Icons.battery_charging_full;
    if (state.level <= 20) return Icons.battery_alert;
    if (state.level <= 50) return Icons.battery_3_bar;
    return Icons.battery_full;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${state.level}% - ${state.modeDescription}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _batteryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_batteryIcon, color: _batteryColor, size: 18),
            const SizedBox(width: 4),
            Text(
              '${state.level}%',
              style: TextStyle(
                color: _batteryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (state.mode == BatterySaverMode.saver ||
                state.mode == BatterySaverMode.critical) ...[
              const SizedBox(width: 4),
              Icon(Icons.eco, color: Colors.green.shade700, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  final BatteryStatus state;
  final bool isDark;

  const _BatteryCard({required this.state, required this.isDark});

  Color get _batteryColor {
    if (state.isCharging) return Colors.green;
    if (state.level <= BatteryThresholds.critical) return Colors.red;
    if (state.level <= BatteryThresholds.low) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BatteryGauge(level: state.level, color: _batteryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.level}%',
                      style: TextStyle(
                        fontSize: context.r.sp(28),
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      state.modeDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: _batteryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _batteryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isCharging ? Icons.bolt : Icons.gps_fixed,
                      color: _batteryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.isCharging
                          ? 'En charge'
                          : '${state.gpsUpdateIntervalSeconds}s',
                      style: TextStyle(
                        color: _batteryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.mode == BatterySaverMode.saver ||
              state.mode == BatterySaverMode.critical) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.mode == BatterySaverMode.critical
                          ? 'Mode économie critique: GPS minimal'
                          : 'Mode économie: GPS basse fréquence',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatteryGauge extends StatelessWidget {
  final int level;
  final Color color;

  const _BatteryGauge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 70,
      child: CustomPaint(
        painter: _BatteryPainter(level: level, color: color),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final int level;
  final Color color;

  _BatteryPainter({required this.level, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Corps de la batterie
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 8, size.width, size.height - 8),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, paint);

    // Tip de la batterie
    final tipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, 10),
      const Radius.circular(2),
    );
    canvas.drawRRect(tipRect, paint);

    // Remplissage
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final fillHeight = (size.height - 16) * (level / 100);
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        4,
        size.height - fillHeight - 4,
        size.width - 8,
        fillHeight,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(fillRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}

/// Bottom sheet pour les paramètres d'économie de batterie
class BatterySaverSettingsSheet extends ConsumerStatefulWidget {
  const BatterySaverSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BatterySaverSettingsSheet(),
    );
  }

  @override
  ConsumerState<BatterySaverSettingsSheet> createState() =>
      _BatterySaverSettingsSheetState();
}

class _BatterySaverSettingsSheetState
    extends ConsumerState<BatterySaverSettingsSheet> {
  bool _batterySaverEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ref.read(batterySaverServiceProvider);
    final enabled = await service.isBatterySaverEnabled();
    if (!mounted) return;
    setState(() => _batterySaverEnabled = enabled);
  }

  Future<void> _toggleBatterySaver(bool enabled) async {
    final service = ref.read(batterySaverServiceProvider);
    await service.setBatterySaverEnabled(enabled);
    setState(() => _batterySaverEnabled = enabled);
    ref.invalidate(batteryStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final batteryAsync = ref.watch(batteryStateProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Icon(
                    Icons.battery_saver,
                    color: Colors.green.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Économie de batterie',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // État actuel
              batteryAsync.maybeWhen(
                data: (state) => BatteryIndicatorWidget(compact: false),
                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              // Toggle mode économie
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco,
                      color: _batterySaverEnabled ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode économie automatique',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Réduit le GPS quand la batterie est < 20%',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _batterySaverEnabled,
                      onChanged: _toggleBatterySaver,
                      activeTrackColor: Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Info sur les modes
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modes GPS',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ModeInfoRow(
                      icon: Icons.gps_fixed,
                      label: 'Normal (> 50%)',
                      value: 'Mise à jour: 5s, Haute précision',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 4),
                    _ModeInfoRow(
                      icon: Icons.gps_not_fixed,
                      label: 'Économie (20-50%)',
                      value: 'Mise à jour: 15s, Précision moyenne',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 4),
                    _ModeInfoRow(
                      icon: Icons.gps_off,
                      label: 'Critique (< 20%)',
                      value: 'Mise à jour: 30s, Basse précision',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ModeInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
