import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/core_providers.dart';
import '../../services/offline_storage_service.dart';
import '../../theme/app_colors.dart';

/// Bottom sheet affichant les actions en attente de synchronisation.
/// Permet à l'utilisateur de voir ce qui sera envoyé au serveur
/// quand la connexion reviendra.
class PendingActionsSheet extends ConsumerWidget {
  const PendingActionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PendingActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineStorage = ref.watch(offlineStorageProvider);
    final actions = offlineStorage.getPendingActions();
    final isDark = AppColors.isDark(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actions en attente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            actions.isEmpty
                                ? 'Tout est synchronisé !'
                                : '${actions.length} action(s) en attente',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty)
                      IconButton(
                        onPressed: () => _clearAll(context, ref),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade400,
                        ),
                        tooltip: 'Tout supprimer',
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Liste des actions
              Expanded(
                child: actions.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: actions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final action = actions[index];
                          return _PendingActionTile(
                            action: action,
                            onDelete: () =>
                                _deleteAction(context, ref, action.id),
                          );
                        },
                      ),
              ),

              // Footer avec info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Les actions seront envoyées automatiquement '
                          'quand la connexion reviendra',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_done_rounded,
              color: Colors.green,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tout est synchronisé !',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aucune action en attente',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer tout ?'),
        content: const Text(
          'Les actions non synchronisées seront perdues. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(offlineStorageProvider).clearPendingActions();
      ref.read(connectivityProvider.notifier).setPendingSync(false, 0);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteAction(
    BuildContext context,
    WidgetRef ref,
    String actionId,
  ) async {
    final storage = ref.read(offlineStorageProvider);
    await storage.removeAction(actionId);
    final remaining = storage.getPendingActions().length;
    ref
        .read(connectivityProvider.notifier)
        .setPendingSync(remaining > 0, remaining);
  }
}

class _PendingActionTile extends StatelessWidget {
  final PendingAction action;
  final VoidCallback onDelete;

  const _PendingActionTile({required this.action, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final (icon, color, label) = _getActionDetails(action.type);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collection: ${action.collection}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          if (action.entityId != null)
            Text(
              'ID: ${action.entityId}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
                fontFamily: 'monospace',
              ),
            ),
          Text(
            _formatTime(action.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 20),
        tooltip: 'Supprimer',
      ),
      isThreeLine: true,
    );
  }

  (IconData, Color, String) _getActionDetails(ActionType type) {
    return switch (type) {
      ActionType.create => (Icons.add_circle_outline, Colors.green, 'Création'),
      ActionType.update => (Icons.edit_outlined, Colors.blue, 'Modification'),
      ActionType.delete => (Icons.delete_outline, Colors.red, 'Suppression'),
    };
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour(s)';
  }
}
