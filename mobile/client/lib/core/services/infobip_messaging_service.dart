import 'package:flutter/foundation.dart';
import 'package:infobip_mobilemessaging/infobip_mobilemessaging.dart';
import 'package:infobip_mobilemessaging/models/configurations/configuration.dart'
    as mmconf;
import 'package:infobip_mobilemessaging/models/data/message.dart';
import 'package:infobip_mobilemessaging/models/data/user_data.dart';
import 'package:infobip_mobilemessaging/models/library_event.dart';

import '../config/env_config.dart';

/// Service d'intégration Infobip Mobile Messaging pour l'app Client.
///
/// Gère l'initialisation du SDK Infobip, l'enregistrement push,
/// la personnalisation utilisateur et la réception des messages in-app.
///
/// Configuration requise:
/// - INFOBIP_APPLICATION_CODE dans .env / --dart-define
/// - Firebase configuré (FCM est utilisé comme transport Android)
/// - APNs configuré pour iOS
///
/// @see https://github.com/infobip/mobile-messaging-flutter-plugin
class InfobipMessagingService {
  static final InfobipMessagingService _instance =
      InfobipMessagingService._internal();
  factory InfobipMessagingService() => _instance;
  InfobipMessagingService._internal();

  bool _initialized = false;
  String? _pushRegistrationId;

  bool get isInitialized => _initialized;
  String? get pushRegistrationId => _pushRegistrationId;

  /// Application code from Infobip Portal
  String get _applicationCode => EnvConfig.infobipApplicationCode;

  bool get isConfigured => _applicationCode.isNotEmpty;

  /// Initialize Infobip Mobile Messaging SDK.
  /// Call after Firebase.initializeApp().
  Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) debugPrint('[Infobip] Already initialized');
      return;
    }

    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint(
            '[Infobip] Not configured (missing INFOBIP_APPLICATION_CODE)');
      }
      return;
    }

    try {
      final config = mmconf.Configuration(
        applicationCode: _applicationCode,
        defaultMessageStorage: true,
        logging: kDebugMode,
        androidSettings: mmconf.AndroidSettings(
          multipleNotifications: true,
        ),
        iosSettings: mmconf.IOSSettings(
          notificationTypes: ['alert', 'badge', 'sound'],
        ),
      );

      await InfobipMobilemessaging.init(config);

      InfobipMobilemessaging.on(
        LibraryEvent.tokenReceived,
        (dynamic token) {
          _pushRegistrationId = token?.toString();
          if (kDebugMode) debugPrint('[Infobip] Push registration ID received');
        },
      );

      InfobipMobilemessaging.on(
        LibraryEvent.messageReceived,
        (Message message) {
          _handleMessage(message);
        },
      );

      _initialized = true;
      if (kDebugMode) debugPrint('[Infobip] Mobile Messaging initialized ✅');
    } catch (e) {
      if (kDebugMode) debugPrint('[Infobip] Initialization failed: $e');
    }
  }

  /// Set user data for Infobip personalization (after login).
  Future<void> setUserData({
    required String externalUserId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    Map<String, dynamic>? customAttributes,
  }) async {
    if (!_initialized || !isConfigured) return;

    try {
      final user = UserData(
        externalUserId: externalUserId,
        firstName: firstName,
        lastName: lastName,
        emails: email != null ? [email] : null,
        phones: phone != null ? [phone] : null,
        customAttributes: customAttributes,
      );

      await InfobipMobilemessaging.saveUser(user);
      if (kDebugMode) {
        debugPrint('[Infobip] User data set for: $externalUserId');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Infobip] Failed to set user data: $e');
    }
  }

  /// Clear user data on logout.
  Future<void> clearUserData() async {
    if (!_initialized || !isConfigured) return;

    try {
      await InfobipMobilemessaging.depersonalize();
      _pushRegistrationId = null;
      if (kDebugMode) debugPrint('[Infobip] Depersonalized');
    } catch (e) {
      if (kDebugMode) debugPrint('[Infobip] Failed to clear data: $e');
    }
  }

  /// Mark a message as seen (for delivery reports).
  Future<void> markMessageSeen(String messageId) async {
    if (!_initialized || !isConfigured) return;

    try {
      await InfobipMobilemessaging.markMessagesSeen([messageId]);
      if (kDebugMode) debugPrint('[Infobip] Message seen: $messageId');
    } catch (e) {
      if (kDebugMode) debugPrint('[Infobip] Failed to mark seen: $e');
    }
  }

  /// Get all stored messages from the default message storage.
  Future<List<dynamic>> getStoredMessages() async {
    if (!_initialized || !isConfigured) return [];

    try {
      final storage = InfobipMobilemessaging.defaultMessageStorage();
      if (storage == null) return [];
      final messages = await storage.findAll();
      return messages ?? [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Infobip] Failed to get stored messages: $e');
      }
      return [];
    }
  }

  /// Handle incoming Infobip message.
  void _handleMessage(Message message) {
    try {
      if (kDebugMode) {
        debugPrint('[Infobip] Message received: ${message.body}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Infobip] Error handling message: $e');
    }
  }

  void dispose() {
    _initialized = false;
    _pushRegistrationId = null;
  }
}
