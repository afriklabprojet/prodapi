import 'package:flutter/foundation.dart';
import 'package:infobip_mobilemessaging/infobip_mobilemessaging.dart';
import 'package:infobip_mobilemessaging/models/configurations/configuration.dart'
    as mmconf;
import 'package:infobip_mobilemessaging/models/data/message.dart';
import 'package:infobip_mobilemessaging/models/data/user_data.dart';
import 'package:infobip_mobilemessaging/models/library_event.dart';

/// Service d'intégration Infobip Mobile Messaging pour l'app Coursier.
///
/// Gère l'initialisation du SDK Infobip, l'enregistrement push,
/// la personnalisation coursier et la réception des messages en temps réel.
///
/// Configuration requise:
/// - INFOBIP_APPLICATION_CODE via --dart-define ou .env
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
  String get _applicationCode =>
      const String.fromEnvironment('INFOBIP_APPLICATION_CODE');

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
        debugPrint('[Infobip] Not configured (missing INFOBIP_APPLICATION_CODE)');
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

  /// Set courier data for Infobip personalization (after login).
  Future<void> setCourierData({
    required String externalUserId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? vehicleType,
    String? zone,
  }) async {
    if (!_initialized || !isConfigured) return;

    try {
      final user = UserData(
        externalUserId: externalUserId,
        firstName: firstName,
        lastName: lastName,
        emails: email != null ? [email] : null,
        phones: phone != null ? [phone] : null,
        customAttributes: {
          'app_type': 'courier',
          if (vehicleType != null) 'vehicle_type': vehicleType,
          if (zone != null) 'delivery_zone': zone,
        },
      );

      await InfobipMobilemessaging.saveUser(user);
      if (kDebugMode) {
        debugPrint('[Infobip] Courier data set for: $externalUserId');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Infobip] Failed to set courier data: $e');
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
