import 'package:flutter/foundation.dart';
import 'crashlytics_service.dart';

/// Service de logging centralisé pour l'application
/// En production, les erreurs sont envoyées à Firebase Crashlytics
class AppLogger {
  AppLogger._();

  static void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('🔍 [DEBUG] $message');
      if (error != null) debugPrint('  Error: $error');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [INFO] $message');
    }
    // Log to Crashlytics for breadcrumb trail
    CrashlyticsService.log('[INFO] $message');
  }

  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('⚠️ [WARN] $message');
      if (error != null) debugPrint('  Error: $error');
    }
    // Log warnings to Crashlytics
    CrashlyticsService.log('[WARN] $message');
    if (error != null) {
      CrashlyticsService.recordError(error, stackTrace, reason: message);
    }
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    debugPrint('❌ [ERROR] $message');
    if (error != null) debugPrint('  Error: $error');
    if (stackTrace != null && kDebugMode) {
      debugPrint('  StackTrace: $stackTrace');
    }
    // Send errors to Crashlytics
    if (error != null) {
      CrashlyticsService.recordError(error, stackTrace, reason: message);
    } else {
      CrashlyticsService.log('[ERROR] $message');
    }
  }

  /// Log pour le tracking des événements analytics
  static void event(String eventName, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      debugPrint('📊 [EVENT] $eventName ${params ?? ''}');
    }
  }

  /// Log pour les appels API
  static void api(String method, String path, {int? statusCode, String? body}) {
    if (kDebugMode) {
      debugPrint('🌐 [API] $method $path → ${statusCode ?? '?'}');
    }
  }

  /// Log pour l'authentification
  static void auth(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('🔐 [AUTH] $message');
      if (error != null) debugPrint('  Error: $error');
    }
    // Auth errors go to Crashlytics
    if (error != null) {
      CrashlyticsService.recordAuthError(
        operation: message,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log pour la géolocalisation
  static void location(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('📍 [LOCATION] $message');
      if (error != null) debugPrint('  Error: $error');
    }
  }

  /// Log pour les paiements (toujours envoyé à Crashlytics)
  static void payment(
    String message, {
    String? provider,
    String? orderId,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    debugPrint('💳 [PAYMENT] $message');
    if (error != null) {
      debugPrint('  Error: $error');
      CrashlyticsService.recordPaymentError(
        provider: provider ?? 'unknown',
        orderId: orderId ?? 'unknown',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log pour les erreurs réseau
  static void network(
    String endpoint, {
    int? statusCode,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('🌐 [NETWORK] $endpoint → ${statusCode ?? 'error'}');
      if (error != null) debugPrint('  Error: $error');
    }
    if (error != null) {
      CrashlyticsService.recordNetworkError(
        endpoint: endpoint,
        statusCode: statusCode,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
