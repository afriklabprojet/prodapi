import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

/// Action IDs for notification buttons
class NotificationActions {
  static const String acceptOrder = 'ACCEPT_ORDER';
  static const String declineOrder = 'DECLINE_ORDER';
  static const String viewDetails = 'VIEW_DETAILS';
}

/// Result of a notification action
class NotificationActionResult {
  final String actionId;
  final String? orderId;
  final Map<String, dynamic>? payload;

  NotificationActionResult({
    required this.actionId,
    this.orderId,
    this.payload,
  });
}

// Singleton instance for background handler reuse
final FlutterLocalNotificationsPlugin _bgNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
bool _bgPluginInitialized = false;

// Top-level function for background handling of data-only FCM messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint("Handling a background message: ${message.messageId}");
  }

  final data = message.data;
  final title = data['title'];
  final body = data['body'];

  if (title == null || title.isEmpty) return;

  if (!_bgPluginInitialized) {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _bgNotificationsPlugin.initialize(initSettings);
    _bgPluginInitialized = true;
  }

  final type = data['type'] ?? '';
  final isDeliveryAlert =
      type == 'new_order' ||
      type == 'new_delivery' ||
      data.containsKey('order_id') ||
      data.containsKey('delivery_id');

  if (isDeliveryAlert) {
    // Créer le canal urgent s'il n'existe pas
    final androidImpl = _bgNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          'urgent_delivery_channel',
          'Courses urgentes',
          description:
              'Alerte persistante pour nouvelle course — sonne même en veille',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_new_order'),
          enableVibration: true,
          enableLights: true,
          ledColor: ui.Color(0xFFFF0000),
        ),
      );
    }

    // Notification avec full-screen intent : allume l'écran et sonne en boucle
    await _bgNotificationsPlugin.show(
      999, // ID fixe pour pouvoir l'annuler
      '🚚 $title',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'urgent_delivery_channel',
          'Courses urgentes',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(
            'notification_new_order',
          ),
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
            body ?? '',
            contentTitle: '🚚 $title',
          ),
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              'VIEW_DETAILS',
              'Voir la course',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: jsonEncode(data),
    );
  } else {
    // Notification standard pour les autres types
    final channelId = data['channel_id'] ?? 'new_orders_channel_v2';
    final soundName = data['sound'] ?? 'notification_new_order';

    await _bgNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Livraisons',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body ?? ''),
        ),
      ),
      payload: jsonEncode(data),
    );
  }
}

/// Provider pour le service de notifications
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref.read(dioProvider));
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider pour écouter les nouvelles commandes en temps réel
final newOrderStreamProvider = StreamProvider<NewOrderNotification?>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.newOrderStream;
});

/// Provider pour le compteur de notifications non lues
final unreadNotificationsCountProvider = Provider<int>((ref) => 0);

/// Provider pour écouter les actions de notification (Accept/Decline)
final notificationActionStreamProvider =
    StreamProvider<NotificationActionResult>((ref) {
      final notificationService = ref.watch(notificationServiceProvider);
      return notificationService.actionStream;
    });

/// Modèle pour une notification de nouvelle commande
class NewOrderNotification {
  final String orderId;
  final String pharmacyName;
  final String deliveryAddress;
  final double amount;
  final double? estimatedEarnings;
  final double? distanceKm;
  final DateTime receivedAt;

  NewOrderNotification({
    required this.orderId,
    required this.pharmacyName,
    required this.deliveryAddress,
    required this.amount,
    this.estimatedEarnings,
    this.distanceKm,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory NewOrderNotification.fromMessage(RemoteMessage message) {
    final data = message.data;
    return NewOrderNotification(
      orderId: data['order_id'] ?? data['delivery_id'] ?? '',
      pharmacyName: data['pharmacy_name'] ?? 'Pharmacie',
      deliveryAddress: data['delivery_address'] ?? '',
      amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0,
      estimatedEarnings: double.tryParse(
        data['estimated_earnings']?.toString() ?? '',
      ),
      distanceKm: double.tryParse(data['distance_km']?.toString() ?? ''),
    );
  }
}

class NotificationService {
  final FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin? _localNotifications;
  final dynamic _dio;

  // Stream controller pour les nouvelles commandes
  final _newOrderController =
      StreamController<NewOrderNotification?>.broadcast();
  Stream<NewOrderNotification?> get newOrderStream =>
      _newOrderController.stream;

  // Stream controller pour les actions de notification (Accept/Decline)
  final _actionController =
      StreamController<NotificationActionResult>.broadcast();
  Stream<NotificationActionResult> get actionStream => _actionController.stream;

  /// Construction normale - utilise les instances par défaut
  NotificationService(this._dio)
    : _firebaseMessaging = null,
      _localNotifications = null;

  /// Constructeur pour tests - permet l'injection de mocks
  NotificationService.forTest(
    this._dio, {
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _firebaseMessaging = firebaseMessaging,
       _localNotifications = localNotifications;

  FirebaseMessaging get _messaging =>
      _firebaseMessaging ?? FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin get _notifications =>
      _localNotifications ?? FlutterLocalNotificationsPlugin();

  // Callback pour quand une notification est tapée
  Function(String orderId)? onNotificationTapped;

  // Callback pour quand une action est sélectionnée
  Function(NotificationActionResult action)? onActionSelected;

  // Stocker les subscriptions FCM pour les annuler dans dispose()
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  bool _initialized = false;

  /// Initialise les notifications locales
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Créer le canal pour Android (haute priorité pour les commandes)
    // Use versioned channel ID to force re-creation if settings change
    const androidChannel = AndroidNotificationChannel(
      'new_orders_channel_v2',
      'Nouvelles Commandes',
      description: 'Notifications pour les nouvelles commandes de livraison',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_new_order'),
      enableVibration: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(androidChannel);

    // Canal urgent pour les courses : fullscreen + son en boucle même en veille
    const urgentChannel = AndroidNotificationChannel(
      'urgent_delivery_channel',
      'Courses urgentes',
      description: 'Alerte persistante — sonne même en veille',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_new_order'),
      enableVibration: true,
      enableLights: true,
      ledColor: ui.Color(0xFFFF0000),
    );

    await androidPlugin?.createNotificationChannel(urgentChannel);

    // Delete old channel that may have been cached without sound
    await androidPlugin?.deleteNotificationChannel('new_orders_channel');
  }

  /// Handle notification response (tap or action button)
  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    // Parse payload to get order ID
    String? orderId;
    Map<String, dynamic>? payloadData;

    if (payload != null) {
      try {
        payloadData = jsonDecode(payload) as Map<String, dynamic>;
        orderId =
            payloadData['order_id']?.toString() ??
            payloadData['delivery_id']?.toString();
      } catch (e) {
        // Payload is a simple string (orderId)
        orderId = payload;
        if (kDebugMode) {
          debugPrint('📱 Notification payload is simple string: $orderId');
        }
      }
    }

    // Handle action button press
    if (actionId != null && actionId.isNotEmpty) {
      final actionResult = NotificationActionResult(
        actionId: actionId,
        orderId: orderId,
        payload: payloadData,
      );

      // Emit to stream only (single path to avoid duplicate handling)
      _actionController.add(actionResult);

      // Add haptic feedback
      HapticFeedback.mediumImpact();

      if (kDebugMode) {
        debugPrint('📱 Notification action: $actionId for order: $orderId');
      }
      return;
    }

    // Handle regular tap (no action button)
    if (orderId != null && onNotificationTapped != null) {
      onNotificationTapped!(orderId);
    }
  }

  /// Affiche une notification locale pour une nouvelle commande avec boutons d'action
  Future<void> _showOrderNotification(NewOrderNotification order) async {
    // Action buttons for quick response
    const acceptAction = AndroidNotificationAction(
      NotificationActions.acceptOrder,
      '✓ Accepter',
      icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
      showsUserInterface: true,
      cancelNotification: true,
    );

    const declineAction = AndroidNotificationAction(
      NotificationActions.declineOrder,
      '✗ Refuser',
      icon: DrawableResourceAndroidBitmap('@drawable/ic_close'),
      showsUserInterface: false,
      cancelNotification: true,
    );

    final androidDetails = AndroidNotificationDetails(
      'urgent_delivery_channel',
      'Courses urgentes',
      channelDescription: 'Alerte persistante pour nouvelle course',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(
        'notification_new_order',
      ),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      additionalFlags: Int32List.fromList([
        4,
      ]), // FLAG_INSISTENT → son en boucle
      // Add action buttons
      actions: const [acceptAction, declineAction],
      // Show expanded content
      styleInformation: BigTextStyleInformation(
        buildNotificationBody(order),
        contentTitle: '🚚 Nouvelle course !',
        summaryText: order.estimatedEarnings != null
            ? '${order.estimatedEarnings!.toStringAsFixed(0)} FCFA'
            : null,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // iOS uses categories for actions (defined in app delegate)
      categoryIdentifier: 'NEW_ORDER_CATEGORY',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Build payload with order data for action handling
    final payloadData = {
      'order_id': order.orderId,
      'pharmacy_name': order.pharmacyName,
      'delivery_address': order.deliveryAddress,
      'amount': order.amount,
      'estimated_earnings': order.estimatedEarnings,
      'distance_km': order.distanceKm,
    };

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚚 Nouvelle commande !',
      buildNotificationBody(order),
      details,
      payload: jsonEncode(payloadData),
    );
  }

  /// Build notification body text - visible for testing
  @visibleForTesting
  String buildNotificationBody(NewOrderNotification order) {
    final buffer = StringBuffer(order.pharmacyName);

    if (order.estimatedEarnings != null) {
      buffer.write(' • ${order.estimatedEarnings!.toStringAsFixed(0)} FCFA');
    }

    if (order.distanceKm != null) {
      buffer.write(' • ${order.distanceKm!.toStringAsFixed(1)} km');
    }

    buffer.write('\n📍 ${order.deliveryAddress}');

    return buffer.toString();
  }

  /// Add new order to stream - visible for testing
  @visibleForTesting
  void addNewOrder(NewOrderNotification order) {
    _newOrderController.add(order);
  }

  /// Add action to stream - visible for testing
  @visibleForTesting
  void addAction(NotificationActionResult action) {
    _actionController.add(action);
  }

  /// Check if streams are closed - visible for testing
  @visibleForTesting
  bool get isDisposed =>
      _newOrderController.isClosed && _actionController.isClosed;

  /// Configure les listeners pour les messages FCM
  void _setupMessageHandlers() {
    // Message reçu quand l'app est en foreground
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) print('📬 FCM Message (foreground): ${message.data}');
      _handleIncomingMessage(message, isBackground: false);
    });

    // Message qui a ouvert l'app depuis un état terminé
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        if (kDebugMode) print('📬 FCM Initial Message: ${message.data}');
        _handleIncomingMessage(message, isBackground: true);
      }
    });

    // Message tapé quand l'app était en background
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      if (kDebugMode) print('📬 FCM Message Opened: ${message.data}');
      final orderId = message.data['order_id'] ?? message.data['delivery_id'];
      if (orderId != null && onNotificationTapped != null) {
        onNotificationTapped!(orderId);
      }
    });
  }

  /// Traite un message entrant (data-only messages from FcmChannel)
  void _handleIncomingMessage(
    RemoteMessage message, {
    required bool isBackground,
  }) {
    final data = message.data;
    final type = data['type'] ?? '';

    // Vérifier si c'est une notification de nouvelle commande
    if (type == 'new_order' ||
        type == 'new_delivery' ||
        data.containsKey('order_id') ||
        data.containsKey('delivery_id')) {
      final notification = NewOrderNotification.fromMessage(message);

      // Émettre sur le stream
      _newOrderController.add(notification);

      // Afficher notification locale si en foreground
      if (!isBackground) {
        _showOrderNotification(notification);
      }
    } else if (!isBackground) {
      // For non-order data-only messages, show local notification with correct channel/sound
      final title = data['title'] ?? '';
      final body = data['body'] ?? '';
      if (title.isNotEmpty) {
        _showLocalNotificationFromData(title, body, data);
      }
    }
  }

  /// Show local notification from data-only FCM payload
  Future<void> _showLocalNotificationFromData(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final channelId = data['channel_id'] ?? 'new_orders_channel_v2';
    final soundName = data['sound'] ?? 'notification_new_order';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Livraisons',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  Future<void> initNotifications() async {
    // Guard against duplicate initialization (prevents duplicate subscriptions)
    if (_initialized) return;
    _initialized = true;

    try {
      // Register background handler for data-only FCM messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Initialiser les notifications locales
      await _initLocalNotifications();

      // Request permission
      NotificationSettings settings = await _messaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          )
          .timeout(const Duration(seconds: 10));

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) print('User granted permission');

        // Configurer les handlers de messages
        _setupMessageHandlers();

        // Get token
        String? fcmToken;
        if (kIsWeb) {
          // Web requires VAPID key. Skipping if not provided or just catching error.
          // You need to generate a specific VAPID key in Firebase Console -> Project Settings -> Cloud Messaging -> Web Push Certificates
          // and pass it here: getToken(vapidKey: "YOUR_KEY");
          try {
            // Attempting without key might fail or work depending on config, but usually fails.
            // We just log that web push needs setup.
            if (kDebugMode) {
              debugPrint(
                'Web Push requires VAPID key. Skipping token retrieval for now to prevent crash.',
              );
            }
            return;
          } catch (e) {
            if (kDebugMode) debugPrint('Error getting web token: $e');
          }
        } else {
          fcmToken = await _messaging.getToken().timeout(
            const Duration(seconds: 10),
          );
        }

        if (kDebugMode) debugPrint('FCM Token: $fcmToken');

        // Send token to backend
        if (fcmToken != null) {
          await _updateTokenOnServer(fcmToken);
        }

        // Handle token updates
        _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
          _updateTokenOnServer,
        );
      } else {
        if (kDebugMode) print('User declined or has not accepted permission');
      }
    } catch (e) {
      if (kDebugMode) print('Notification initialization failed: $e');
      // Do not rethrow to prevent blocking the login flow
    }
  }

  Future<void> _updateTokenOnServer(String token) async {
    try {
      // Assuming Dio instance from ApiClient provider is fully configured with baseUrl and interceptors
      // Using raw Dio instance passed from provider
      // Prepended /api because ApiConstants.baseUrl does not include it (Fixed: ApiConstants includes /api)
      await _dio.post('/notifications/fcm-token', data: {'fcm_token': token});
      if (kDebugMode) print('FCM Token updated on server');
    } catch (e) {
      if (kDebugMode) print('Failed to update FCM token on server: $e');
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _newOrderController.close();
    _actionController.close();
  }
}
