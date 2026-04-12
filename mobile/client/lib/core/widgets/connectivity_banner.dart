import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';
import '../services/offline_queue_service.dart';

/// Wrap autour de l'app pour afficher un bandeau hors-ligne persistant.
///
/// Usage dans MaterialApp.router :
/// ```dart
/// builder: (context, child) => ConnectivityBanner(child: child!),
/// ```
class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectivityProvider);
    final queueState = ref.watch(offlineQueueProvider);

    // Déterminer l'état à afficher
    final showOffline = !isConnected;
    final showSyncing = isConnected && queueState.isSyncing;
    final showPending = isConnected && queueState.hasPending && !queueState.isSyncing;
    final showBanner = showOffline || showSyncing || showPending;

    return Column(
      children: [
        // Contenu principal (prend tout l'espace disponible)
        Expanded(child: child),

        // Bannière contextuelle en bas
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: showBanner ? 40 : 0,
          color: _getBannerColor(showOffline, showSyncing),
          width: double.infinity,
          child: !showBanner
              ? const SizedBox.shrink()
              : SafeArea(
                  top: false,
                  child: Center(
                    child: _BannerContent(
                      isOffline: showOffline,
                      isSyncing: showSyncing,
                      pendingCount: queueState.pendingCount,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Color _getBannerColor(bool isOffline, bool isSyncing) {
    if (isOffline) return Colors.orange.shade700;
    if (isSyncing) return Colors.blue.shade600;
    return Colors.green.shade600; // Pending but connected
  }
}

class _BannerContent extends StatelessWidget {
  final bool isOffline;
  final bool isSyncing;
  final int pendingCount;

  const _BannerContent({
    required this.isOffline,
    required this.isSyncing,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    if (isOffline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            pendingCount > 0
                ? 'Hors ligne · $pendingCount action${pendingCount > 1 ? 's' : ''} en attente'
                : 'Hors ligne · Données en cache',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (isSyncing) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Synchronisation en cours...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // Pending actions, now connected
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(
          '$pendingCount action${pendingCount > 1 ? 's' : ''} prête${pendingCount > 1 ? 's' : ''} à envoyer',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
