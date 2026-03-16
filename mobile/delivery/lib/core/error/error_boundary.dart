import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget pour capturer les erreurs dans l'arbre de widgets
/// Équivalent d'un Error Boundary dans React
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails error)? errorBuilder;
  final void Function(FlutterErrorDetails error)? onError;
  final bool showErrorDetails;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
    this.showErrorDetails = kDebugMode,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  // NOTE: Nous ne surchargeons PAS FlutterError.onError ici.
  // L'ErrorBoundary capture les erreurs de rendu via didError() et
  // ErrorWidget.builder, sans interférer avec le handler global défini dans main.dart.

  void _reset() {
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!);
      }
      return _DefaultErrorWidget(
        error: _error!,
        showDetails: widget.showErrorDetails,
        onRetry: _reset,
      );
    }
    return widget.child;
  }
}

/// Widget d'erreur par défaut
class _DefaultErrorWidget extends StatelessWidget {
  final FlutterErrorDetails error;
  final bool showDetails;
  final VoidCallback? onRetry;

  const _DefaultErrorWidget({
    required this.error,
    this.showDetails = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade400,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'Oups ! Une erreur est survenue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nous sommes désolés pour ce désagrément.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (showDetails) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error.exceptionAsString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.red.shade400,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget pour afficher une erreur dans un contexte plus petit (inline)
class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? details;

  const ErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.red.shade700 : Colors.red.shade200,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade400,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (details != null) ...[
            const SizedBox(height: 8),
            Text(
              details!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget pour les états de chargement avec erreur
class LoadingErrorWidget extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;

  const LoadingErrorWidget({
    super.key,
    required this.isLoading,
    this.error,
    this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return ErrorCard(
        message: error!,
        onRetry: onRetry,
      );
    }

    return child;
  }
}

/// Service global de gestion des erreurs
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  final _errorController = StreamController<AppError>.broadcast();
  
  /// Stream des erreurs globales
  Stream<AppError> get errorStream => _errorController.stream;

  /// Méthode pour configurer le handler global dans main()
  static void setup() {
    // Handler pour les erreurs Flutter — chaîner avec l'existant
    final existingFlutterHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      _instance._handleFlutterError(details);
      existingFlutterHandler?.call(details);
    };

    // Handler pour les erreurs asynchrones non capturées — chaîner
    final existingPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _instance._handlePlatformError(error, stack);
      existingPlatformHandler?.call(error, stack);
      return true;
    };
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    final error = AppError(
      type: ErrorType.flutter,
      message: details.exceptionAsString(),
      stackTrace: details.stack,
      timestamp: DateTime.now(),
    );
    _errorController.add(error);
    
    if (kDebugMode) {
      debugPrint('🔴 [FLUTTER ERROR] ${details.exception}');
      debugPrintStack(stackTrace: details.stack);
    }
  }

  void _handlePlatformError(Object error, StackTrace stack) {
    final appError = AppError(
      type: ErrorType.platform,
      message: error.toString(),
      stackTrace: stack,
      timestamp: DateTime.now(),
    );
    _errorController.add(appError);
    
    if (kDebugMode) {
      debugPrint('🔴 [PLATFORM ERROR] $error');
      debugPrintStack(stackTrace: stack);
    }
  }

  /// Reporter une erreur manuellement
  void reportError(String message, {
    ErrorType type = ErrorType.custom,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    final error = AppError(
      type: type,
      message: message,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      extra: extra,
    );
    _errorController.add(error);
    
    if (kDebugMode) {
      debugPrint('🔴 [CUSTOM ERROR] $message');
    }
  }

  /// Exécuter une fonction avec gestion d'erreur
  Future<T?> runSafely<T>(
    Future<T> Function() action, {
    T? fallback,
    String? errorMessage,
  }) async {
    try {
      return await action();
    } catch (e, stack) {
      reportError(
        errorMessage ?? e.toString(),
        type: ErrorType.custom,
        stackTrace: stack,
      );
      return fallback;
    }
  }

  void dispose() {
    _errorController.close();
  }
}

/// Types d'erreurs
enum ErrorType {
  flutter,
  platform,
  network,
  api,
  validation,
  custom,
}

/// Modèle d'erreur
class AppError {
  final ErrorType type;
  final String message;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? extra;

  AppError({
    required this.type,
    required this.message,
    this.stackTrace,
    required this.timestamp,
    this.extra,
  });

  @override
  String toString() => '[$type] $message';
}

/// Extension pour zone d'erreur sécurisée
extension SafeZone on Widget {
  Widget withErrorBoundary({
    Widget Function(FlutterErrorDetails)? errorBuilder,
    void Function(FlutterErrorDetails)? onError,
  }) {
    return ErrorBoundary(
      errorBuilder: errorBuilder,
      onError: onError,
      child: this,
    );
  }
}
