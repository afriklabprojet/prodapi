import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';

/// Overlay affiché quand le coursier est hors ligne (pas de livraison active)
class OfflineOverlay extends StatelessWidget {
  const OfflineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 80, color: Colors.white54),
            const SizedBox(height: 20),
            Text(
              'VOUS ÊTES HORS LIGNE',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.r.sp(24),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Passez en ligne pour recevoir des commandes',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
