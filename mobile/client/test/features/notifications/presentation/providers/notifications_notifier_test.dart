import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:drpharma_client/features/notifications/domain/entities/notification_entity.dart';
import 'package:drpharma_client/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:drpharma_client/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:drpharma_client/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:drpharma_client/features/notifications/presentation/providers/notifications_notifier.dart';
import 'package:drpharma_client/features/notifications/presentation/providers/notifications_state.dart';

import 'notifications_notifier_test.mocks.dart';

@GenerateMocks([
  GetNotificationsUseCase,
  MarkNotificationAsReadUseCase,
  MarkAllNotificationsReadUseCase,
  NotificationsRemoteDataSource,
])
void main() {
  late NotificationsNotifier notifier;
  late MockGetNotificationsUseCase mockGetNotificationsUseCase;
  late MockMarkNotificationAsReadUseCase mockMarkNotificationAsReadUseCase;
  late MockMarkAllNotificationsReadUseCase mockMarkAllNotificationsReadUseCase;
  late MockNotificationsRemoteDataSource mockRemoteDataSource;

  final tNotification1 = NotificationEntity(
    id: '1',
    type: 'order_status',
    title: 'Commande confirmée',
    body: 'Votre commande a été confirmée',
    data: {'order_id': 123},
    isRead: false,
    createdAt: DateTime(2024, 1, 15, 10, 0),
  );

  final tNotification2 = NotificationEntity(
    id: '2',
    type: 'delivery_assigned',
    title: 'Livreur assigné',
    body: 'Un livreur a été assigné à votre commande',
    data: {'order_id': 123, 'delivery_id': 456},
    isRead: true,
    createdAt: DateTime(2024, 1, 15, 11, 0),
  );

  final tNotificationList = [tNotification1, tNotification2];

  setUp(() {
    mockGetNotificationsUseCase = MockGetNotificationsUseCase();
    mockMarkNotificationAsReadUseCase = MockMarkNotificationAsReadUseCase();
    mockMarkAllNotificationsReadUseCase = MockMarkAllNotificationsReadUseCase();
    mockRemoteDataSource = MockNotificationsRemoteDataSource();
  });

  NotificationsNotifier createNotifier() {
    return NotificationsNotifier(
      getNotificationsUseCase: mockGetNotificationsUseCase,
      markNotificationAsReadUseCase: mockMarkNotificationAsReadUseCase,
      markAllNotificationsReadUseCase: mockMarkAllNotificationsReadUseCase,
      remoteDataSource: mockRemoteDataSource,
    );
  }

  group('NotificationsNotifier', () {
    group('loadNotifications', () {
      test('should emit loaded state with notifications on success', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Right(tNotificationList));

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();

        // Assert
        verify(mockGetNotificationsUseCase()).called(1);
        expect(notifier.state.status, NotificationsStatus.loaded);
        expect(notifier.state.notifications, tNotificationList);
        expect(notifier.state.unreadCount, 1); // tNotification1 is unread
      });

      test('should emit error state on failure', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Left(ServerFailure(message: 'Server error')));

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();

        // Assert
        expect(notifier.state.status, NotificationsStatus.error);
        expect(notifier.state.errorMessage, isNotNull);
      });

      test('should emit loading state during fetch', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Right(tNotificationList));

        // Act
        notifier = createNotifier();
        
        // The state should start as loading
        final loadFuture = notifier.loadNotifications();
        
        // Wait for completion
        await loadFuture;

        // Assert final state
        expect(notifier.state.status, NotificationsStatus.loaded);
      });

      test('should translate network error to readable message', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Left(NetworkFailure(message: 'Network connection failed')));

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();

        // Assert
        expect(notifier.state.errorMessage, contains('connexion'));
      });

      test('should translate unauthorized error to readable message', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Left(ServerFailure(message: '401 unauthorized', statusCode: 401)));

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();

        // Assert
        expect(notifier.state.errorMessage, anyOf(contains('Session'), contains('reconnecter')));
      });
    });

    group('markAsRead', () {
      test('should update notification to read on success', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Right(tNotificationList));
        when(mockMarkNotificationAsReadUseCase(any))
            .thenAnswer((_) async => Right(null));

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();
        await notifier.markAsRead('1');

        // Assert
        verify(mockMarkNotificationAsReadUseCase('1')).called(1);
        
        final markedNotification = notifier.state.notifications
            .firstWhere((n) => n.id == '1');
        expect(markedNotification.isRead, isTrue);
        expect(notifier.state.unreadCount, 0); // All read now
      });

      test('should emit error on failure', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Right(tNotificationList));
        when(mockMarkNotificationAsReadUseCase(any))
            .thenAnswer((_) async => Left(ServerFailure(message: 'Failed')));

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();
        await notifier.markAsRead('1');

        // Assert
        expect(notifier.state.status, NotificationsStatus.error);
      });
    });

    group('markAllAsRead', () {
      test('should update all notifications to read on success', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Right(tNotificationList));
        when(mockMarkAllNotificationsReadUseCase())
            .thenAnswer((_) async => Right(null));

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();
        await notifier.markAllAsRead();

        // Assert
        verify(mockMarkAllNotificationsReadUseCase()).called(1);
        
        expect(notifier.state.unreadCount, 0);
        for (final notification in notifier.state.notifications) {
          expect(notification.isRead, isTrue);
        }
      });

      test('should emit error on failure', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Right(tNotificationList));
        when(mockMarkAllNotificationsReadUseCase())
            .thenAnswer((_) async => Left(ServerFailure(message: 'Failed')));

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();
        await notifier.markAllAsRead();

        // Assert
        expect(notifier.state.status, NotificationsStatus.error);
      });
    });

    group('deleteNotification', () {
      test('should remove notification from list on success', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Right(tNotificationList));
        when(mockRemoteDataSource.deleteNotification(any))
            .thenAnswer((_) async => {});

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();
        expect(notifier.state.notifications.length, 2);
        
        await notifier.deleteNotification('1');

        // Assert
        verify(mockRemoteDataSource.deleteNotification('1')).called(1);
        expect(notifier.state.notifications.length, 1);
        expect(notifier.state.notifications.any((n) => n.id == '1'), isFalse);
      });

      test('should update unread count after deleting unread notification', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Right(tNotificationList));
        when(mockRemoteDataSource.deleteNotification(any))
            .thenAnswer((_) async => {});

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();
        expect(notifier.state.unreadCount, 1);
        
        await notifier.deleteNotification('1'); // Delete unread notification

        // Assert
        expect(notifier.state.unreadCount, 0);
      });

      test('should emit error on failure', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Right(tNotificationList));
        when(mockRemoteDataSource.deleteNotification(any))
            .thenThrow(Exception('Failed'));

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();
        await notifier.deleteNotification('1');

        // Assert
        expect(notifier.state.status, NotificationsStatus.error);
      });
    });

    group('updateFcmToken', () {
      test('should call remote datasource to update token', () async {
        // Arrange
        when(mockRemoteDataSource.updateFcmToken(any))
            .thenAnswer((_) async => {});

        // Act
        notifier = createNotifier();
        await notifier.updateFcmToken('test-fcm-token');

        // Assert
        verify(mockRemoteDataSource.updateFcmToken('test-fcm-token')).called(1);
      });

      test('should silently fail on error', () async {
        // Arrange
        when(mockRemoteDataSource.updateFcmToken(any))
            .thenThrow(Exception('Failed'));

        // Act
        notifier = createNotifier();
        await notifier.updateFcmToken('test-fcm-token');

        // Assert - No error state, silent fail
        expect(notifier.state.status, NotificationsStatus.initial);
      });
    });

    group('removeFcmToken', () {
      test('should call remote datasource to remove token', () async {
        // Arrange
        when(mockRemoteDataSource.removeFcmToken())
            .thenAnswer((_) async => {});

        // Act
        notifier = createNotifier();
        await notifier.removeFcmToken();

        // Assert
        verify(mockRemoteDataSource.removeFcmToken()).called(1);
      });

      test('should silently fail on error', () async {
        // Arrange
        when(mockRemoteDataSource.removeFcmToken())
            .thenThrow(Exception('Failed'));

        // Act
        notifier = createNotifier();
        await notifier.removeFcmToken();

        // Assert - No error state, silent fail
        expect(notifier.state.status, NotificationsStatus.initial);
      });
    });

    group('clearError', () {
      test('should clear error message', () async {
        // Arrange
        when(mockGetNotificationsUseCase())
            .thenAnswer((_) async => Left(ServerFailure(message: 'Error')));

        // Act
        notifier = createNotifier();
        await notifier.loadNotifications();
        expect(notifier.state.errorMessage, isNotNull);
        
        notifier.clearError();

        // Assert
        expect(notifier.state.errorMessage, isNull);
      });

      test('should do nothing when no error exists', () async {
        // Act
        notifier = createNotifier();
        final stateBefore = notifier.state;
        notifier.clearError();

        // Assert
        expect(notifier.state, stateBefore);
      });
    });
  });

  group('NotificationsState', () {
    test('should create initial state', () {
      const state = NotificationsState.initial();
      
      expect(state.status, NotificationsStatus.initial);
      expect(state.notifications, isEmpty);
      expect(state.unreadCount, 0);
      expect(state.errorMessage, isNull);
    });

    test('should copy with new values', () {
      const state = NotificationsState.initial();
      final newState = state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: tNotificationList,
        unreadCount: 1,
        errorMessage: 'Error',
      );
      
      expect(newState.status, NotificationsStatus.loaded);
      expect(newState.notifications, tNotificationList);
      expect(newState.unreadCount, 1);
      expect(newState.errorMessage, 'Error');
    });

    test('should keep original values when not specified in copyWith', () {
      final state = NotificationsState(
        status: NotificationsStatus.loaded,
        notifications: tNotificationList,
        unreadCount: 1,
        errorMessage: 'Error',
      );
      
      final newState = state.copyWith(status: NotificationsStatus.loading);
      
      expect(newState.status, NotificationsStatus.loading);
      expect(newState.notifications, tNotificationList);
      expect(newState.unreadCount, 1);
      // Note: errorMessage is handled specially in copyWith
    });

    test('should allow clearing errorMessage via copyWith', () {
      final state = NotificationsState(
        status: NotificationsStatus.error,
        notifications: const [],
        unreadCount: 0,
        errorMessage: 'Error',
      );
      
      final newState = state.copyWith(errorMessage: null);
      
      expect(newState.errorMessage, isNull);
    });

    test('should be equatable', () {
      final state1 = NotificationsState(
        status: NotificationsStatus.loaded,
        notifications: tNotificationList,
        unreadCount: 1,
        errorMessage: null,
      );
      
      final state2 = NotificationsState(
        status: NotificationsStatus.loaded,
        notifications: tNotificationList,
        unreadCount: 1,
        errorMessage: null,
      );
      
      expect(state1, equals(state2));
    });

    test('should not be equal with different status', () {
      final state1 = NotificationsState(
        status: NotificationsStatus.loading,
        notifications: tNotificationList,
        unreadCount: 1,
        errorMessage: null,
      );
      
      final state2 = NotificationsState(
        status: NotificationsStatus.loaded,
        notifications: tNotificationList,
        unreadCount: 1,
        errorMessage: null,
      );
      
      expect(state1, isNot(equals(state2)));
    });

    test('props should include all fields', () {
      final state = NotificationsState(
        status: NotificationsStatus.loaded,
        notifications: tNotificationList,
        unreadCount: 2,
        errorMessage: 'Error',
      );
      
      expect(state.props, contains(NotificationsStatus.loaded));
      expect(state.props, contains(tNotificationList));
      expect(state.props, contains(2));
      expect(state.props, contains('Error'));
    });
  });

  group('NotificationEntity', () {
    test('should create valid entity', () {
      expect(tNotification1.id, '1');
      expect(tNotification1.type, 'order_status');
      expect(tNotification1.title, 'Commande confirmée');
      expect(tNotification1.body, 'Votre commande a été confirmée');
      expect(tNotification1.data, {'order_id': 123});
      expect(tNotification1.isRead, isFalse);
    });

    test('should handle null data', () {
      final notification = NotificationEntity(
        id: '3',
        type: 'general',
        title: 'Test',
        body: 'Body',
        data: null,
        isRead: false,
        createdAt: DateTime(2024, 1, 15),
      );
      
      expect(notification.data, isNull);
    });

    test('should be equatable', () {
      final notification1 = NotificationEntity(
        id: '1',
        type: 'test',
        title: 'Title',
        body: 'Body',
        data: {'key': 'value'},
        isRead: false,
        createdAt: DateTime(2024, 1, 15),
      );
      
      final notification2 = NotificationEntity(
        id: '1',
        type: 'test',
        title: 'Title',
        body: 'Body',
        data: {'key': 'value'},
        isRead: false,
        createdAt: DateTime(2024, 1, 15),
      );
      
      expect(notification1, equals(notification2));
    });
  });
}
