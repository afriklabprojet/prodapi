import 'package:flutter/material.dart';

/// Mixin réutilisable pour protéger les formulaires contre la perte de données.
/// 
/// Usage:
/// ```dart
/// class _EditPageState extends State<EditPage> with FormGuardMixin {
///   @override
///   Widget build(BuildContext context) {
///     return buildGuardedScaffold(
///       appBar: AppBar(title: Text('Éditer')),
///       body: Form(child: ...),
///     );
///   }
/// }
/// ```
mixin FormGuardMixin<T extends StatefulWidget> on State<T> {
  bool _hasUnsavedChanges = false;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Marquer le formulaire comme modifié.
  void markDirty() {
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
    }
  }

  /// Marquer le formulaire comme propre (après sauvegarde).
  void markClean() {
    _hasUnsavedChanges = false;
  }

  /// Affiche un dialogue de confirmation si des modifications non sauvegardées existent.
  Future<bool> confirmDiscard(BuildContext context) async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text('Vous avez des modifications non sauvegardées. Voulez-vous quitter sans sauvegarder ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Wraps a Scaffold with PopScope for back-navigation protection.
  Widget buildGuardedScaffold({
    required PreferredSizeWidget? appBar,
    required Widget body,
    Color? backgroundColor,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
  }) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await confirmDiscard(context);
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
