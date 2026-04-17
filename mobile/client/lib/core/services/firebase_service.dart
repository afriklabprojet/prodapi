import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app_logger.dart';
import 'navigation_service.dart';

/// Background message handler — doit être top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[Firebase] Background message: ${message.messageId}');

  // Afficher une notification locale pour les messages data-only en background
  final data = message.data;
  final title = data['title'];
  final body = data['body'];
  if (title == null || title.isEmpty) return;

  final plugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await plugin.initialize(initSettings);

  final channelId = data['channel_id'] ?? 'drpharma_channel';
  final soundName = data['sound'];

  await plugin.show(
    message.hashCode,
    title,
    body ?? '',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'DR Pharma Notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: soundName != null,
        sound: soundName != null
            ? RawResourceAndroidNotificationSound(soundName)
            : null,
      ),
    ),
    payload: jsonEncode(data),
  );
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

  /// Notification en attente (si le navigator n'est pas encore prêt au moment du tap)
  static Map<String, dynamic>? _pendingNotificationData;

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
        _navigateOrSave(message.data.cast<String, dynamic>());
      });

      // Handle cold start from notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.debug(
          '[Firebase] App opened from notification: ${initialMessage.messageId}',
        );
        _navigateOrSave(initialMessage.data.cast<String, dynamic>());
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channels on Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_channel);

    // Canal pour les messages de chat
    const chatChannel = AndroidNotificationChannel(
      'system_channel',
      'Messages',
      description: 'Notifications de messages de chat',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_chat'),
    );
    await androidPlugin?.createNotificationChannel(chatChannel);

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
    final String? soundName = message.data['sound'];

    // Encode data as JSON payload pour pouvoir naviguer au tap
    final payload = jsonEncode(message.data);

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
          playSound: soundName != null,
          sound: soundName != null
              ? RawResourceAndroidNotificationSound(soundName)
              : null,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Handler pour le tap sur une notification locale (foreground)
  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      AppLogger.debug('[Firebase] Local notification tapped: ${data['type']}');
      _navigateOrSave(data);
    } catch (e) {
      AppLogger.error('Error handling notification tap', error: e);
    }
  }

  /// Tente la navigation immédiate ; sinon sauvegarde pour plus tard.
  static void _navigateOrSave(Map<String, dynamic> data) {
    if (navigatorKey.currentState != null) {
      NavigationService.handleNotificationTap(
        type: data['type'],
        data: data,
      );
    } else {
      AppLogger.debug('[Firebase] Navigator not ready, saving notification for later');
      _pendingNotificationData = data;
      // Réessayer après le prochain frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        processPendingNotification();
      });
    }
  }

  /// Traite la notification en attente (appelé quand le navigator est prêt).
  static void processPendingNotification() {
    if (_pendingNotificationData == null) return;

    if (navigatorKey.currentState != null) {
      final data = _pendingNotificationData!;
      _pendingNotificationData = null;
      AppLogger.debug('[Firebase] Processing saved notification: ${data['type']}');
      NavigationService.handleNotificationTap(type: data['type'], data: data);
    } else {
      // Toujours pas prêt, réessayer au prochain frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        processPendingNotification();
      });
    }
  }
}
