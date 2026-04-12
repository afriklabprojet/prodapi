import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import 'notifications_state.dart';

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;
  final NotificationsRemoteDataSource remoteDataSource;

  NotificationsNotifier({
    required this.getNotificationsUseCase,
    required this.markNotificationAsReadUseCase,
    required this.markAllNotificationsReadUseCase,
    required this.remoteDataSource,
  }) : super(const NotificationsState.initial());

  Future<void> loadNotifications() async {
    state = state.copyWith(status: NotificationsStatus.loading);
    final result = await getNotificationsUseCase();
    result.fold(
      (failure) {
        state = state.copyWith(
          status: NotificationsStatus.error,
          errorMessage: _mapFailureMessage(failure),
        );
      },
      (notifications) {
        state = state.copyWith(
          status: NotificationsStatus.loaded,
          notifications: notifications,
          unreadCount: notifications.where((n) => !n.isRead).length,
        );
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final result = await markNotificationAsReadUseCase(notificationId);
    result.fold(
      (failure) {
        state = state.copyWith(
          status: NotificationsStatus.error,
          errorMessage: _mapFailureMessage(failure),
        );
      },
      (_) {
        final updated = state.notifications.map((n) {
          if (n.id == notificationId) {
            return NotificationEntity(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              data: n.data,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();
        state = state.copyWith(
          notifications: updated,
          unreadCount: updated.where((n) => !n.isRead).length,
        );
      },
    );
  }

  Future<void> markAllAsRead() async {
    final result = await markAllNotificationsReadUseCase();
    result.fold(
      (failure) {
        state = state.copyWith(
          status: NotificationsStatus.error,
          errorMessage: _mapFailureMessage(failure),
        );
      },
      (_) {
        final updated = state.notifications
            .map(
              (n) => NotificationEntity(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                data: n.data,
                isRead: true,
                createdAt: n.createdAt,
              ),
            )
            .toList();
        state = state.copyWith(notifications: updated, unreadCount: 0);
      },
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await remoteDataSource.deleteNotification(notificationId);
      final updated = state.notifications
          .where((n) => n.id != notificationId)
          .toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      );
    } catch (e) {
      AppLogger.error('Failed to delete notification', error: e);
      state = state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: 'Impossible de supprimer la notification',
      );
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await remoteDataSource.updateFcmToken(token);
    } catch (e) {
      AppLogger.warning('Failed to update FCM token: $e');
    }
  }

  Future<void> removeFcmToken() async {
    try {
      await remoteDataSource.removeFcmToken();
    } catch (e) {
      AppLogger.warning('Failed to remove FCM token: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapFailureMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Erreur de connexion. Vérifiez votre connexion internet.';
    }
    if (failure is ServerFailure) {
      final code = failure.statusCode;
      if (code == 401) {
        return 'Session expirée. Veuillez vous reconnecter.';
      }
      if (code == 403) {
        return 'Accès non autorisé.';
      }
    }
    return failure.message;
  }
}
