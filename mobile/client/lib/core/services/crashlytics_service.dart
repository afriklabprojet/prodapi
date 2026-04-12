import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Service centralisé pour Firebase Crashlytics
/// Gère le reporting d'erreurs et de crashs en production
class CrashlyticsService {
  CrashlyticsService._();

  static FirebaseCrashlytics? _instance;

  /// Initialise Crashlytics
  /// Désactivé en mode debug pour éviter le spam
  static Future<void> init() async {
    _instance = FirebaseCrashlytics.instance;

    // Désactiver la collecte en mode debug
    await _instance!.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Enregistrer les erreurs Flutter non capturées
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (!kDebugMode) {
        _instance!.recordFlutterFatalError(details);
      }
    };

    // Enregistrer les erreurs asynchrones non capturées
    PlatformDispatcher.instance.onError = (error, stack) {
      if (!kDebugMode) {
        _instance!.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  /// Enregistre une erreur non fatale
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {
    if (kDebugMode || _instance == null) return;

    await _instance!.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
      information: information,
    );
  }

  /// Enregistre un message personnalisé
  static Future<void> log(String message) async {
    if (kDebugMode || _instance == null) return;
    _instance!.log(message);
  }

  /// Définit l'identifiant utilisateur pour le contexte
  static Future<void> setUserIdentifier(String userId) async {
    if (_instance == null) return;
    await _instance!.setUserIdentifier(userId);
  }

  /// Efface l'identifiant utilisateur (déconnexion)
  static Future<void> clearUserIdentifier() async {
    if (_instance == null) return;
    await _instance!.setUserIdentifier('');
  }

  /// Ajoute une clé personnalisée pour le contexte
  static Future<void> setCustomKey(String key, Object value) async {
    if (_instance == null) return;
    await _instance!.setCustomKey(key, value);
  }

  /// Définit plusieurs clés personnalisées
  static Future<void> setCustomKeys(Map<String, Object> keysAndValues) async {
    if (_instance == null) return;
    for (final entry in keysAndValues.entries) {
      await _instance!.setCustomKey(entry.key, entry.value);
    }
  }

  /// Force un crash pour tester (uniquement en debug)
  static void testCrash() {
    if (kDebugMode) {
      _instance?.crash();
    }
  }

  /// Vérifie si Crashlytics est activé
  static bool get isEnabled => _instance != null && !kDebugMode;

  /// Enregistre une erreur réseau
  static Future<void> recordNetworkError({
    required String endpoint,
    required int? statusCode,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    await recordError(
      error,
      stackTrace,
      reason: 'Network Error: $endpoint (${statusCode ?? 'unknown'})',
      information: [
        DiagnosticsNode.message('Endpoint: $endpoint'),
        DiagnosticsNode.message('Status: $statusCode'),
      ],
    );
  }

  /// Enregistre une erreur d'authentification
  static Future<void> recordAuthError({
    required String operation,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    await recordError(error, stackTrace, reason: 'Auth Error: $operation');
  }

  /// Enregistre une erreur de paiement
  static Future<void> recordPaymentError({
    required String provider,
    required String orderId,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    await recordError(
      error,
      stackTrace,
      reason: 'Payment Error: $provider',
      fatal: true, // Les erreurs de paiement sont critiques
      information: [
        DiagnosticsNode.message('Provider: $provider'),
        DiagnosticsNode.message('Order ID: $orderId'),
      ],
    );
  }
}
