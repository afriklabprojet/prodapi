import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive.dart';

/// Widget pour afficher l'ETA (temps estimé d'arrivée) de manière claire
class ETADisplayWidget extends StatelessWidget {
  final String? duration; // e.g., "12 min", "1 hour 5 mins"
  final String? distance; // e.g., "3.5 km"
  final bool isCompact;
  final bool showArrivalTime;

  const ETADisplayWidget({
    super.key,
    this.duration,
    this.distance,
    this.isCompact = false,
    this.showArrivalTime = true,
  });

  @override
  Widget build(BuildContext context) {
    if (duration == null && distance == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCompact) {
      return _buildCompactView(isDark);
    }

    return _buildFullView(context, isDark);
  }

  Widget _buildCompactView(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.blue.shade900.withValues(alpha: 0.3) 
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_filled,
            size: 16,
            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            duration ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
              fontSize: 14,
            ),
          ),
          if (distance != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 14,
              color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
            ),
            Icon(
              Icons.route,
              size: 14,
              color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              distance!,
              style: TextStyle(
                color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context, bool isDark) {
    final arrivalTime = _calculateArrivalTime();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blue.shade900, Colors.blue.shade800]
              : [Colors.blue.shade600, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // ETA principale
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Temps estimé',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      duration ?? '--',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.r.sp(28),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Séparateur
              Container(
                width: 1,
                height: 50,
                color: Colors.white24,
              ),
              
              // Distance
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.route, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Distance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      distance ?? '--',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.r.sp(28),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Heure d'arrivée estimée
          if (showArrivalTime && arrivalTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Arrivée prévue : $arrivalTime',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  /// Calcule l'heure d'arrivée estimée basée sur la durée
  String? _calculateArrivalTime() {
    if (duration == null) return null;

    final minutes = _parseDurationMinutes(duration!);
    if (minutes <= 0) return null;

    final arrival = DateTime.now().add(Duration(minutes: minutes));
    return DateFormat('HH:mm').format(arrival);
  }

  /// Parse la durée string en minutes
  int _parseDurationMinutes(String durationStr) {
    int totalMinutes = 0;

    // Pattern: "X hour(s) Y min(s)" ou "X min(s)"
    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(durationStr.toLowerCase());
    final minMatch = RegExp(r'(\d+)\s*min').firstMatch(durationStr.toLowerCase());

    if (hourMatch != null) {
      totalMinutes += int.parse(hourMatch.group(1)!) * 60;
    }
    if (minMatch != null) {
      totalMinutes += int.parse(minMatch.group(1)!);
    }

    // Si seulement des chiffres (ex: "12")
    if (totalMinutes == 0) {
      final numMatch = RegExp(r'(\d+)').firstMatch(durationStr);
      if (numMatch != null) {
        totalMinutes = int.parse(numMatch.group(1)!);
      }
    }

    return totalMinutes;
  }
}

/// Badge compact pour l'ETA à afficher dans un header ou une card
class ETABadge extends StatelessWidget {
  final String duration;
  final Color? backgroundColor;
  final Color? textColor;

  const ETABadge({
    super.key,
    required this.duration,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? Colors.green.shade900 : Colors.green.shade100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: textColor ?? (isDark ? Colors.green.shade300 : Colors.green.shade700),
          ),
          const SizedBox(width: 4),
          Text(
            duration,
            style: TextStyle(
              color: textColor ?? (isDark ? Colors.green.shade300 : Colors.green.shade700),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget en direct avec mise à jour automatique de l'ETA
class LiveETAWidget extends StatefulWidget {
  final String? initialDuration;
  final String? distance;
  final DateTime? startTime;
  final bool autoUpdate;

  const LiveETAWidget({
    super.key,
    this.initialDuration,
    this.distance,
    this.startTime,
    this.autoUpdate = true,
  });

  @override
  State<LiveETAWidget> createState() => _LiveETAWidgetState();
}

class _LiveETAWidgetState extends State<LiveETAWidget> {
  late String? _currentDuration;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.initialDuration;
  }

  @override
  void didUpdateWidget(LiveETAWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDuration != oldWidget.initialDuration) {
      _currentDuration = widget.initialDuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ETADisplayWidget(
      duration: _currentDuration,
      distance: widget.distance,
      isCompact: false,
      showArrivalTime: true,
    );
  }
}
