/// ─────────────────────────────────────────────────────────
/// Cart UI Guards — Protection contre les utilisateurs imprévisibles
/// ─────────────────────────────────────────────────────────
///
/// Ce fichier fournit des utilitaires pour protéger l'UI du panier
/// contre les clics rapides, fermetures brutales, etc.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mixin pour protéger contre les clics rapides
mixin CartOperationGuard<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Set de product IDs en cours d'opération
  final Set<int> _pendingOperations = {};

  /// Vérifie si une opération est en cours pour ce produit
  bool isOperationPending(int productId) =>
      _pendingOperations.contains(productId);

  /// Exécute une opération avec protection contre double-clic
  Future<R?> guardedOperation<R>({
    required int productId,
    required Future<R> Function() operation,
    Duration cooldown = const Duration(milliseconds: 300),
  }) async {
    if (_pendingOperations.contains(productId)) {
      return null; // Opération déjà en cours
    }

    _pendingOperations.add(productId);
    if (mounted) setState(() {});

    try {
      final result = await operation();
      return result;
    } finally {
      // Cooldown avant de permettre une nouvelle opération
      await Future.delayed(cooldown);
      _pendingOperations.remove(productId);
      if (mounted) setState(() {});
    }
  }

  /// Libère toutes les opérations pendantes
  void clearPendingOperations() {
    _pendingOperations.clear();
  }
}

/// Widget bouton avec debounce intégré
class DebouncedIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final Duration debounceDuration;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  const DebouncedIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.padding,
    this.constraints,
  });

  @override
  State<DebouncedIconButton> createState() => _DebouncedIconButtonState();
}

class _DebouncedIconButtonState extends State<DebouncedIconButton> {
  bool _isProcessing = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handlePress() {
    if (_isProcessing || widget.onPressed == null) return;

    setState(() => _isProcessing = true);
    widget.onPressed!();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isProcessing ? null : _handlePress,
      icon: widget.icon,
      tooltip: widget.tooltip,
      padding: widget.padding,
      constraints: widget.constraints,
    );
  }
}

/// Widget bouton ElevatedButton avec debounce
class DebouncedElevatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;
  final Duration debounceDuration;

  const DebouncedElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.style,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<DebouncedElevatedButton> createState() =>
      _DebouncedElevatedButtonState();
}

class _DebouncedElevatedButtonState extends State<DebouncedElevatedButton> {
  bool _isProcessing = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handlePress() {
    if (_isProcessing || widget.onPressed == null) return;

    setState(() => _isProcessing = true);
    widget.onPressed!();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.icon != null) {
      return ElevatedButton.icon(
        onPressed: _isProcessing ? null : _handlePress,
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : widget.icon!,
        label: widget.child,
        style: widget.style,
      );
    }

    return ElevatedButton(
      onPressed: _isProcessing ? null : _handlePress,
      style: widget.style,
      child: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.child,
    );
  }
}

/// Extension pour vérifier le résultat d'une opération panier
extension CartResultHandler on Future<dynamic> {
  /// Gère le résultat et affiche un snackbar approprié
  Future<void> handleCartResult(
    BuildContext context, {
    required String successMessage,
    String? errorPrefix,
  }) async {
    try {
      final result = await this;

      if (!context.mounted) return;

      // Si c'est un Either (dartz), vérifier le résultat
      if (result != null && result.toString().contains('Left(')) {
        // Extraction du message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorPrefix ?? 'Erreur lors de l\'opération'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Provider pour suivre les opérations en cours par productId
final cartOperationStatusProvider =
    StateNotifierProvider<CartOperationStatusNotifier, Set<int>>(
  (ref) => CartOperationStatusNotifier(),
);

class CartOperationStatusNotifier extends StateNotifier<Set<int>> {
  CartOperationStatusNotifier() : super({});

  bool isOperating(int productId) => state.contains(productId);

  void startOperation(int productId) {
    state = {...state, productId};
  }

  void endOperation(int productId) {
    state = state.where((id) => id != productId).toSet();
  }
}
