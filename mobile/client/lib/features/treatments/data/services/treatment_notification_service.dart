import 'dart:async';
import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/treatment_entity.dart';

/// Service pour la gestion des notifications de renouvellement des traitements
class TreatmentNotificationService {
  static final TreatmentNotificationService _instance = TreatmentNotificationService._internal();
  factory TreatmentNotificationService() => _instance;
  TreatmentNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialise le service de notifications
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    AppLogger.info('TreatmentNotificationService initialized');
  }

  void _onNotificationTap(NotificationResponse response) {
    AppLogger.info('Treatment notification tapped: ${response.payload}');
    // Deep link vers la page des traitements sera géré par le router
  }

  /// Planifie une notification de rappel pour un traitement
  Future<void> scheduleRenewalReminder(TreatmentEntity treatment) async {
    if (!treatment.reminderEnabled || treatment.nextRenewalDate == null) {
      return;
    }

    // Calculer la date de notification (X jours avant le renouvellement)
    final reminderDate = treatment.nextRenewalDate!
        .subtract(Duration(days: treatment.reminderDaysBefore));

    // Ne pas planifier si la date est passée
    if (reminderDate.isBefore(DateTime.now())) {
      AppLogger.warning('Reminder date is in the past for ${treatment.productName}');
      return;
    }

    final notificationId = _generateNotificationId(treatment.id);

    // Annuler l'ancienne notification si elle existe
    await _notifications.cancel(notificationId);

    // Planifier la nouvelle notification
    await _notifications.zonedSchedule(
      notificationId,
      '💊 Renouvellement de traitement',
      'Il est temps de renouveler votre ${treatment.productName}',
      tz.TZDateTime.from(reminderDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'treatment_reminders',
          'Rappels de traitement',
          channelDescription: 'Notifications de renouvellement de vos traitements',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2E7D32), // AppColors.primary
          actions: [
            const AndroidNotificationAction(
              'order_now',
              'Commander',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'remind_later',
              'Plus tard',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'treatment:${treatment.id}',
    );

    AppLogger.info(
      'Scheduled renewal reminder for ${treatment.productName} on $reminderDate',
    );
  }

  /// Annule la notification de rappel pour un traitement
  Future<void> cancelRenewalReminder(String treatmentId) async {
    final notificationId = _generateNotificationId(treatmentId);
    await _notifications.cancel(notificationId);
    AppLogger.info('Cancelled renewal reminder for treatment $treatmentId');
  }

  /// Met à jour les notifications pour plusieurs traitements
  Future<void> syncAllReminders(List<TreatmentEntity> treatments) async {
    for (final treatment in treatments) {
      if (treatment.reminderEnabled) {
        await scheduleRenewalReminder(treatment);
      } else {
        await cancelRenewalReminder(treatment.id);
      }
    }
    AppLogger.info('Synced ${treatments.length} treatment reminders');
  }

  /// Génère un ID de notification unique à partir de l'ID du traitement
  int _generateNotificationId(String treatmentId) {
    return treatmentId.hashCode.abs() % 2147483647; // Max int32
  }

  /// Affiche une notification immédiate (pour les tests)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'treatment_reminders',
          'Rappels de traitement',
          channelDescription: 'Notifications de renouvellement de vos traitements',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
