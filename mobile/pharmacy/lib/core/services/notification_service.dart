import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Debug Logging Helper
// ─────────────────────────────────────────────────────────────────────────────

void _log(String message) {
  if (kDebugMode) debugPrint(message);
}

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Types de notifications qui déclenchent une alerte urgente.
const _urgentNotificationTypes = {'new_order', 'new_prescription'};

/// Types de notifications liées aux commandes.
const _orderNotificationTypes = {
  'new_order',
  'order_status',
  'new_prescription',
};

/// Types de notifications liées au stock.
const _stockNotificationTypes = {'low_stock', 'out_of_stock'};

/// Types de notifications liées aux paiements.
const _paymentNotificationTypes = {'payment', 'payout_completed'};

/// Mapping des canaux vers les fichiers sons (sans extension).
const _channelSounds = {
  NotificationChannels.ordersChannel: 'order_received',
  NotificationChannels.stockChannel: 'alert',
  NotificationChannels.paymentsChannel: 'chime',
  NotificationChannels.systemChannel: 'soft',
};

// ─────────────────────────────────────────────────────────────────────────────
// Background Handler (top-level function required by Firebase)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _log('Handling a background message: ${message.messageId}');

  final data = message.data;
  final title = data['title'];
  final body = data['body'];

  if (title == null || title.isEmpty) return;

  final plugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await plugin.initialize(initSettings);

  final type = data['type'] ?? data['notification_type'] ?? '';

  if (_urgentNotificationTypes.contains(type)) {
    // Créer le canal urgent si nécessaire
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          NotificationChannels.channels[NotificationChannels
              .urgentOrdersChannel]!,
        );
    await _showUrgentNotification(plugin, title, body ?? '', data);
  } else {
    await _showStandardNotification(plugin, title, body ?? '', data);
  }
}

/// Affiche une notification urgente (full-screen, son en boucle).
Future<void> _showUrgentNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body,
  Map<String, dynamic> data,
) async {
  await plugin.show(
    999, // ID fixe pour pouvoir l'annuler
    '🔔 $title',
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.urgentOrdersChannel,
        'Commandes urgentes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('order_received'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        additionalFlags: Int32List.fromList([
          4,
        ]), // FLAG_INSISTENT → son en boucle
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: '🔔 $title',
        ),
        actions: const [
          AndroidNotificationAction(
            'voir_commande',
            'Voir la commande',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    ),
    payload: jsonEncode(data),
  );
}

/// Affiche une notification standard.
Future<void> _showStandardNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body,
  Map<String, dynamic> data,
) async {
  final channelId =
      data['channel_id'] as String? ??
      _getChannelForType(data['type'] ?? data['notification_type']);
  final soundName =
      data['sound'] as String? ?? _channelSounds[channelId] ?? 'order_received';

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        NotificationChannels.channels[channelId]?.name ?? 'Commandes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundName),
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
      ),
      iOS: const DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      ),
    ),
    payload: jsonEncode(data),
  );
}

/// Détermine le canal de notification basé sur le type.
String _getChannelForType(String? type) {
  if (type == null) return NotificationChannels.systemChannel;
  if (_orderNotificationTypes.contains(type))
    return NotificationChannels.ordersChannel;
  if (_stockNotificationTypes.contains(type))
    return NotificationChannels.stockChannel;
  if (_paymentNotificationTypes.contains(type))
    return NotificationChannels.paymentsChannel;
  return NotificationChannels.systemChannel;
}

/// Types de notifications supportés
enum NotificationType {
  newOrder,
  orderStatusChange,
  lowStock,
  prescription,
  payment,
  system,
  promotion,
}

/// Configuration des canaux de notification
class NotificationChannels {
  static const String ordersChannel = 'orders_channel';
  static const String urgentOrdersChannel = 'urgent_orders_channel';
  static const String stockChannel = 'stock_channel';
  static const String paymentsChannel = 'payments_channel';
  static const String systemChannel = 'system_channel';

  static const Map<String, AndroidNotificationChannel> channels = {
    ordersChannel: AndroidNotificationChannel(
      ordersChannel,
      'Commandes',
      description: 'Notifications pour les nouvelles commandes',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('order_received'),
      enableVibration: true,
      ledColor: const ui.Color(0xFF2E7D32),
    ),
    urgentOrdersChannel: AndroidNotificationChannel(
      urgentOrdersChannel,
      'Commandes urgentes',
      description: 'Alerte persistante — sonne même en veille',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('order_received'),
      enableVibration: true,
      enableLights: true,
      ledColor: const ui.Color(0xFFFF0000),
    ),
    stockChannel: AndroidNotificationChannel(
      stockChannel,
      'Stock',
      description: 'Alertes de stock bas ou rupture',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alert'),
      enableVibration: true,
    ),
    paymentsChannel: AndroidNotificationChannel(
      paymentsChannel,
      'Paiements',
      description: 'Notifications de paiement',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('chime'),
    ),
    systemChannel: AndroidNotificationChannel(
      systemChannel,
      'Système',
      description: 'Notifications système',
      importance: Importance.defaultImportance,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('soft'),
    ),
  };
}

class NotificationService {
  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Callbacks pour la navigation
  Function(Map<String, dynamic> data)? onNotificationTapped;
  Function(RemoteMessage message)? onForegroundMessage;

  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      _log('Firebase not initialized. NotificationService disabled.');
      return;
    }

    try {
      _firebaseMessaging = FirebaseMessaging.instance;

      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );
      _log('✅ User granted permission: ${settings.authorizationStatus}');

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );
      await _createNotificationChannels();

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) _handleMessageOpenedApp(initialMessage);

      _log('✅ FCM Token: ${await getToken()}');
    } catch (e) {
      _log('❌ Error initializing NotificationService: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      for (final channel in NotificationChannels.channels.values) {
        await androidImpl.createNotificationChannel(channel);
      }
      _log('✅ Notification channels created');
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _log('📱 Notification tapped with payload: ${response.payload}');
    if (response.payload != null) {
      try {
        onNotificationTapped?.call(
          jsonDecode(response.payload!) as Map<String, dynamic>,
        );
      } catch (e) {
        _log('Error parsing notification payload: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _log('📬 Got foreground message: ${message.data}');
    onForegroundMessage?.call(message);

    final data = message.data;
    final title = data['title'] ?? message.notification?.title;
    final body = data['body'] ?? message.notification?.body;

    if (title != null && title.isNotEmpty) {
      _showLocalNotificationFromData(title, body ?? '', data);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _log('📱 App opened from notification: ${message.data}');
    onNotificationTapped?.call(message.data);
  }

  Future<String?> getToken() async {
    if (_firebaseMessaging == null) return null;
    try {
      return await _firebaseMessaging!.getToken();
    } catch (e) {
      _log('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (_firebaseMessaging == null) return;
    await _firebaseMessaging!.subscribeToTopic(topic);
    _log('✅ Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (_firebaseMessaging == null) return;
    await _firebaseMessaging!.unsubscribeFromTopic(topic);
    _log('✅ Unsubscribed from topic: $topic');
  }

  /// Show local notification from data-only FCM message (delegates to shared helpers).
  Future<void> _showLocalNotificationFromData(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final type = data['type'] ?? data['notification_type'] ?? '';
    if (_urgentNotificationTypes.contains(type)) {
      await _showUrgentNotification(_localNotifications, title, body, data);
    } else {
      await _showStandardNotification(_localNotifications, title, body, data);
    }
  }

  /// Affiche une notification locale personnalisée.
  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? channelId,
    Map<String, dynamic>? data,
  }) async {
    final channel = channelId ?? NotificationChannels.systemChannel;
    final soundName = _channelSounds[channel] ?? 'soft';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          NotificationChannels.channels[channel]?.name ?? 'Default',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  Future<void> clearAllNotifications() => _localNotifications.cancelAll();
  Future<void> clearNotification(int id) => _localNotifications.cancel(id);

  Future<void> updateBadgeCount(int count) async {
    _log('📛 Badge count updated to: $count');
  }
}
