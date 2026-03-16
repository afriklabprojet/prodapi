import 'dart:async';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

/// Types de notifications
enum NotificationType {
  newDelivery,
  deliveryUpdate,
  earnings,
  promotion,
  system,
  urgent,
}

/// Configuration des sons de notification
class NotificationSound {
  final String id;
  final String name;
  final String assetPath;
  final bool isCustom;

  const NotificationSound({
    required this.id,
    required this.name,
    required this.assetPath,
    this.isCustom = false,
  });

  static const defaultSound = NotificationSound(
    id: 'default',
    name: 'Par défaut',
    assetPath: 'sounds/notification_default.mp3',
  );

  static const urgentSound = NotificationSound(
    id: 'urgent',
    name: 'Urgent',
    assetPath: 'sounds/notification_urgent.mp3',
  );

  static const deliverySound = NotificationSound(
    id: 'delivery',
    name: 'Nouvelle livraison',
    assetPath: 'sounds/notification_delivery.mp3',
  );

  static const earningsSound = NotificationSound(
    id: 'earnings',
    name: 'Gains',
    assetPath: 'sounds/notification_earnings.mp3',
  );

  static const silentSound = NotificationSound(
    id: 'silent',
    name: 'Silencieux',
    assetPath: '',
  );

  static List<NotificationSound> get all => [
    defaultSound,
    urgentSound,
    deliverySound,
    earningsSound,
    silentSound,
  ];
}

/// Action rapide sur notification
class NotificationAction {
  final String id;
  final String label;
  final String? icon;
  final bool destructive;
  final bool requiresUnlock;

  const NotificationAction({
    required this.id,
    required this.label,
    this.icon,
    this.destructive = false,
    this.requiresUnlock = false,
  });

  // Actions prédéfinies
  static const accept = NotificationAction(
    id: 'accept',
    label: 'Accepter',
    icon: 'check',
  );

  static const decline = NotificationAction(
    id: 'decline',
    label: 'Refuser',
    icon: 'close',
    destructive: true,
  );

  static const viewDetails = NotificationAction(
    id: 'view_details',
    label: 'Voir détails',
    icon: 'visibility',
  );

  static const navigate = NotificationAction(
    id: 'navigate',
    label: 'Naviguer',
    icon: 'navigation',
  );

  static const call = NotificationAction(
    id: 'call',
    label: 'Appeler',
    icon: 'phone',
    requiresUnlock: true,
  );

  static const markDelivered = NotificationAction(
    id: 'mark_delivered',
    label: 'Marquer livrée',
    icon: 'done_all',
    requiresUnlock: true,
  );
}

/// Notification groupée
class NotificationGroup {
  final String id;
  final String name;
  final String description;
  final List<NotificationPayload> notifications;
  final DateTime lastUpdated;

  NotificationGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.notifications,
    required this.lastUpdated,
  });

  int get count => notifications.length;

  String get summary {
    if (count == 1) return notifications.first.title;
    return '$count notifications';
  }
}

/// Payload de notification
class NotificationPayload {
  final int id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final List<NotificationAction> actions;
  final DateTime createdAt;
  final String? groupId;
  final String? imageUrl;
  final bool silent;

  NotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.actions = const [],
    DateTime? createdAt,
    this.groupId,
    this.imageUrl,
    this.silent = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.name,
    'data': data,
    'groupId': groupId,
    'imageUrl': imageUrl,
    'silent': silent,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Préférences de notification
class NotificationPreferences {
  final bool enabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool groupNotifications;
  final bool showPreview;
  final Map<NotificationType, bool> typeEnabled;
  final Map<NotificationType, NotificationSound> typeSounds;
  final bool quietHoursEnabled;
  final int quietHoursStart; // 0-23
  final int quietHoursEnd; // 0-23
  final bool allowUrgentDuringQuiet;

  const NotificationPreferences({
    this.enabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.groupNotifications = true,
    this.showPreview = true,
    this.typeEnabled = const {
      NotificationType.newDelivery: true,
      NotificationType.deliveryUpdate: true,
      NotificationType.earnings: true,
      NotificationType.promotion: true,
      NotificationType.system: true,
      NotificationType.urgent: true,
    },
    this.typeSounds = const {
      NotificationType.newDelivery: NotificationSound.deliverySound,
      NotificationType.deliveryUpdate: NotificationSound.defaultSound,
      NotificationType.earnings: NotificationSound.earningsSound,
      NotificationType.promotion: NotificationSound.defaultSound,
      NotificationType.system: NotificationSound.defaultSound,
      NotificationType.urgent: NotificationSound.urgentSound,
    },
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
    this.allowUrgentDuringQuiet = true,
  });

  NotificationPreferences copyWith({
    bool? enabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? groupNotifications,
    bool? showPreview,
    Map<NotificationType, bool>? typeEnabled,
    Map<NotificationType, NotificationSound>? typeSounds,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? allowUrgentDuringQuiet,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      showPreview: showPreview ?? this.showPreview,
      typeEnabled: typeEnabled ?? this.typeEnabled,
      typeSounds: typeSounds ?? this.typeSounds,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      allowUrgentDuringQuiet: allowUrgentDuringQuiet ?? this.allowUrgentDuringQuiet,
    );
  }

  bool isInQuietHours() {
    if (!quietHoursEnabled) return false;
    final now = DateTime.now();
    final hour = now.hour;
    
    if (quietHoursStart < quietHoursEnd) {
      return hour >= quietHoursStart && hour < quietHoursEnd;
    } else {
      return hour >= quietHoursStart || hour < quietHoursEnd;
    }
  }
}

/// Service de notifications avancées
class AdvancedNotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final Map<String, NotificationGroup> _groups = {};
  final List<NotificationPayload> _history = [];
  
  StreamController<NotificationPayload>? _notificationController;
  StreamController<String>? _actionController;
  
  NotificationPreferences _preferences = const NotificationPreferences();
  
  int _nextId = 1;
  
  /// Initialiser le service
  Future<void> initialize() async {
    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuration iOS
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: _buildIOSCategories(),
    );
    
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationHandler,
    );
    
    // Créer les canaux Android
    await _createAndroidChannels();
    
    // Charger les préférences
    await _loadPreferences();
    
    // Initialiser les streams
    _notificationController = StreamController<NotificationPayload>.broadcast();
    _actionController = StreamController<String>.broadcast();
    
    if (kDebugMode) debugPrint('🔔 Advanced Notification Service initialized');
  }
  
  /// Créer les canaux Android
  Future<void> _createAndroidChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;
    
    // Canal nouvelles livraisons (haute priorité)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'new_delivery',
        'Nouvelles livraisons',
        description: 'Notifications pour les nouvelles commandes',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF009688),
      ),
    );
    
    // Canal mises à jour
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'delivery_updates',
        'Mises à jour',
        description: 'Mises à jour sur les livraisons en cours',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    
    // Canal gains
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'earnings',
        'Gains',
        description: 'Notifications de gains et paiements',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );
    
    // Canal promotions
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'promotions',
        'Promotions',
        description: 'Offres et promotions',
        importance: Importance.low,
      ),
    );
    
    // Canal système
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'system',
        'Système',
        description: 'Notifications système',
        importance: Importance.low,
      ),
    );
    
    // Canal urgent
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'urgent',
        'Urgent',
        description: 'Notifications urgentes',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF0000),
      ),
    );
  }
  
  /// Construire les catégories iOS
  List<DarwinNotificationCategory> _buildIOSCategories() {
    return [
      // Catégorie nouvelle livraison
      DarwinNotificationCategory(
        'new_delivery',
        actions: [
          DarwinNotificationAction.plain(
            'accept',
            'Accepter',
            options: {DarwinNotificationActionOption.foreground},
          ),
          DarwinNotificationAction.plain(
            'decline',
            'Refuser',
            options: {DarwinNotificationActionOption.destructive},
          ),
        ],
        options: {
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      ),
      // Catégorie livraison en cours
      DarwinNotificationCategory(
        'delivery_in_progress',
        actions: [
          DarwinNotificationAction.plain(
            'navigate',
            'Naviguer',
            options: {DarwinNotificationActionOption.foreground},
          ),
          DarwinNotificationAction.plain(
            'call',
            'Appeler',
            options: {DarwinNotificationActionOption.foreground},
          ),
        ],
      ),
      // Catégorie livraison arrivée
      DarwinNotificationCategory(
        'delivery_arrived',
        actions: [
          DarwinNotificationAction.plain(
            'mark_delivered',
            'Marquer livrée',
            options: {DarwinNotificationActionOption.foreground},
          ),
          DarwinNotificationAction.plain(
            'call',
            'Appeler client',
            options: {DarwinNotificationActionOption.foreground},
          ),
        ],
      ),
    ];
  }
  
  /// Afficher une notification
  Future<void> show(NotificationPayload payload) async {
    if (!_preferences.enabled) return;
    if (!(_preferences.typeEnabled[payload.type] ?? true)) return;
    
    // Vérifier les heures calmes
    if (_preferences.isInQuietHours()) {
      if (payload.type != NotificationType.urgent || !_preferences.allowUrgentDuringQuiet) {
        // Ajouter à l'historique silencieusement
        _addToHistory(payload.copyWith(silent: true));
        return;
      }
    }
    
    final id = _nextId++;
    final notificationPayload = payload.copyWith(id: id);
    
    // Ajouter au groupe si nécessaire
    if (payload.groupId != null && _preferences.groupNotifications) {
      _addToGroup(notificationPayload);
    }
    
    // Construire les détails de notification
    final details = await _buildNotificationDetails(notificationPayload);
    
    // Afficher
    await _notifications.show(
      id,
      _preferences.showPreview ? payload.title : 'DR-PHARMA',
      _preferences.showPreview ? payload.body : 'Nouvelle notification',
      details,
      payload: notificationPayload.toJson().toString(),
    );
    
    // Jouer le son personnalisé si nécessaire
    if (_preferences.soundEnabled && !payload.silent) {
      await _playSound(payload.type);
    }
    
    // Ajouter à l'historique
    _addToHistory(notificationPayload);
    
    // Émettre sur le stream
    _notificationController?.add(notificationPayload);
  }
  
  /// Construire les détails de notification
  Future<NotificationDetails> _buildNotificationDetails(NotificationPayload payload) async {
    final channelId = _getChannelId(payload.type);
    
    // Configuration Android
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(payload.type),
      channelDescription: _getChannelDescription(payload.type),
      importance: _getImportance(payload.type),
      priority: _getPriority(payload.type),
      playSound: _preferences.soundEnabled && !payload.silent,
      enableVibration: _preferences.vibrationEnabled && !payload.silent,
      groupKey: payload.groupId,
      setAsGroupSummary: false,
      styleInformation: payload.imageUrl != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(payload.imageUrl!),
              contentTitle: payload.title,
              summaryText: payload.body,
            )
          : BigTextStyleInformation(payload.body),
      actions: payload.actions
          .map((a) => AndroidNotificationAction(
                a.id,
                a.label,
                showsUserInterface: a.requiresUnlock,
                cancelNotification: a.destructive,
              ))
          .toList(),
    );
    
    // Configuration iOS
    final iosDetails = DarwinNotificationDetails(
      presentAlert: !payload.silent,
      presentBadge: true,
      presentSound: _preferences.soundEnabled && !payload.silent,
      threadIdentifier: payload.groupId,
      categoryIdentifier: _getIOSCategory(payload.type),
      interruptionLevel: _getInterruptionLevel(payload.type),
    );
    
    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }
  
  /// Jouer un son personnalisé
  Future<void> _playSound(NotificationType type) async {
    final sound = _preferences.typeSounds[type] ?? NotificationSound.defaultSound;
    if (sound.id == 'silent' || sound.assetPath.isEmpty) return;
    
    try {
      await _audioPlayer.play(AssetSource(sound.assetPath));
    } catch (e) {
      if (kDebugMode) debugPrint('Error playing notification sound: $e');
    }
  }
  
  /// Ajouter à un groupe
  void _addToGroup(NotificationPayload payload) {
    final groupId = payload.groupId!;
    
    if (_groups.containsKey(groupId)) {
      final group = _groups[groupId]!;
      _groups[groupId] = NotificationGroup(
        id: groupId,
        name: group.name,
        description: group.description,
        notifications: [...group.notifications, payload],
        lastUpdated: DateTime.now(),
      );
    } else {
      _groups[groupId] = NotificationGroup(
        id: groupId,
        name: _getGroupName(payload.type),
        description: '',
        notifications: [payload],
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Ajouter à l'historique
  void _addToHistory(NotificationPayload payload) {
    _history.insert(0, payload);
    // Limiter l'historique à 100 éléments
    if (_history.length > 100) {
      _history.removeLast();
    }
  }
  
  /// Handler de réponse notification
  void _onNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId != null && actionId.isNotEmpty) {
      _actionController?.add(actionId);
      if (kDebugMode) debugPrint('🔔 Notification action: $actionId');
    }
  }
  
  /// Stream des notifications
  Stream<NotificationPayload> get notificationStream =>
      _notificationController?.stream ?? const Stream.empty();
  
  /// Stream des actions
  Stream<String> get actionStream =>
      _actionController?.stream ?? const Stream.empty();
  
  /// Historique des notifications
  List<NotificationPayload> get history => List.unmodifiable(_history);
  
  /// Groupes de notifications
  List<NotificationGroup> get groups => _groups.values.toList();
  
  /// Préférences actuelles
  NotificationPreferences get preferences => _preferences;
  
  /// Mettre à jour les préférences
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    _preferences = prefs;
    await _savePreferences();
  }
  
  /// Annuler une notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
  
  /// Annuler toutes les notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    _groups.clear();
  }
  
  /// Effacer l'historique
  void clearHistory() {
    _history.clear();
  }
  
  // Helpers
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.newDelivery:
        return 'new_delivery';
      case NotificationType.deliveryUpdate:
        return 'delivery_updates';
      case NotificationType.earnings:
        return 'earnings';
      case NotificationType.promotion:
        return 'promotions';
      case NotificationType.system:
        return 'system';
      case NotificationType.urgent:
        return 'urgent';
    }
  }
  
  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.newDelivery:
        return 'Nouvelles livraisons';
      case NotificationType.deliveryUpdate:
        return 'Mises à jour';
      case NotificationType.earnings:
        return 'Gains';
      case NotificationType.promotion:
        return 'Promotions';
      case NotificationType.system:
        return 'Système';
      case NotificationType.urgent:
        return 'Urgent';
    }
  }
  
  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.newDelivery:
        return 'Notifications pour les nouvelles commandes';
      case NotificationType.deliveryUpdate:
        return 'Mises à jour sur les livraisons en cours';
      case NotificationType.earnings:
        return 'Notifications de gains et paiements';
      case NotificationType.promotion:
        return 'Offres et promotions';
      case NotificationType.system:
        return 'Notifications système';
      case NotificationType.urgent:
        return 'Notifications urgentes';
    }
  }
  
  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.newDelivery:
      case NotificationType.urgent:
        return Importance.max;
      case NotificationType.deliveryUpdate:
        return Importance.high;
      case NotificationType.earnings:
        return Importance.defaultImportance;
      case NotificationType.promotion:
      case NotificationType.system:
        return Importance.low;
    }
  }
  
  Priority _getPriority(NotificationType type) {
    switch (type) {
      case NotificationType.newDelivery:
      case NotificationType.urgent:
        return Priority.max;
      case NotificationType.deliveryUpdate:
        return Priority.high;
      case NotificationType.earnings:
        return Priority.defaultPriority;
      case NotificationType.promotion:
      case NotificationType.system:
        return Priority.low;
    }
  }
  
  String _getIOSCategory(NotificationType type) {
    switch (type) {
      case NotificationType.newDelivery:
        return 'new_delivery';
      case NotificationType.deliveryUpdate:
        return 'delivery_in_progress';
      default:
        return '';
    }
  }
  
  InterruptionLevel _getInterruptionLevel(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return InterruptionLevel.critical;
      case NotificationType.newDelivery:
        return InterruptionLevel.timeSensitive;
      case NotificationType.deliveryUpdate:
        return InterruptionLevel.active;
      default:
        return InterruptionLevel.passive;
    }
  }
  
  String _getGroupName(NotificationType type) {
    switch (type) {
      case NotificationType.newDelivery:
        return 'Nouvelles livraisons';
      case NotificationType.deliveryUpdate:
        return 'Mises à jour';
      case NotificationType.earnings:
        return 'Gains';
      case NotificationType.promotion:
        return 'Promotions';
      case NotificationType.system:
        return 'Système';
      case NotificationType.urgent:
        return 'Urgent';
    }
  }
  
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preferences = NotificationPreferences(
        enabled: prefs.getBool('notif_enabled') ?? true,
        soundEnabled: prefs.getBool('notif_sound') ?? true,
        vibrationEnabled: prefs.getBool('notif_vibration') ?? true,
        groupNotifications: prefs.getBool('notif_group') ?? true,
        showPreview: prefs.getBool('notif_preview') ?? true,
        quietHoursEnabled: prefs.getBool('notif_quiet_enabled') ?? false,
        quietHoursStart: prefs.getInt('notif_quiet_start') ?? 22,
        quietHoursEnd: prefs.getInt('notif_quiet_end') ?? 7,
        allowUrgentDuringQuiet: prefs.getBool('notif_quiet_allow_urgent') ?? true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading notification preferences: $e');
    }
  }
  
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_enabled', _preferences.enabled);
      await prefs.setBool('notif_sound', _preferences.soundEnabled);
      await prefs.setBool('notif_vibration', _preferences.vibrationEnabled);
      await prefs.setBool('notif_group', _preferences.groupNotifications);
      await prefs.setBool('notif_preview', _preferences.showPreview);
      await prefs.setBool('notif_quiet_enabled', _preferences.quietHoursEnabled);
      await prefs.setInt('notif_quiet_start', _preferences.quietHoursStart);
      await prefs.setInt('notif_quiet_end', _preferences.quietHoursEnd);
      await prefs.setBool('notif_quiet_allow_urgent', _preferences.allowUrgentDuringQuiet);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving notification preferences: $e');
    }
  }
  
  /// Disposer
  void dispose() {
    _notificationController?.close();
    _actionController?.close();
    _audioPlayer.dispose();
  }
}

/// Extension pour copier le payload
extension NotificationPayloadCopy on NotificationPayload {
  NotificationPayload copyWith({
    int? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    List<NotificationAction>? actions,
    DateTime? createdAt,
    String? groupId,
    String? imageUrl,
    bool? silent,
  }) {
    return NotificationPayload(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
      imageUrl: imageUrl ?? this.imageUrl,
      silent: silent ?? this.silent,
    );
  }
}

// Handler statique pour les notifications en background
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse response) {
  if (kDebugMode) {
    debugPrint('🔔 Background notification action: ${response.actionId}');
  }
}

/// Provider
final advancedNotificationServiceProvider = Provider<AdvancedNotificationService>((ref) {
  final service = AdvancedNotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider pour les préférences
final notificationPreferencesProvider = StateProvider<NotificationPreferences>((ref) {
  return const NotificationPreferences();
});

/// Provider pour l'historique
final notificationHistoryProvider = Provider<List<NotificationPayload>>((ref) {
  final service = ref.watch(advancedNotificationServiceProvider);
  return service.history;
});
