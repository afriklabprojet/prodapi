import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../providers/courier_heatmap_provider.dart';

class HeatmapOpportunitiesOverlay extends ConsumerWidget {
  final void Function(double lat, double lng)? onNavigateToZone;

  const HeatmapOpportunitiesOverlay({super.key, this.onNavigateToZone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courierHeatmapProvider);
    final opportunities = state.opportunities;

    if (state.isLoading && opportunities.isEmpty) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: 168,
        child: _buildLoadingCard(context),
      );
    }

    if (opportunities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 168,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignTokens.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Zones chaudes proches',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        ref.read(courierHeatmapProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                    tooltip: 'Actualiser',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: opportunities.take(5).map((o) {
                    final heatColor = _heatColor(o.heatLevel);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onNavigateToZone?.call(o.lat, o.lng);
                        },
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: heatColor.withValues(alpha: 0.12),
                            border: Border.all(
                              color: heatColor.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${o.distanceKm.toStringAsFixed(1)} km  •  ${o.pendingOrders} cmd',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: heatColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '~${o.potentialEarnings} F CFA',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DesignTokens.primary.withValues(alpha: 0.2),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Analyse des zones chaudes...',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Color _heatColor(String level) {
    switch (level) {
      case 'extreme':
        return const Color(0xFF7C3AED);
      case 'hot':
        return const Color(0xFFEF4444);
      case 'warm':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}
