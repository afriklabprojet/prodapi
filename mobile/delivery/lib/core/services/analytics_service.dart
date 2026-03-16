import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service centralisé pour Analytics et Crashlytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  bool _initialized = false;

  /// Observer pour naviguer avec analytics
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  /// Initialisation du service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;

      // Activer Crashlytics uniquement en production
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Configurer le handler d'erreurs Flutter pour Crashlytics
      // IMPORTANT : chaîner avec le handler existant (défini dans main.dart)
      final existingFlutterHandler = FlutterError.onError;
      FlutterError.onError = (errorDetails) {
        _crashlytics.recordFlutterFatalError(errorDetails);
        // Appeler le handler précédent pour ne pas perdre le log/affichage
        existingFlutterHandler?.call(errorDetails);
      };

      // Handler pour les erreurs asynchrones — chaîner aussi
      final existingPlatformHandler = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        existingPlatformHandler?.call(error, stack);
        return true;
      };

      _initialized = true;
      if (kDebugMode) debugPrint('✅ Analytics & Crashlytics initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Analytics init error: $e');
    }
  }

  // ==================== USER PROPERTIES ====================

  /// Définir l'ID utilisateur
  Future<void> setUserId(String? userId) async {
    if (!_initialized) return;
    await _analytics.setUserId(id: userId);
    if (userId != null) {
      await _crashlytics.setUserIdentifier(userId);
    }
  }

  /// Définir une propriété utilisateur personnalisée
  Future<void> setUserProperty({required String name, required String? value}) async {
    if (!_initialized) return;
    await _analytics.setUserProperty(name: name, value: value);
    if (value != null) {
      await _crashlytics.setCustomKey(name, value);
    }
  }

  /// Définir le rôle du livreur
  Future<void> setCourierRole(String role) async {
    await setUserProperty(name: 'courier_role', value: role);
  }

  /// Définir le niveau du livreur
  Future<void> setCourierLevel(int level) async {
    await setUserProperty(name: 'courier_level', value: level.toString());
    await _crashlytics.setCustomKey('courier_level', level);
  }

  // ==================== SCREEN TRACKING ====================

  /// Logger la navigation vers un écran
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_initialized) return;
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
    if (kDebugMode) debugPrint('📊 Screen: $screenName');
  }

  // ==================== DELIVERY EVENTS ====================

  /// Livreur passe en ligne
  Future<void> logGoOnline() async {
    await _logEvent('courier_go_online');
  }

  /// Livreur passe hors ligne
  Future<void> logGoOffline() async {
    await _logEvent('courier_go_offline');
  }

  /// Nouvelle livraison acceptée
  Future<void> logDeliveryAccepted({
    required int deliveryId,
    required double distance,
    required double amount,
  }) async {
    await _logEvent('delivery_accepted', parameters: {
      'delivery_id': deliveryId,
      'distance_km': distance,
      'amount_fcfa': amount,
    });
  }

  /// Livraison refusée
  Future<void> logDeliveryRejected({required int deliveryId}) async {
    await _logEvent('delivery_rejected', parameters: {
      'delivery_id': deliveryId,
    });
  }

  /// Marchandise récupérée
  Future<void> logDeliveryPickedUp({required int deliveryId}) async {
    await _logEvent('delivery_picked_up', parameters: {
      'delivery_id': deliveryId,
    });
  }

  /// Livraison terminée
  Future<void> logDeliveryCompleted({
    required int deliveryId,
    required double amount,
    required int durationMinutes,
  }) async {
    await _logEvent('delivery_completed', parameters: {
      'delivery_id': deliveryId,
      'amount_fcfa': amount,
      'duration_minutes': durationMinutes,
    });
  }

  /// Livraison échouée
  Future<void> logDeliveryFailed({
    required int deliveryId,
    required String reason,
  }) async {
    await _logEvent('delivery_failed', parameters: {
      'delivery_id': deliveryId,
      'reason': reason,
    });
  }

  // ==================== WALLET EVENTS ====================

  /// Demande de retrait
  Future<void> logWithdrawalRequested({
    required double amount,
    required String method,
  }) async {
    await _logEvent('withdrawal_requested', parameters: {
      'amount_fcfa': amount,
      'method': method,
    });
  }

  /// Retrait complété
  Future<void> logWithdrawalCompleted({required double amount}) async {
    await _logEvent('withdrawal_completed', parameters: {
      'amount_fcfa': amount,
    });
  }

  // ==================== GAMIFICATION EVENTS ====================

  /// Montée de niveau
  Future<void> logLevelUp({
    required int newLevel,
    required String levelName,
  }) async {
    await _analytics.logLevelUp(level: newLevel);
    await _logEvent('courier_level_up', parameters: {
      'new_level': newLevel,
      'level_name': levelName,
    });
  }

  /// Badge débloqué
  Future<void> logBadgeUnlocked({
    required String badgeId,
    required String badgeName,
  }) async {
    await _analytics.logUnlockAchievement(id: badgeId);
    await _logEvent('badge_unlocked', parameters: {
      'badge_id': badgeId,
      'badge_name': badgeName,
    });
  }

  // ==================== INTERACTION EVENTS ====================

  /// Chat ouvert
  Future<void> logChatOpened({required int deliveryId}) async {
    await _logEvent('chat_opened', parameters: {
      'delivery_id': deliveryId,
    });
  }

  /// Message envoyé
  Future<void> logMessageSent({required int deliveryId}) async {
    await _logEvent('message_sent', parameters: {
      'delivery_id': deliveryId,
    });
  }

  /// Navigation lancée
  Future<void> logNavigationStarted({
    required String destination,
    required String app,
  }) async {
    await _logEvent('navigation_started', parameters: {
      'destination': destination,
      'navigation_app': app,
    });
  }

  /// Partage de lien de tracking
  Future<void> logTrackingLinkShared({required int deliveryId}) async {
    await _logEvent('tracking_link_shared', parameters: {
      'delivery_id': deliveryId,
    });
  }

  // ==================== SETTINGS EVENTS ====================

  /// Changement de thème
  Future<void> logThemeChanged({required String theme}) async {
    await _logEvent('theme_changed', parameters: {'theme': theme});
  }

  /// Changement de langue
  Future<void> logLanguageChanged({required String language}) async {
    await _logEvent('language_changed', parameters: {'language': language});
  }

  /// Mode économie batterie activé
  Future<void> logBatterySaverEnabled({required String mode}) async {
    await _logEvent('battery_saver_enabled', parameters: {'mode': mode});
  }

  // ==================== ERROR TRACKING ====================

  /// Logger une erreur non fatale
  Future<void> logError({
    required String message,
    required StackTrace? stackTrace,
    bool fatal = false,
    Map<String, dynamic>? extra,
  }) async {
    if (!_initialized) return;

    await _crashlytics.recordError(
      Exception(message),
      stackTrace,
      reason: message,
      fatal: fatal,
    );

    await _logEvent('app_error', parameters: {
      'error_message': message.substring(0, message.length > 100 ? 100 : message.length),
      'fatal': fatal,
      ...?extra,
    });
  }

  /// Logger un message personnalisé dans Crashlytics
  Future<void> log(String message) async {
    if (!_initialized) return;
    await _crashlytics.log(message);
  }

  // ==================== HELPER ====================

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!_initialized) return;
    
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        debugPrint('📊 Event: $name ${parameters ?? ''}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Analytics event error: $e');
    }
  }
}

// ==================== EXTENSION POUR EASY ACCESS ====================

/// Extension pour accéder facilement au service
extension AnalyticsExtension on Object {
  AnalyticsService get analytics => AnalyticsService();
}
