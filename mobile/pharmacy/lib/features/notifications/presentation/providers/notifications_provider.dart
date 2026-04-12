import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/realtime_event_bus.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

// ─────────── Unread Count (FCM-triggered) ───────────

/// Dedicated provider for unread notification count.
/// Listens to FCM events via RealtimeEventBus instead of polling.
/// Falls back to a 2-minute safety-net timer.
class UnreadCountNotifier extends StateNotifier<int> {
  final NotificationRepository _repository;
  Timer? _timer;
  StreamSubscription<RealtimeEvent>? _subscription;

  UnreadCountNotifier(this._repository) : super(0) {
    // Fetch immediately
    fetchCount();
    // Listen to all FCM events to refresh badge count
    _subscription = RealtimeEventBus().stream.listen((_) => fetchCount());
    // Safety-net timer: 2 minutes (down from 30 seconds)
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => fetchCount());
  }

  Future<void> fetchCount() async {
    final result = await _repository.getUnreadCount();
    result.fold(
      (failure) => debugPrint(
        '⚠️ [UnreadCount] Failed to fetch count: ${failure.message}',
      ),
      (count) {
        if (mounted) state = count;
      },
    );
  }

  /// Call to force an immediate refresh (e.g. after FCM push)
  void refresh() => fetchCount();

  @override
  void dispose() {
    _subscription?.cancel();
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

class NotificationsNotifier extends AutoDisposeNotifier<NotificationsState> {
  late final NotificationRepository _repository;

  @override
  NotificationsState build() {
    _repository = ref.watch(notificationRepositoryProvider);
    // Defer initial fetch to avoid "Bad state: uninitialized" error
    Future.microtask(loadNotifications);
    return NotificationsState();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getNotifications();
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (notifications) {
        state = state.copyWith(isLoading: false, notifications: notifications);
        // Sync the unread count from the full list
        ref.read(unreadCountNotifierProvider.notifier).refresh();
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
    ref.read(unreadCountNotifierProvider.notifier).refresh();

    final result = await _repository.markAsRead(id);
    result.fold(
      (failure) => loadNotifications(), // Revert on failure
      (_) => null,
    );
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    ref.read(unreadCountNotifierProvider.notifier).refresh();
    loadNotifications();
  }
}

final notificationsProvider =
    NotifierProvider.autoDispose<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
    );
