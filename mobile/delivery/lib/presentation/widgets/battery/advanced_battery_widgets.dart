import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/advanced_battery_service.dart';
import '../../../core/utils/responsive.dart';

/// Widget d'affichage avancé de la batterie avec graphique
class AdvancedBatteryWidget extends ConsumerWidget {
  final bool showGraph;
  final bool showProfile;

  const AdvancedBatteryWidget({
    super.key,
    this.showGraph = true,
    this.showProfile = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryAsync = ref.watch(advancedBatteryStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return batteryAsync.when(
      loading: () => const _LoadingWidget(),
      error: (_, _) => const _ErrorWidget(),
      data: (state) => _BatteryDisplay(
        state: state,
        isDark: isDark,
        showGraph: showGraph,
        showProfile: showProfile,
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Text('Impossible de lire la batterie'),
      ),
    );
  }
}

class _BatteryDisplay extends StatelessWidget {
  final AdvancedBatteryState state;
  final bool isDark;
  final bool showGraph;
  final bool showProfile;

  const _BatteryDisplay({
    required this.state,
    required this.isDark,
    required this.showGraph,
    required this.showProfile,
  });

  Color get _levelColor => Color(state.levelColorValue);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header avec niveau et état
          Row(
            children: [
              // Icône batterie animée
              _AnimatedBatteryIcon(
                level: state.level,
                isCharging: state.isCharging,
                color: _levelColor,
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${state.level}%',
                          style: TextStyle(
                            fontSize: context.r.sp(32),
                            fontWeight: FontWeight.bold,
                            color: _levelColor,
                          ),
                        ),
                        if (state.isCharging) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.bolt,
                            color: Colors.green.shade600,
                            size: 24,
                          ),
                        ],
                      ],
                    ),
                    if (state.stats != null)
                      Text(
                        'Reste environ ${state.stats!.remainingTimeFormatted}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              // Mode actif
              if (showProfile)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getProfileColor(state.activeProfile).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getProfileIcon(state.activeProfile),
                        color: _getProfileColor(state.activeProfile),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.activeProfile.name,
                        style: TextStyle(
                          color: _getProfileColor(state.activeProfile),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Graphique historique
          if (showGraph && state.levelHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            _BatteryHistoryChart(
              history: state.levelHistory,
              isDark: isDark,
            ),
          ],

          // Statistiques de consommation
          if (state.stats != null) ...[
            const SizedBox(height: 16),
            _UsageBreakdown(
              stats: state.stats!,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Color _getProfileColor(PowerProfile profile) {
    switch (profile.id) {
      case 'performance':
        return Colors.blue;
      case 'balanced':
        return Colors.green;
      case 'battery_saver':
        return Colors.orange;
      case 'ultra_saver':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getProfileIcon(PowerProfile profile) {
    switch (profile.id) {
      case 'performance':
        return Icons.speed;
      case 'balanced':
        return Icons.balance;
      case 'battery_saver':
        return Icons.battery_saver;
      case 'ultra_saver':
        return Icons.battery_alert;
      default:
        return Icons.battery_std;
    }
  }
}

/// Icône de batterie animée
class _AnimatedBatteryIcon extends StatefulWidget {
  final int level;
  final bool isCharging;
  final Color color;

  const _AnimatedBatteryIcon({
    required this.level,
    required this.isCharging,
    required this.color,
  });

  @override
  State<_AnimatedBatteryIcon> createState() => _AnimatedBatteryIconState();
}

class _AnimatedBatteryIconState extends State<_AnimatedBatteryIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isCharging) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedBatteryIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCharging && !oldWidget.isCharging) {
      _controller.repeat(reverse: true);
    } else if (!widget.isCharging && oldWidget.isCharging) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCharging ? _pulseAnimation.value : 1.0,
          child: CustomPaint(
            size: const Size(50, 70),
            painter: _BatteryPainter(
              level: widget.level,
              color: widget.color,
              isCharging: widget.isCharging,
            ),
          ),
        );
      },
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final int level;
  final Color color;
  final bool isCharging;

  _BatteryPainter({
    required this.level,
    required this.color,
    required this.isCharging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Corps de la batterie
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 10, size.width - 10, size.height - 15),
      const Radius.circular(6),
    );
    paint.color = color.withValues(alpha: 0.5);
    canvas.drawRRect(bodyRect, paint);

    // Borne supérieure
    final terminalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 8, 2, 16, 10),
      const Radius.circular(3),
    );
    canvas.drawRRect(terminalRect, paint);

    // Niveau de remplissage
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final maxHeight = size.height - 25;
    final fillHeight = maxHeight * (level / 100);
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        8,
        10 + maxHeight - fillHeight + 3,
        size.width - 16,
        fillHeight - 3,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(fillRect, fillPaint);

    // Éclair si en charge
    if (isCharging) {
      final boltPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final boltPath = Path()
        ..moveTo(size.width / 2 + 2, 25)
        ..lineTo(size.width / 2 - 6, 40)
        ..lineTo(size.width / 2, 40)
        ..lineTo(size.width / 2 - 2, 55)
        ..lineTo(size.width / 2 + 8, 38)
        ..lineTo(size.width / 2 + 2, 38)
        ..close();

      canvas.drawPath(boltPath, boltPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.color != color ||
        oldDelegate.isCharging != isCharging;
  }
}

/// Graphique d'historique de batterie
class _BatteryHistoryChart extends StatelessWidget {
  final List<int> history;
  final bool isDark;

  const _BatteryHistoryChart({
    required this.history,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(
          history: history,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<int> history;
  final bool isDark;

  _ChartPainter({
    required this.history,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paint = Paint()
      ..color = Colors.green.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.green.shade400.withValues(alpha: 0.3),
          Colors.green.shade400.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final dx = size.width / (history.length - 1);

    for (var i = 0; i < history.length; i++) {
      final x = i * dx;
      final y = size.height - (history[i] / 100 * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Point actuel
    final lastX = (history.length - 1) * dx;
    final lastY = size.height - (history.last / 100 * size.height);
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = Colors.green.shade600,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}

/// Répartition de l'utilisation
class _UsageBreakdown extends StatelessWidget {
  final BatteryUsageStats stats;
  final bool isDark;

  const _UsageBreakdown({
    required this.stats,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.grey.shade400,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Utilisation par fonctionnalité',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: stats.usageByFeature.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Expanded(
                flex: item.value.toInt(),
                child: Container(
                  height: 8,
                  color: colors[index % colors.length],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: stats.usageByFeature.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.key} (${item.value.toInt()}%)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Sélecteur de profil d'énergie
class PowerProfileSelector extends ConsumerWidget {
  const PowerProfileSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryAsync = ref.watch(advancedBatteryStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return batteryAsync.when(
      loading: () => const _LoadingWidget(),
      error: (_, _) => const _ErrorWidget(),
      data: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Mode d\'énergie',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ...PowerProfile.all.map((profile) {
            final isSelected = state.activeProfile.id == profile.id;
            return _ProfileCard(
              profile: profile,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () {
                ref.read(advancedBatteryServiceProvider).setProfile(profile);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final PowerProfile profile;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.profile,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  Color get _profileColor {
    switch (profile.id) {
      case 'performance':
        return Colors.blue;
      case 'balanced':
        return Colors.green;
      case 'battery_saver':
        return Colors.orange;
      case 'ultra_saver':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get _profileIcon {
    switch (profile.id) {
      case 'performance':
        return Icons.speed;
      case 'balanced':
        return Icons.balance;
      case 'battery_saver':
        return Icons.battery_saver;
      case 'ultra_saver':
        return Icons.battery_alert;
      default:
        return Icons.battery_std;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? _profileColor.withValues(alpha: 0.15)
                  : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _profileColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _profileColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_profileIcon, color: _profileColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? _profileColor
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.description,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _ProfileStat(
                            icon: Icons.gps_fixed,
                            value: '${profile.gpsIntervalSeconds}s',
                            color: _profileColor,
                          ),
                          const SizedBox(width: 12),
                          _ProfileStat(
                            icon: Icons.straighten,
                            value: '${profile.distanceFilterMeters}m',
                            color: _profileColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: _profileColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Switch pour l'optimisation automatique
class AutoOptimizeSwitch extends ConsumerWidget {
  const AutoOptimizeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryAsync = ref.watch(advancedBatteryStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return batteryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optimisation automatique',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Ajuste le profil selon le niveau de batterie',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: state.autoOptimizeEnabled,
              onChanged: (value) {
                ref.read(advancedBatteryServiceProvider).setAutoOptimize(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste des conseils d'optimisation
class OptimizationTipsList extends ConsumerWidget {
  const OptimizationTipsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tips = ref.watch(optimizationTipsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Conseils d\'optimisation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        ...tips.map((tip) => _OptimizationTipCard(tip: tip, isDark: isDark)),
      ],
    );
  }
}

class _OptimizationTipCard extends StatelessWidget {
  final OptimizationTip tip;
  final bool isDark;

  const _OptimizationTipCard({
    required this.tip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(tip.icon, style: TextStyle(fontSize: context.r.sp(24))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  tip.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${tip.estimatedSavingsPercent}%',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicateur compact de batterie pour l'AppBar
class CompactBatteryIndicator extends ConsumerWidget {
  const CompactBatteryIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryAsync = ref.watch(advancedBatteryStateProvider);

    return batteryAsync.when(
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const Icon(Icons.battery_unknown, size: 20),
      data: (state) => Tooltip(
        message: '${state.level}% - ${state.activeProfile.name}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color(state.levelColorValue).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.isCharging
                    ? Icons.battery_charging_full
                    : (state.level <= 20
                        ? Icons.battery_alert
                        : Icons.battery_std),
                color: Color(state.levelColorValue),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${state.level}%',
                style: TextStyle(
                  color: Color(state.levelColorValue),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
