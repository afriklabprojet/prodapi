import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import 'pending_actions_sheet.dart';

/// Widget qui affiche un banner quand l'application est hors ligne
class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);

    return Column(
      children: [
        // Banner de connectivité
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: connectivityState.isConnected ? 0 : null,
          child: connectivityState.isConnected
              ? const SizedBox.shrink()
              : _OfflineBanner(
                  pendingCount: connectivityState.pendingActionsCount,
                ),
        ),
        // Contenu principal
        Expanded(child: child),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final int pendingCount;

  const _OfflineBanner({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => PendingActionsSheet.show(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.orange.withRed(230)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Mode hors ligne',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      pendingCount > 0
                          ? '$pendingCount action(s) en attente • Touchez pour voir'
                          : 'Continuez à travailler, on synchronise quand ça revient',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicateur visuel qu'on peut toucher
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  pendingCount > 0
                      ? Icons.expand_more_rounded
                      : Icons.sync_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget qui affiche un indicateur de synchronisation
class SyncIndicator extends StatefulWidget {
  final bool isSyncing;
  final int pendingCount;
  final VoidCallback? onTap;

  const SyncIndicator({
    super.key,
    required this.isSyncing,
    this.pendingCount = 0,
    this.onTap,
  });

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    if (widget.isSyncing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing && !oldWidget.isSyncing) {
      _controller.repeat();
    } else if (!widget.isSyncing && oldWidget.isSyncing) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSyncing && widget.pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isSyncing ? Colors.blue : Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isSyncing)
              RotationTransition(
                turns: _controller,
                child: const Icon(Icons.sync, color: Colors.white, size: 16),
              )
            else
              const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.white,
                size: 16,
              ),
            const SizedBox(width: 6),
            Text(
              widget.isSyncing
                  ? 'Sync...'
                  : '${widget.pendingCount} en attente',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Snackbar personnalisé pour le statut de connexion
class ConnectionSnackbar {
  static void showOffline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Vous êtes hors ligne. Les modifications seront synchronisées.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showOnline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Connexion rétablie'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showSyncComplete(BuildContext context, int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white),
            const SizedBox(width: 12),
            Text('$count élément(s) synchronisé(s)'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
