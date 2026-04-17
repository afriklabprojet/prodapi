import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../providers/core_providers.dart' as core;

/// États de connectivité.
enum ConnectivityStatus { online, offline, weak }

/// Provider pour l'état de connectivité en temps réel.
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  final controller = StreamController<ConnectivityStatus>();

  // Check initial
  Connectivity().checkConnectivity().then((results) {
    controller.add(_mapConnectivity(results));
  });

  // Écouter les changements
  final subscription = Connectivity().onConnectivityChanged.listen((results) {
    controller.add(_mapConnectivity(results));
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

ConnectivityStatus _mapConnectivity(List<ConnectivityResult> results) {
  if (results.isEmpty || results.contains(ConnectivityResult.none)) {
    return ConnectivityStatus.offline;
  }
  return ConnectivityStatus.online;
}

/// Provider pour la dernière heure de synchronisation.
final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Provider pour mettre à jour le timestamp de synchro.
final syncNotifierProvider = Provider((ref) => SyncNotifier(ref));

class SyncNotifier {
  final Ref ref;
  static const _lastSyncKey = 'last_sync_time';

  SyncNotifier(this.ref) {
    _loadLastSync();
  }

  Future<void> _loadLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    if (timestamp != null) {
      ref.read(lastSyncTimeProvider.notifier).state =
          DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  Future<void> updateSyncTime() async {
    final now = DateTime.now();
    ref.read(lastSyncTimeProvider.notifier).state = now;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
  }
}

/// Bannière de statut de synchronisation.
/// S'affiche quand l'app est hors ligne pour informer l'utilisateur.
class SyncStatusBanner extends ConsumerWidget {
  /// Afficher même quand online (avec "Dernière synchro").
  final bool showWhenOnline;

  /// Callback pour forcer une synchro.
  final VoidCallback? onRetrySync;

  const SyncStatusBanner({
    super.key,
    this.showWhenOnline = false,
    this.onRetrySync,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return 'jamais';

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'à l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'il y a ${diff.inHours}h';
    } else {
      return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);
    final isDark = AppColors.isDark(context);
    final coreConnectivity = ref.watch(core.connectivityProvider);
    final pendingCount = coreConnectivity.pendingActionsCount;

    return connectivity.when(
      data: (status) {
        if (status == ConnectivityStatus.offline) {
          return _OfflineBanner(
            lastSync: lastSync,
            formatTime: _formatTime,
            onRetry: onRetrySync,
            isDark: isDark,
            pendingActionsCount: pendingCount,
          );
        }

        // Show pending actions banner even when online (syncing in progress)
        if (pendingCount > 0) {
          return _SyncingBanner(pendingCount: pendingCount, isDark: isDark);
        }

        if (showWhenOnline && lastSync != null) {
          return _OnlineBanner(
            lastSync: lastSync,
            formatTime: _formatTime,
            isDark: isDark,
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        debugPrint('[SyncStatusBanner] Error: $error');
        return const SizedBox.shrink();
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final DateTime? lastSync;
  final String Function(DateTime?) formatTime;
  final VoidCallback? onRetry;
  final bool isDark;
  final int pendingActionsCount;

  const _OfflineBanner({
    required this.lastSync,
    required this.formatTime,
    this.onRetry,
    required this.isDark,
    this.pendingActionsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingActionsCount > 0;

    return Semantics(
      liveRegion: true,
      label: hasPending
          ? 'Mode hors ligne. $pendingActionsCount action${pendingActionsCount > 1 ? 's' : ''} en attente de synchronisation'
          : 'Mode hors ligne. Dernière synchronisation ${formatTime(lastSync)}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.orange.shade900.withValues(alpha: 0.4)
              : Colors.orange.shade50,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.orange.shade800 : Colors.orange.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 16,
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mode hors ligne',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.orange.shade200
                          : Colors.orange.shade800,
                    ),
                  ),
                  if (hasPending)
                    Text(
                      '$pendingActionsCount action${pendingActionsCount > 1 ? 's' : ''} en attente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.orange.shade300
                            : Colors.orange.shade700,
                      ),
                    )
                  else
                    Text(
                      'Dernière synchro ${formatTime(lastSync)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.orange.shade300
                            : Colors.orange.shade700,
                      ),
                    ),
                ],
              ),
            ),
            if (hasPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pending_actions_rounded,
                      size: 14,
                      color: isDark
                          ? Colors.orange.shade200
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$pendingActionsCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.orange.shade200
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              )
            else if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: isDark
                      ? Colors.orange.shade200
                      : Colors.orange.shade700,
                ),
                label: Text(
                  'Réessayer',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.orange.shade200
                        : Colors.orange.shade700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(48, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bannière de synchronisation en cours (quand retour online avec pending actions)
class _SyncingBanner extends StatelessWidget {
  final int pendingCount;
  final bool isDark;

  const _SyncingBanner({required this.pendingCount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label:
          'Synchronisation en cours. $pendingCount action${pendingCount > 1 ? 's' : ''} en attente.',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.blue.shade900.withValues(alpha: 0.4)
              : Colors.blue.shade50,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.blue.shade800 : Colors.blue.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Synchronisation en cours',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.blue.shade200
                          : Colors.blue.shade800,
                    ),
                  ),
                  Text(
                    '$pendingCount action${pendingCount > 1 ? 's' : ''} en attente',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.blue.shade300
                          : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineBanner extends StatelessWidget {
  final DateTime lastSync;
  final String Function(DateTime?) formatTime;
  final bool isDark;

  const _OnlineBanner({
    required this.lastSync,
    required this.formatTime,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.green.shade900.withValues(alpha: 0.2)
            : Colors.green.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_done_outlined,
            size: 14,
            color: isDark ? Colors.green.shade400 : Colors.green.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            'Synchronisé ${formatTime(lastSync)}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.green.shade400 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper qui affiche la bannière en haut de n'importe quel widget.
class WithSyncBanner extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onRetrySync;
  final bool showWhenOnline;

  const WithSyncBanner({
    super.key,
    required this.child,
    this.onRetrySync,
    this.showWhenOnline = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SyncStatusBanner(
          showWhenOnline: showWhenOnline,
          onRetrySync: onRetrySync,
        ),
        Expanded(child: child),
      ],
    );
  }
}
