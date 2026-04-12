import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../models/notification_model.dart';

/// Datasource distante pour les notifications
class NotificationsRemoteDataSource {
  final ApiClient apiClient;

  NotificationsRemoteDataSource({required this.apiClient});

  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.get(ApiConstants.notifications);
    final rawData = response.data['data'];
    final raw = (rawData is Map && rawData.containsKey('notifications'))
        ? rawData['notifications']
        : rawData;

    final List<dynamic> data;
    if (raw is List) {
      data = raw;
    } else if (raw is Map) {
      data = raw.values.toList();
    } else {
      data = [];
    }

    return data
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await apiClient.post(ApiConstants.markNotificationRead(notificationId));
  }

  Future<void> markAllAsRead() async {
    await apiClient.post(ApiConstants.markAllNotificationsRead);
  }

  Future<void> deleteNotification(String notificationId) async {
    await apiClient.delete(ApiConstants.deleteNotification(notificationId));
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await apiClient.post(
        ApiConstants.updateFcmToken,
        data: {'fcm_token': token},
      );
    } catch (e) {
      AppLogger.warning(
        'NotificationsRemoteDataSource.updateFcmToken failed: $e',
      );
    }
  }

  Future<void> removeFcmToken() async {
    try {
      await apiClient.delete(ApiConstants.updateFcmToken);
    } catch (e) {
      AppLogger.warning(
        'NotificationsRemoteDataSource.removeFcmToken failed: $e',
      );
    }
  }
}
