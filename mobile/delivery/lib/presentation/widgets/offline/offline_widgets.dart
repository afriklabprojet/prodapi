import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_manager.dart';
import '../../../core/theme/theme_provider.dart';

/// Bannière d'état hors-ligne qui s'affiche en haut de l'écran
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncManagerProvider);
    final isDark = ref.watch(isDarkModeProvider);

    // Ne pas afficher si en ligne et pas de sync en cours
    if (connectivity.isOnline && !syncState.isSyncing && connectivity.pendingSyncCount == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getBannerColor(connectivity, syncState, isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _buildIcon(connectivity, syncState),
            const SizedBox(width: 12),
            Expanded(
              child: _buildText(connectivity, syncState),
            ),
            if (connectivity.isOnline && connectivity.pendingSyncCount > 0 && !syncState.isSyncing)
              _buildSyncButton(ref),
          ],
        ),
      ),
    );
  }

  Color _getBannerColor(ConnectivityState connectivity, SyncState syncState, bool isDark) {
    if (syncState.isSyncing) {
      return isDark ? Colors.blue.shade900 : Colors.blue.shade50;
    }
    if (connectivity.isOffline) {
      return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    }
    if (connectivity.pendingSyncCount > 0) {
      return isDark ? Colors.orange.shade900 : Colors.orange.shade50;
    }
    return Colors.transparent;
  }

  Widget _buildIcon(ConnectivityState connectivity, SyncState syncState) {
    if (syncState.isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }
    
    if (connectivity.isOffline) {
      return const Icon(Icons.cloud_off, size: 20, color: Colors.grey);
    }
    
    if (connectivity.pendingSyncCount > 0) {
      return Stack(
        children: [
          const Icon(Icons.sync_problem, size: 20, color: Colors.orange),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${connectivity.pendingSyncCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return const Icon(Icons.cloud_done, size: 20, color: Colors.green);
  }

  Widget _buildText(ConnectivityState connectivity, SyncState syncState) {
    if (syncState.isSyncing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Synchronisation en cours...',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (syncState.currentAction != null)
            Text(
              syncState.currentAction!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          if (syncState.totalPending > 0)
            LinearProgressIndicator(
              value: syncState.progress,
              backgroundColor: Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
        ],
      );
    }
    
    if (connectivity.isOffline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Mode hors-ligne',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            connectivity.offlineDurationLabel.isNotEmpty
                ? connectivity.offlineDurationLabel
                : 'Les données seront synchronisées à la reconnexion',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      );
    }
    
    if (connectivity.pendingSyncCount > 0) {
      return Text(
        '${connectivity.pendingSyncCount} élément(s) en attente de sync',
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildSyncButton(WidgetRef ref) {
    return TextButton.icon(
      onPressed: () {
        ref.read(syncManagerProvider.notifier).forceSync();
      },
      icon: const Icon(Icons.sync, size: 16),
      label: const Text('Sync'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.orange.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

/// Indicateur compact pour la barre de status
class OfflineIndicator extends ConsumerWidget {
  final bool showLabel;
  final double size;

  const OfflineIndicator({
    super.key,
    this.showLabel = true,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncManagerProvider);

    if (connectivity.isOnline && connectivity.pendingSyncCount == 0 && !syncState.isSyncing) {
      return const SizedBox.shrink();
    }

    final color = _getStatusColor(connectivity, syncState);
    final icon = _getStatusIcon(connectivity, syncState);

    return Tooltip(
      message: _getTooltipMessage(connectivity, syncState),
      child: InkWell(
        onTap: connectivity.isOnline && connectivity.pendingSyncCount > 0
            ? () => ref.read(syncManagerProvider.notifier).forceSync()
            : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (syncState.isSyncing)
                SizedBox(
                  width: size - 4,
                  height: size - 4,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, size: size, color: color),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  _getStatusLabel(connectivity, syncState),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (connectivity.pendingSyncCount > 0 && !syncState.isSyncing) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${connectivity.pendingSyncCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ConnectivityState connectivity, SyncState syncState) {
    if (syncState.isSyncing) return Colors.blue;
    if (connectivity.isOffline) return Colors.grey;
    if (connectivity.pendingSyncCount > 0) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon(ConnectivityState connectivity, SyncState syncState) {
    if (syncState.isSyncing) return Icons.sync;
    if (connectivity.isOffline) return Icons.cloud_off;
    if (connectivity.pendingSyncCount > 0) return Icons.sync_problem;
    return Icons.cloud_done;
  }

  String _getStatusLabel(ConnectivityState connectivity, SyncState syncState) {
    if (syncState.isSyncing) return 'Sync...';
    if (connectivity.isOffline) return 'Hors-ligne';
    if (connectivity.pendingSyncCount > 0) return 'En attente';
    return 'En ligne';
  }

  String _getTooltipMessage(ConnectivityState connectivity, SyncState syncState) {
    if (syncState.isSyncing) {
      return 'Synchronisation: ${syncState.synced}/${syncState.totalPending}';
    }
    if (connectivity.isOffline) {
      return 'Mode hors-ligne\n${connectivity.offlineDurationLabel}';
    }
    if (connectivity.pendingSyncCount > 0) {
      return '${connectivity.pendingSyncCount} élément(s) en attente\nAppuyez pour synchroniser';
    }
    return 'Connecté via ${connectivity.connectionTypeLabel}';
  }
}

/// Écran complet de statut hors-ligne (pour afficher quand totalement offline)
class OfflineStatusScreen extends ConsumerWidget {
  final Widget child;
  final bool showOverlay;

  const OfflineStatusScreen({
    super.key,
    required this.child,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Stack(
      children: [
        child,
        if (connectivity.isOffline && showOverlay)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? Colors.grey.shade900 : Colors.grey.shade100).withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 32,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mode hors-ligne',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Certaines fonctionnalités sont limitées.\nLes données seront synchronisées automatiquement.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(connectivityProvider.notifier).checkConnectivity();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Vérifier la connexion'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bouton de synchronisation manuelle
class SyncNowButton extends ConsumerWidget {
  final bool expanded;

  const SyncNowButton({super.key, this.expanded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncManagerProvider);
    final isDark = ref.watch(isDarkModeProvider);

    // Désactivé si offline ou sync en cours
    final enabled = connectivity.isOnline && !syncState.isSyncing;

    if (expanded) {
      return ElevatedButton.icon(
        onPressed: enabled
            ? () => ref.read(syncManagerProvider.notifier).forceSync()
            : null,
        icon: syncState.isSyncing
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white70 : Colors.grey,
                  ),
                ),
              )
            : const Icon(Icons.sync, size: 18),
        label: Text(syncState.isSyncing ? 'Synchronisation...' : 'Synchroniser'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.grey.shade800,
        ),
      );
    }

    return IconButton(
      onPressed: enabled
          ? () => ref.read(syncManagerProvider.notifier).forceSync()
          : null,
      icon: syncState.isSyncing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white70 : Colors.grey,
                ),
              ),
            )
          : Icon(
              Icons.sync,
              color: enabled
                  ? (isDark ? Colors.white : Colors.grey.shade800)
                  : Colors.grey,
            ),
      tooltip: syncState.isSyncing ? 'Synchronisation...' : 'Synchroniser',
    );
  }
}

/// Card montrant le statut de synchronisation détaillé
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncManagerProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connectivity.isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: connectivity.isOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connectivity.isOnline ? 'Connecté' : 'Hors-ligne',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        connectivity.connectionTypeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SyncNowButton(),
              ],
            ),
            if (connectivity.pendingSyncCount > 0 || syncState.isSyncing) ...[
              const Divider(height: 24),
              Row(
                children: [
                  if (syncState.isSyncing)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            syncState.currentAction ?? 'Synchronisation...',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: syncState.progress,
                            backgroundColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${syncState.synced}/${syncState.totalPending} éléments',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.sync_problem,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${connectivity.pendingSyncCount} élément(s) en attente',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (syncState.lastSyncTime != null) ...[
              const SizedBox(height: 12),
              Text(
                'Dernière sync: ${_formatLastSync(syncState.lastSyncTime!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLastSync(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}

/// Wrapper qui gère les actions offline automatiquement
class OfflineAwareButton extends ConsumerWidget {
  final VoidCallback onPressed;
  final VoidCallback? onOfflinePressed;
  final String actionType;
  final int? deliveryId;
  final Widget child;
  final bool showOfflineSnackbar;

  const OfflineAwareButton({
    super.key,
    required this.onPressed,
    this.onOfflinePressed,
    this.actionType = 'action',
    this.deliveryId,
    required this.child,
    this.showOfflineSnackbar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return GestureDetector(
      onTap: () {
        if (isOnline) {
          onPressed();
        } else {
          // Mettre en queue si offline
          if (deliveryId != null) {
            ref.read(syncManagerProvider.notifier).queueAction(
                  type: actionType,
                  deliveryId: deliveryId!,
                );
          }

          if (showOfflineSnackbar) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Action enregistrée. Elle sera exécutée à la reconnexion.',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.grey.shade700,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          onOfflinePressed?.call();
        }
      },
      child: child,
    );
  }
}
