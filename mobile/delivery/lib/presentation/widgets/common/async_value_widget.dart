import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_loading_widget.dart';
import 'app_error_widget.dart';

/// Widget générique qui gère automatiquement les 3 états d'un [AsyncValue]:
/// loading, error, data.
///
/// Remplace le pattern dupliqué dans 10+ écrans :
/// ```dart
/// asyncValue.when(
///   loading: () => Center(child: CircularProgressIndicator()),
///   error: (e, st) => Center(child: Column(Icon + Text + Button)),
///   data: (data) => ...,
/// )
/// ```
///
/// Usage :
/// ```dart
/// AsyncValueWidget<WalletData>(
///   value: ref.watch(walletDataProvider),
///   data: (wallet) => WalletContent(wallet: wallet),
///   onRetry: () => ref.invalidate(walletDataProvider),
/// )
/// ```
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loadingMessage,
    this.loading,
    this.error,
  });

  /// La valeur asynchrone à observer.
  final AsyncValue<T> value;

  /// Builder appelé quand les données sont disponibles.
  final Widget Function(T data) data;

  /// Callback pour le bouton réessayer en cas d'erreur.
  final VoidCallback? onRetry;

  /// Message affiché pendant le chargement.
  final String? loadingMessage;

  /// Widget de chargement personnalisé (remplace le défaut).
  final Widget? loading;

  /// Widget d'erreur personnalisé (remplace le défaut).
  final Widget Function(Object error, StackTrace? stack)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loading ?? AppLoadingWidget(message: loadingMessage),
      error: (e, st) {
        if (error != null) return error!(e, st);

        final errorMessage = e.toString();
        final isProfileError = errorMessage.contains('coursier') ||
            errorMessage.contains('403') ||
            errorMessage.contains('non trouvé');

        if (isProfileError) {
          return AppErrorWidget.profile(
            message: errorMessage,
            onRetry: onRetry,
          );
        }

        return AppErrorWidget(
          message: errorMessage,
          onRetry: onRetry,
        );
      },
      data: data,
    );
  }
}

/// Variante Sliver de [AsyncValueWidget] pour utilisation dans [CustomScrollView].
///
/// Enveloppe automatiquement les états loading/error dans [SliverFillRemaining].
class SliverAsyncValueWidget<T> extends StatelessWidget {
  const SliverAsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loadingMessage,
  });

  /// La valeur asynchrone à observer.
  final AsyncValue<T> value;

  /// Builder appelé quand les données sont disponibles — doit retourner un Sliver.
  final Widget Function(T data) data;

  /// Callback pour le bouton réessayer en cas d'erreur.
  final VoidCallback? onRetry;

  /// Message affiché pendant le chargement.
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => SliverFillRemaining(
        child: AppLoadingWidget(message: loadingMessage),
      ),
      error: (e, st) {
        final errorMessage = e.toString();
        return SliverFillRemaining(
          child: AppErrorWidget(
            message: errorMessage,
            onRetry: onRetry,
          ),
        );
      },
      data: data,
    );
  }
}
