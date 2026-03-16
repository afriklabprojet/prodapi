import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

// ─────────── Unread Count (lightweight polling) ───────────

/// Dedicated provider for unread notification count.
/// Polls the server every 30 seconds for a lightweight count.
/// Can be manually refreshed via [refreshUnreadCount].
class UnreadCountNotifier extends StateNotifier<int> {
  final NotificationRepository _repository;
  Timer? _timer;

  UnreadCountNotifier(this._repository) : super(0) {
    // Fetch immediately then poll
    fetchCount();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchCount());
  }

  Future<void> fetchCount() async {
    final result = await _repository.getUnreadCount();
    result.fold(
      (_) {}, // ignore errors silently
      (count) {
        if (mounted) state = count;
      },
    );
  }

  /// Call to force an immediate refresh (e.g. after FCM push)
  void refresh() => fetchCount();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final unreadCountNotifierProvider =
    StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return UnreadCountNotifier(repo);
});

/// Public provider all badges should watch.
/// Returns the live unread notification count.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountNotifierProvider);
});

// ─────────── Full Notifications List ───────────

class NotificationsState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final String? error;

  NotificationsState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    String? error,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error ?? this.error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationsNotifier(this._repository, this._ref) : super(NotificationsState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getNotifications();
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (notifications) {
        state = state.copyWith(isLoading: false, notifications: notifications);
        // Sync the unread count from the full list
        _ref.read(unreadCountNotifierProvider.notifier).refresh();
      },
    );
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    final updatedList = state.notifications.map((n) {
      if (n.id == id) {
        return NotificationModel(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    
    state = state.copyWith(notifications: updatedList);
    // Immediately decrement unread count
    _ref.read(unreadCountNotifierProvider.notifier).refresh();

    final result = await _repository.markAsRead(id);
    result.fold(
      (failure) => loadNotifications(), // Revert on failure
      (_) => null,
    );
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    _ref.read(unreadCountNotifierProvider.notifier).refresh();
    loadNotifications();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationsNotifier(repository, ref);
});
