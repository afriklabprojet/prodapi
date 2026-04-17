import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/simple_html_text.dart';
import '../../../data/models/route_info.dart';

/// Bottom sheet affichant les étapes détaillées de l'itinéraire
class ItinerarySheet extends StatelessWidget {
  final RouteInfo routeInfo;

  const ItinerarySheet({super.key, required this.routeInfo});

  /// Affiche le sheet depuis n'importe quel écran
  static void show(BuildContext context, RouteInfo routeInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItinerarySheet(routeInfo: routeInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20, top: 8),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Itinéraire',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${routeInfo.totalDistance} • ${routeInfo.totalDuration}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            const Divider(height: 30),
            // Steps
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: routeInfo.steps.length,
                itemBuilder: (context, index) {
                  final step = routeInfo.steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.directions, color: context.iconColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SimpleHtmlText(
                                data: step.instruction,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${step.distance} • ${step.duration}',
                                style: TextStyle(fontSize: 12, color: context.secondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
