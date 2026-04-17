import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import 'notifications_notifier.dart';
import 'notifications_state.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      final remoteDataSource = NotificationsRemoteDataSource(
        apiClient: apiClient,
      );
      final repository = NotificationsRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );
      return NotificationsNotifier(
        getNotificationsUseCase: GetNotificationsUseCase(repository),
        markNotificationAsReadUseCase: MarkNotificationAsReadUseCase(
          repository,
        ),
        markAllNotificationsReadUseCase: MarkAllNotificationsReadUseCase(
          repository,
        ),
        remoteDataSource: remoteDataSource,
      );
    });

/// Provider qui expose le nombre de notifications non lues
final unreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationsProvider);
  return state.unreadCount;
});
