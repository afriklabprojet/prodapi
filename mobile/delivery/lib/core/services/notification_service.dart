import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

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
      estimatedEarnings: double.tryParse(data['estimated_earnings']?.toString() ?? ''),
      distanceKm: double.tryParse(data['distance_km']?.toString() ?? ''),
    );
  }
}

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final dynamic _dio;
  
  // Stream controller pour les nouvelles commandes
  final _newOrderController = StreamController<NewOrderNotification?>.broadcast();
  Stream<NewOrderNotification?> get newOrderStream => _newOrderController.stream;
  
  // Callback pour quand une notification est tapée
  Function(String orderId)? onNotificationTapped;

  // Stocker les subscriptions FCM pour les annuler dans dispose()
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  NotificationService(this._dio);

  /// Initialise les notifications locales
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Quand l'utilisateur tape sur la notification
        final payload = response.payload;
        if (payload != null && onNotificationTapped != null) {
          onNotificationTapped!(payload);
        }
      },
    );
    
    // Créer le canal pour Android (haute priorité pour les commandes)
    const androidChannel = AndroidNotificationChannel(
      'new_orders_channel',
      'Nouvelles Commandes',
      description: 'Notifications pour les nouvelles commandes de livraison',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Affiche une notification locale pour une nouvelle commande
  Future<void> _showOrderNotification(NewOrderNotification order) async {
    final androidDetails = AndroidNotificationDetails(
      'new_orders_channel',
      'Nouvelles Commandes',
      channelDescription: 'Notifications pour les nouvelles commandes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final earningsText = order.estimatedEarnings != null 
        ? ' • ${order.estimatedEarnings!.toStringAsFixed(0)} FCFA'
        : '';
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚚 Nouvelle commande !',
      '${order.pharmacyName}$earningsText\n${order.deliveryAddress}',
      details,
      payload: order.orderId,
    );
  }

  /// Configure les listeners pour les messages FCM
  void _setupMessageHandlers() {
    // Message reçu quand l'app est en foreground
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        if (kDebugMode) print('📬 FCM Message (foreground): ${message.data}');
      }
      _handleIncomingMessage(message, isBackground: false);
    });
    
    // Message qui a ouvert l'app depuis un état terminé
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          if (kDebugMode) print('📬 FCM Initial Message: ${message.data}');
        }
        _handleIncomingMessage(message, isBackground: true);
      }
    });
    
    // Message tapé quand l'app était en background
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        if (kDebugMode) print('📬 FCM Message Opened: ${message.data}');
      }
      final orderId = message.data['order_id'] ?? message.data['delivery_id'];
      if (orderId != null && onNotificationTapped != null) {
        onNotificationTapped!(orderId);
      }
    });
  }

  /// Traite un message entrant
  void _handleIncomingMessage(RemoteMessage message, {required bool isBackground}) {
    final type = message.data['type'] ?? message.notification?.title ?? '';
    
    // Vérifier si c'est une notification de nouvelle commande
    if (type == 'new_order' || 
        type == 'new_delivery' || 
        message.data.containsKey('order_id') ||
        message.data.containsKey('delivery_id')) {
      
      final notification = NewOrderNotification.fromMessage(message);
      
      // Émettre sur le stream
      _newOrderController.add(notification);
      
      // Afficher notification locale si en foreground
      if (!isBackground) {
        _showOrderNotification(notification);
      }
    }
  }

  Future<void> initNotifications() async {
    try {
      // Initialiser les notifications locales
      await _initLocalNotifications();
      
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      ).timeout(const Duration(seconds: 10));

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          if (kDebugMode) print('User granted permission');
        }
        
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
             if (kDebugMode) debugPrint('Web Push requires VAPID key. Skipping token retrieval for now to prevent crash.');
             return; 
          } catch (e) {
             if (kDebugMode) debugPrint('Error getting web token: $e');
          }
        } else {
          fcmToken = await _firebaseMessaging.getToken()
              .timeout(const Duration(seconds: 10));
        }

        if (kDebugMode) {
          if (kDebugMode) debugPrint('FCM Token: $fcmToken');
        }

        // Send token to backend
        if (fcmToken != null) {
          await _updateTokenOnServer(fcmToken);
        }

        // Handle token updates
        _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(_updateTokenOnServer);
      } else {
        if (kDebugMode) {
          if (kDebugMode) print('User declined or has not accepted permission');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('Notification initialization failed: $e');
      }
      // Do not rethrow to prevent blocking the login flow
    }
  }

  Future<void> _updateTokenOnServer(String token) async {
    try {
      // Assuming Dio instance from ApiClient provider is fully configured with baseUrl and interceptors
      // Using raw Dio instance passed from provider
      // Prepended /api because ApiConstants.baseUrl does not include it (Fixed: ApiConstants includes /api)
      await _dio.post(
        '/notifications/fcm-token',
        data: {'fcm_token': token},
      );
      if (kDebugMode) {
        if (kDebugMode) print('FCM Token updated on server');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('Failed to update FCM token on server: $e');
      }
    }
  }
  
  /// Nettoyer les ressources
  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _newOrderController.close();
  }
}
