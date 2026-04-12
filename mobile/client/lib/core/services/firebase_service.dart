import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app_logger.dart';

/// Background message handler — doit être top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.debug('[Firebase] Background message: ${message.messageId}');
}

/// Plugin local notifications pour afficher les messages foreground
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Canal Android pour les notifications
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'drpharma_channel',
  'DR Pharma Notifications',
  description: 'Notifications de commandes et livraisons',
  importance: Importance.high,
);

/// Service pour l'initialisation et la gestion de Firebase
class FirebaseService {
  FirebaseService._();

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      AppLogger.info('Firebase initialized successfully');
    } catch (e) {
      AppLogger.error('Firebase initialization failed', error: e);
    }
  }

  /// Configure Firebase Messaging (notifications push)
  static Future<void> configureMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('FCM permission granted');

        // Get token
        final token = await messaging.getToken();
        if (kDebugMode) {
          AppLogger.debug('FCM Token: $token');
        }
      }

      // Setup local notifications for foreground display
      await _setupLocalNotifications();

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        AppLogger.debug(
          '[Firebase] Notification tapped (background): ${message.messageId}',
        );
      });

      // Handle cold start from notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.debug(
          '[Firebase] App opened from notification: ${initialMessage.messageId}',
        );
      }
    } catch (e) {
      AppLogger.error('FCM configuration failed', error: e);
    }
  }

  /// Initialise le plugin local notifications
  static Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(initSettings);

    // Create notification channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Show notifications in foreground on iOS
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Affiche une notification locale quand l'app est au premier plan
  ///
  /// Le backend envoie des messages DATA-ONLY (pas de bloc notification)
  /// pour permettre le contrôle du canal et du son côté Flutter.
  /// On extrait donc title/body depuis message.data.
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Priorité : message.notification (si présent), sinon message.data
    final String? title = message.notification?.title ?? message.data['title'];
    final String? body = message.notification?.body ?? message.data['body'];

    AppLogger.debug('[Firebase] Foreground message: $title');

    // Ne rien afficher si pas de title
    if (title == null || title.isEmpty) {
      AppLogger.debug('[Firebase] Message sans titre, ignoré');
      return;
    }

    // Récupérer le canal personnalisé depuis data (si fourni par le backend)
    final String channelId = message.data['channel_id'] ?? _channel.id;
    final String channelName = message.data['channel_name'] ?? _channel.name;

    await _localNotifications.show(
      message.hashCode,
      title,
      body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
