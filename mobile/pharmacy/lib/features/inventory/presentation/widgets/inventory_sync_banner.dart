import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/inventory_sync_provider.dart';

/// Bannière d'état de synchronisation pour l'inventaire.
///
/// Affiche l'état offline, les modifications en attente,
/// et permet de forcer une synchronisation.
class InventorySyncBanner extends ConsumerWidget {
  /// Callback quand la synchro est terminée.
  final VoidCallback? onSyncComplete;

  const InventorySyncBanner({super.key, this.onSyncComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncMeta = ref.watch(inventorySyncMetaProvider);

    // Ne rien afficher si tout est synchronisé et online
    if (!syncMeta.isOffline &&
        syncMeta.pendingChangesCount == 0 &&
        !syncMeta.isStale) {
      return const SizedBox.shrink();
    }

    final isDark = AppColors.isDark(context);

    // Déterminer le style selon l'état
    final (Color bgColor, Color textColor, IconData icon, String message) =
        _getBannerStyle(context, syncMeta, isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Icône animée
            _AnimatedIcon(icon: icon, color: textColor),
            const SizedBox(width: 12),

            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (syncMeta.pendingChangesCount > 0)
                    Text(
                      AppLocalizations.of(
                        context,
                      ).modificationsPending(syncMeta.pendingChangesCount),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

            // Bouton de synchro si online
            if (!syncMeta.isOffline)
              _SyncButton(
                textColor: textColor,
                onPressed: () async {
                  final success = await ref
                      .read(inventorySyncMetaProvider.notifier)
                      .forceSync();
                  if (success) {
                    onSyncComplete?.call();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData, String) _getBannerStyle(
    BuildContext context,
    InventorySyncMeta meta,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    if (meta.isOffline) {
      return (
        isDark ? Colors.orange.shade900 : Colors.orange.shade100,
        isDark ? Colors.orange.shade100 : Colors.orange.shade900,
        Icons.cloud_off_rounded,
        l10n.offlineModeLabel,
      );
    }

    if (meta.pendingChangesCount > 0) {
      return (
        isDark ? Colors.blue.shade900 : Colors.blue.shade50,
        isDark ? Colors.blue.shade100 : Colors.blue.shade900,
        Icons.sync_rounded,
        l10n.syncPending,
      );
    }

    if (meta.isStale) {
      return (
        isDark ? Colors.amber.shade900 : Colors.amber.shade50,
        isDark ? Colors.amber.shade100 : Colors.amber.shade900,
        Icons.update_rounded,
        'Données obsolètes (${meta.dataAgeMinutes} min)',
      );
    }

    return (
      isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      isDark ? Colors.grey.shade300 : Colors.grey.shade700,
      Icons.info_outline_rounded,
      meta.statusMessage,
    );
  }
}

/// Icône avec animation de pulsation pour attirer l'attention.
class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedIcon({required this.icon, required this.color});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(widget.icon, color: widget.color, size: 18),
      ),
    );
  }
}

/// Bouton de synchronisation manuelle.
class _SyncButton extends StatefulWidget {
  final Color textColor;
  final Future<void> Function() onPressed;

  const _SyncButton({required this.textColor, required this.onPressed});

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton>
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);
    _rotationController.repeat();

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        _rotationController.stop();
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Synchroniser',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSyncing ? null : _handlePress,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: RotationTransition(
              turns: _rotationController,
              child: Icon(
                Icons.refresh_rounded,
                color: _isSyncing
                    ? widget.textColor.withValues(alpha: 0.5)
                    : widget.textColor,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicateur compact d'état de synchronisation.
///
/// Peut être utilisé dans un AppBar ou à côté d'un titre.
class InventorySyncIndicator extends ConsumerWidget {
  const InventorySyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncMeta = ref.watch(inventorySyncMetaProvider);

    if (!syncMeta.isOffline &&
        syncMeta.pendingChangesCount == 0 &&
        !syncMeta.isFromCache) {
      return const SizedBox.shrink();
    }

    final (Color color, IconData icon) = _getIndicatorStyle(syncMeta);

    return Tooltip(
      message: syncMeta.statusMessage,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            if (syncMeta.pendingChangesCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '${syncMeta.pendingChangesCount}',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, IconData) _getIndicatorStyle(InventorySyncMeta meta) {
    if (meta.isOffline) {
      return (Colors.orange, Icons.cloud_off_rounded);
    }
    if (meta.pendingChangesCount > 0) {
      return (Colors.blue, Icons.sync_rounded);
    }
    if (meta.isFromCache) {
      return (Colors.grey, Icons.cached_rounded);
    }
    return (Colors.grey, Icons.check_circle_outline);
  }
}
