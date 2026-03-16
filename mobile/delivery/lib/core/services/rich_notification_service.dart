import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TYPES ET MODÈLES
// ══════════════════════════════════════════════════════════════════════════════

/// Types de notifications avec configuration personnalisée
enum NotificationType {
  newOrder,       // Nouvelle commande disponible
  orderAssigned,  // Commande assignée au livreur
  urgent,         // Notification urgente
  reminder,       // Rappel
  earnings,       // Notification de gains
  system,         // Message système
  chat,           // Message de chat
  promo,          // Promotion / offre
}

/// Extension pour les propriétés de chaque type
extension NotificationTypeConfig on NotificationType {
  String get channelId {
    switch (this) {
      case NotificationType.newOrder:
        return 'new_orders_high';
      case NotificationType.orderAssigned:
        return 'order_assigned';
      case NotificationType.urgent:
        return 'urgent_alerts';
      case NotificationType.reminder:
        return 'reminders';
      case NotificationType.earnings:
        return 'earnings';
      case NotificationType.system:
        return 'system';
      case NotificationType.chat:
        return 'chat_messages';
      case NotificationType.promo:
        return 'promotions';
    }
  }

  String get channelName {
    switch (this) {
      case NotificationType.newOrder:
        return 'Nouvelles commandes';
      case NotificationType.orderAssigned:
        return 'Commandes assignées';
      case NotificationType.urgent:
        return 'Alertes urgentes';
      case NotificationType.reminder:
        return 'Rappels';
      case NotificationType.earnings:
        return 'Gains & revenus';
      case NotificationType.system:
        return 'Système';
      case NotificationType.chat:
        return 'Messages';
      case NotificationType.promo:
        return 'Promotions';
    }
  }

  String get channelDescription {
    switch (this) {
      case NotificationType.newOrder:
        return 'Notifications pour les nouvelles livraisons disponibles';
      case NotificationType.orderAssigned:
        return 'Quand une commande vous est attribuée';
      case NotificationType.urgent:
        return 'Alertes importantes nécessitant une action immédiate';
      case NotificationType.reminder:
        return 'Rappels de livraisons en cours';
      case NotificationType.earnings:
        return 'Notifications sur vos gains et paiements';
      case NotificationType.system:
        return 'Messages système et mises à jour';
      case NotificationType.chat:
        return 'Messages des clients et pharmacies';
      case NotificationType.promo:
        return 'Offres spéciales et promotions';
    }
  }

  Importance get importance {
    switch (this) {
      case NotificationType.newOrder:
      case NotificationType.urgent:
        return Importance.max;
      case NotificationType.orderAssigned:
      case NotificationType.chat:
        return Importance.high;
      case NotificationType.reminder:
      case NotificationType.earnings:
        return Importance.defaultImportance;
      case NotificationType.system:
      case NotificationType.promo:
        return Importance.low;
    }
  }

  Priority get priority {
    switch (this) {
      case NotificationType.newOrder:
      case NotificationType.urgent:
        return Priority.max;
      case NotificationType.orderAssigned:
      case NotificationType.chat:
        return Priority.high;
      default:
        return Priority.defaultPriority;
    }
  }

  String get soundName {
    switch (this) {
      case NotificationType.newOrder:
        return 'notification_new_order';
      case NotificationType.urgent:
        return 'notification_urgent';
      case NotificationType.earnings:
        return 'notification_cash';
      case NotificationType.chat:
        return 'notification_chat';
      default:
        return 'default';
    }
  }

  String get emoji {
    switch (this) {
      case NotificationType.newOrder:
        return '🚚';
      case NotificationType.orderAssigned:
        return '✅';
      case NotificationType.urgent:
        return '🚨';
      case NotificationType.reminder:
        return '⏰';
      case NotificationType.earnings:
        return '💰';
      case NotificationType.system:
        return 'ℹ️';
      case NotificationType.chat:
        return '💬';
      case NotificationType.promo:
        return '🎁';
    }
  }

  List<int> get vibrationPattern {
    switch (this) {
      case NotificationType.newOrder:
        return [0, 500, 200, 500, 200, 500]; // Long pattern pour attirer l'attention
      case NotificationType.urgent:
        return [0, 1000, 500, 1000]; // Pattern intense
      case NotificationType.earnings:
        return [0, 300, 100, 300]; // Pattern "cha-ching"
      default:
        return [0, 250, 100, 250]; // Pattern standard
    }
  }
}

/// Configuration des préférences de notification utilisateur
class NotificationPreferences {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool newOrdersEnabled;
  final bool chatEnabled;
  final bool earningsEnabled;
  final bool promosEnabled;
  final bool urgentEnabled;
  final String selectedSound;
  final bool quietHoursEnabled;
  final int quietHoursStart; // 0-23
  final int quietHoursEnd;   // 0-23

  const NotificationPreferences({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.newOrdersEnabled = true,
    this.chatEnabled = true,
    this.earningsEnabled = true,
    this.promosEnabled = false,
    this.urgentEnabled = true,
    this.selectedSound = 'default',
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
  });

  NotificationPreferences copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? newOrdersEnabled,
    bool? chatEnabled,
    bool? earningsEnabled,
    bool? promosEnabled,
    bool? urgentEnabled,
    String? selectedSound,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
  }) {
    return NotificationPreferences(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      newOrdersEnabled: newOrdersEnabled ?? this.newOrdersEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      earningsEnabled: earningsEnabled ?? this.earningsEnabled,
      promosEnabled: promosEnabled ?? this.promosEnabled,
      urgentEnabled: urgentEnabled ?? this.urgentEnabled,
      selectedSound: selectedSound ?? this.selectedSound,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  bool get isQuietTime {
    if (!quietHoursEnabled) return false;
    
    final now = DateTime.now().hour;
    if (quietHoursStart < quietHoursEnd) {
      return now >= quietHoursStart && now < quietHoursEnd;
    } else {
      // Crossing midnight (e.g., 22h - 7h)
      return now >= quietHoursStart || now < quietHoursEnd;
    }
  }

  Map<String, dynamic> toJson() => {
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    'newOrdersEnabled': newOrdersEnabled,
    'chatEnabled': chatEnabled,
    'earningsEnabled': earningsEnabled,
    'promosEnabled': promosEnabled,
    'urgentEnabled': urgentEnabled,
    'selectedSound': selectedSound,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      newOrdersEnabled: json['newOrdersEnabled'] ?? true,
      chatEnabled: json['chatEnabled'] ?? true,
      earningsEnabled: json['earningsEnabled'] ?? true,
      promosEnabled: json['promosEnabled'] ?? false,
      urgentEnabled: json['urgentEnabled'] ?? true,
      selectedSound: json['selectedSound'] ?? 'default',
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: json['quietHoursStart'] ?? 22,
      quietHoursEnd: json['quietHoursEnd'] ?? 7,
    );
  }
}

/// Notification enrichie avec actions rapides
class RichNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final List<NotificationAction>? actions;
  final DateTime createdAt;
  final bool isRead;

  RichNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    this.actions,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  RichNotification copyWith({bool? isRead}) {
    return RichNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      actions: actions,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Action rapide sur une notification
class NotificationAction {
  final String id;
  final String label;
  final String? icon;
  final bool destructive;

  const NotificationAction({
    required this.id,
    required this.label,
    this.icon,
    this.destructive = false,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// SERVICE DE NOTIFICATIONS ENRICHIES
// ══════════════════════════════════════════════════════════════════════════════

/// Service de notifications enrichies avec sons personnalisés et actions rapides
class RichNotificationService extends StateNotifier<List<RichNotification>> {
  RichNotificationService() : super([]) {
    _init();
  }

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  SharedPreferences? _prefs;
  NotificationPreferences _preferences = const NotificationPreferences();
  
  // Stream pour écouter les actions de notification
  final _actionController = StreamController<NotificationActionEvent>.broadcast();
  Stream<NotificationActionEvent> get actionStream => _actionController.stream;

  // Callback pour navigation
  Function(String notificationId, String? actionId, Map<String, dynamic>? data)? onNotificationAction;

  NotificationPreferences get preferences => _preferences;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();
    await _initializeNotifications();
  }

  Future<void> _loadPreferences() async {
    final json = _prefs?.getString('notification_preferences');
    if (json != null) {
      try {
        final map = Map<String, dynamic>.from(
          Map.castFrom(Uri.splitQueryString(json).map(
            (key, value) => MapEntry(key, _parseValue(value)),
          )),
        );
        _preferences = NotificationPreferences.fromJson(map);
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [RichNotif] Erreur parsing préférences: $e');
      }
    }
  }

  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    final intVal = int.tryParse(value);
    if (intVal != null) return intVal;
    return value;
  }

  Future<void> savePreferences(NotificationPreferences newPrefs) async {
    _preferences = newPrefs;
    final json = newPrefs.toJson().entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    await _prefs?.setString('notification_preferences', json);
    if (kDebugMode) debugPrint('✅ [RichNotif] Préférences sauvegardées');
  }

  Future<void> _initializeNotifications() async {
    // Android settings avec actions
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings - non-const due to DarwinNotificationCategory
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'NEW_ORDER',
          actions: [
            DarwinNotificationAction.plain('ACCEPT', 'Accepter'),
            DarwinNotificationAction.plain('REJECT', 'Refuser',
              options: {DarwinNotificationActionOption.destructive}),
          ],
          options: {
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        ),
        DarwinNotificationCategory(
          'CHAT',
          actions: [
            DarwinNotificationAction.plain('REPLY', 'Répondre'),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Créer les canaux Android
    await _createNotificationChannels();
    
    if (kDebugMode) debugPrint('✅ [RichNotif] Initialisé avec canaux personnalisés');
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    // Créer un canal pour chaque type
    for (final type in NotificationType.values) {
      final channel = AndroidNotificationChannel(
        type.channelId,
        type.channelName,
        description: type.channelDescription,
        importance: type.importance,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(type.vibrationPattern),
        // Note: Custom sounds require files in android/app/src/main/res/raw/
        // sound: RawResourceAndroidNotificationSound(type.soundName),
      );

      await androidPlugin.createNotificationChannel(channel);
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('📬 [RichNotif] Response: ${response.actionId} - ${response.payload}');
    }

    final notificationId = response.payload ?? '';
    final actionId = response.actionId;

    // Trouver la notification
    final notification = state.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => RichNotification(id: '', type: NotificationType.system, title: '', body: ''),
    );

    // Émettre l'événement
    _actionController.add(NotificationActionEvent(
      notificationId: notificationId,
      actionId: actionId,
      data: notification.data,
    ));

    // Callback
    onNotificationAction?.call(notificationId, actionId, notification.data);

    // Marquer comme lu
    if (notificationId.isNotEmpty) {
      markAsRead(notificationId);
    }
  }

  /// Affiche une notification enrichie
  Future<void> showNotification({
    required String id,
    required NotificationType type,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    List<NotificationAction>? actions,
  }) async {
    // Vérifier les préférences
    if (!_shouldShowNotification(type)) {
      if (kDebugMode) debugPrint('🔕 [RichNotif] Notification $type ignorée (préférences)');
      return;
    }

    // Créer l'objet notification
    final notification = RichNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      actions: actions,
    );

    // Ajouter à la liste (en tête)
    state = [notification, ...state.take(99)]; // Garder max 100 notifications

    // Construire les détails Android
    final androidDetails = AndroidNotificationDetails(
      type.channelId,
      type.channelName,
      channelDescription: type.channelDescription,
      importance: type.importance,
      priority: type.priority,
      icon: '@mipmap/ic_launcher',
      playSound: _preferences.soundEnabled && !_preferences.isQuietTime,
      enableVibration: _preferences.vibrationEnabled && !_preferences.isQuietTime,
      vibrationPattern: _preferences.vibrationEnabled 
          ? Int64List.fromList(type.vibrationPattern) 
          : null,
      styleInformation: BigTextStyleInformation(body),
      actions: actions?.map((a) => AndroidNotificationAction(
        a.id,
        a.label,
        cancelNotification: a.destructive,
      )).toList(),
    );

    // Construire les détails iOS
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _preferences.soundEnabled && !_preferences.isQuietTime,
      categoryIdentifier: _getCategoryIdentifier(type),
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Afficher la notification
    await _localNotifications.show(
      id.hashCode,
      '${type.emoji} $title',
      body,
      details,
      payload: id,
    );

    if (kDebugMode) debugPrint('🔔 [RichNotif] Notification affichée: $type - $title');
  }

  bool _shouldShowNotification(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.orderAssigned:
        return _preferences.newOrdersEnabled;
      case NotificationType.chat:
        return _preferences.chatEnabled;
      case NotificationType.earnings:
        return _preferences.earningsEnabled;
      case NotificationType.promo:
        return _preferences.promosEnabled;
      case NotificationType.urgent:
        return _preferences.urgentEnabled;
      default:
        return true;
    }
  }

  String? _getCategoryIdentifier(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return 'NEW_ORDER';
      case NotificationType.chat:
        return 'CHAT';
      default:
        return null;
    }
  }

  /// Affiche une notification de nouvelle commande avec actions rapides
  Future<void> showNewOrderNotification({
    required String orderId,
    required String pharmacyName,
    required String deliveryAddress,
    double? amount,
    double? estimatedEarnings,
    double? distanceKm,
  }) async {
    final earningsText = estimatedEarnings != null
        ? ' • ${estimatedEarnings.toStringAsFixed(0)} FCFA'
        : '';
    final distanceText = distanceKm != null
        ? ' • ${distanceKm.toStringAsFixed(1)} km'
        : '';

    await showNotification(
      id: 'order_$orderId',
      type: NotificationType.newOrder,
      title: 'Nouvelle commande disponible !',
      body: '$pharmacyName$earningsText$distanceText\n📍 $deliveryAddress',
      data: {
        'order_id': orderId,
        'pharmacy_name': pharmacyName,
        'delivery_address': deliveryAddress,
        'amount': amount,
        'estimated_earnings': estimatedEarnings,
        'distance_km': distanceKm,
      },
      actions: const [
        NotificationAction(id: 'ACCEPT', label: 'Accepter', icon: '✅'),
        NotificationAction(id: 'REJECT', label: 'Refuser', icon: '❌', destructive: true),
      ],
    );
  }

  /// Affiche une notification de gains
  Future<void> showEarningsNotification({
    required String title,
    required double amount,
    String? details,
  }) async {
    await showNotification(
      id: 'earnings_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.earnings,
      title: title,
      body: '${amount.toStringAsFixed(0)} FCFA${details != null ? '\n$details' : ''}',
      data: {'amount': amount},
    );
  }

  /// Affiche une notification de chat
  Future<void> showChatNotification({
    required String senderId,
    required String senderName,
    required String message,
    String? deliveryId,
  }) async {
    await showNotification(
      id: 'chat_${senderId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.chat,
      title: senderName,
      body: message,
      data: {
        'sender_id': senderId,
        'sender_name': senderName,
        'delivery_id': deliveryId,
      },
      actions: const [
        NotificationAction(id: 'REPLY', label: 'Répondre'),
      ],
    );
  }

  /// Affiche une notification urgente
  Future<void> showUrgentNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await showNotification(
      id: 'urgent_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.urgent,
      title: title,
      body: message,
      data: data,
    );
  }

  /// Marque une notification comme lue
  void markAsRead(String notificationId) {
    state = state.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
  }

  /// Marque toutes comme lues
  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  /// Supprime une notification
  void removeNotification(String notificationId) {
    state = state.where((n) => n.id != notificationId).toList();
    _localNotifications.cancel(notificationId.hashCode);
  }

  /// Supprime toutes les notifications
  Future<void> clearAll() async {
    state = [];
    await _localNotifications.cancelAll();
  }

  /// Nombre de notifications non lues
  int get unreadCount => state.where((n) => !n.isRead).length;

  @override
  void dispose() {
    _actionController.close();
    super.dispose();
  }
}

/// Événement d'action sur notification
class NotificationActionEvent {
  final String notificationId;
  final String? actionId;
  final Map<String, dynamic>? data;

  NotificationActionEvent({
    required this.notificationId,
    this.actionId,
    this.data,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDERS RIVERPOD
// ══════════════════════════════════════════════════════════════════════════════

/// Provider principal pour les notifications enrichies
final richNotificationProvider = StateNotifierProvider<RichNotificationService, List<RichNotification>>((ref) {
  return RichNotificationService();
});

/// Provider pour les préférences de notification
final notificationPreferencesProvider = Provider<NotificationPreferences>((ref) {
  final service = ref.watch(richNotificationProvider.notifier);
  return service.preferences;
});

/// Provider pour le stream d'actions
final notificationActionStreamProvider = StreamProvider<NotificationActionEvent>((ref) {
  return ref.watch(richNotificationProvider.notifier).actionStream;
});

/// Provider pour le nombre de notifications non lues
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(richNotificationProvider);
  return notifications.where((n) => !n.isRead).length;
});

/// Provider des notifications non lues uniquement
final unreadNotificationsProvider = Provider<List<RichNotification>>((ref) {
  final notifications = ref.watch(richNotificationProvider);
  return notifications.where((n) => !n.isRead).toList();
});
