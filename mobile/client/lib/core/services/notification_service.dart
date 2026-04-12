import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';
import 'app_logger.dart';

/// Service de gestion des notifications push (FCM)
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialiser les notifications (permissions + token)
  Future<void> initNotifications() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      AppLogger.info('Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          AppLogger.info('FCM Token obtained (${token.substring(0, 10)}...)');
        }
        
        // Écouter les changements de token (expiration/rotation)
        _messaging.onTokenRefresh.listen((newToken) {
          AppLogger.info('FCM Token refreshed');
          // Token sera synchronisé au prochain login ou via syncTokenToBackend
        });
      }
    } catch (e) {
      AppLogger.error('Failed to init notifications', error: e);
      if (kDebugMode) rethrow;
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.error('Failed to get FCM token', error: e);
      return null;
    }
  }

  /// Synchroniser le token FCM avec le backend
  /// Doit être appelé après le login de l'utilisateur
  Future<bool> syncTokenToBackend(ApiClient apiClient) async {
    try {
      final token = await getToken();
      if (token == null) {
        AppLogger.warning('No FCM token to sync');
        return false;
      }

      await apiClient.post(
        ApiConstants.updateFcmToken,
        data: {'fcm_token': token},
      );

      AppLogger.info('FCM token synced to backend');
      return true;
    } catch (e) {
      AppLogger.error('Failed to sync FCM token', error: e);
      return false;
    }
  }

  /// Supprimer le token FCM du backend (logout)
  Future<void> removeTokenFromBackend(ApiClient apiClient) async {
    try {
      await apiClient.delete(ApiConstants.updateFcmToken);
      AppLogger.info('FCM token removed from backend');
    } catch (e) {
      AppLogger.error('Failed to remove FCM token', error: e);
    }
  }
}
