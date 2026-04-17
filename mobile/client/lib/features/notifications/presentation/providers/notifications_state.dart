import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';

enum NotificationsStatus { initial, loading, loaded, error }

// Sentinel object to distinguish "not provided" from "explicitly null"
const _unset = Object();

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  const NotificationsState.initial()
    : status = NotificationsStatus.initial,
      notifications = const [],
      unreadCount = 0,
      errorMessage = null;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationEntity>? notifications,
    int? unreadCount,
    Object? errorMessage = _unset,
    bool clearError = false,
  }) {
    final String? newError;
    if (clearError || (errorMessage != _unset && errorMessage == null)) {
      newError = null;
    } else if (errorMessage != _unset) {
      newError = errorMessage as String?;
    } else {
      newError = this.errorMessage;
    }
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: newError,
    );
  }

  @override
  List<Object?> get props => [status, notifications, unreadCount, errorMessage];
}
