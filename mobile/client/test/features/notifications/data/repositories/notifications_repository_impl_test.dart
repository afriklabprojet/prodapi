import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:drpharma_client/features/notifications/data/models/notification_model.dart';
import 'package:drpharma_client/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:drpharma_client/features/notifications/domain/entities/notification_entity.dart';

import 'notifications_repository_impl_test.mocks.dart';

@GenerateMocks([NotificationsRemoteDataSource])
void main() {
  late NotificationsRepositoryImpl repository;
  late MockNotificationsRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockNotificationsRemoteDataSource();
    repository = NotificationsRepositoryImpl(remoteDataSource: mockDataSource);
  });

  NotificationModel createNotificationModel({
    String id = '1',
    String type = 'order_status',
    String title = 'Test Title',
    String body = 'Test Body',
  }) {
    return NotificationModel(
      id: id,
      type: type,
      data: {'title': title, 'message': body},
      createdAt: '2024-01-01T00:00:00.000Z',
    );
  }

  group('NotificationsRepositoryImpl', () {
    group('getNotifications', () {
      test('should return list of notification entities on success', () async {
        // Arrange
        final models = [
          createNotificationModel(id: '1', title: 'Notification 1'),
          createNotificationModel(id: '2', title: 'Notification 2'),
        ];
        when(mockDataSource.getNotifications()).thenAnswer((_) async => models);

        // Act
        final result = await repository.getNotifications();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (notifications) {
            expect(notifications.length, 2);
            expect(notifications.first, isA<NotificationEntity>());
          },
        );
        verify(mockDataSource.getNotifications()).called(1);
      });

      test('should return empty list when no notifications', () async {
        // Arrange
        when(mockDataSource.getNotifications()).thenAnswer((_) async => []);

        // Act
        final result = await repository.getNotifications();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (notifications) => expect(notifications, isEmpty),
        );
      });

      test('should return UnauthorizedFailure on UnauthorizedException', () async {
        // Arrange
        when(mockDataSource.getNotifications())
            .thenThrow(UnauthorizedException(message: 'Unauthorized'));

        // Act
        final result = await repository.getNotifications();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockDataSource.getNotifications()).thenThrow(
          ServerException(message: 'Server error', statusCode: 500),
        );

        // Act
        final result = await repository.getNotifications();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect((failure as ServerFailure).statusCode, 500);
          },
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockDataSource.getNotifications())
            .thenThrow(NetworkException(message: 'No internet'));

        // Act
        final result = await repository.getNotifications();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on unexpected exception', () async {
        // Arrange
        when(mockDataSource.getNotifications())
            .thenAnswer((_) async => throw Exception('Unknown'));

        // Act
        final result = await repository.getNotifications();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('markAsRead', () {
      test('should return Right(null) on success', () async {
        // Arrange
        const notificationId = '123';
        when(mockDataSource.markAsRead(notificationId))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.markAsRead(notificationId);

        // Assert
        expect(result.isRight(), true);
        verify(mockDataSource.markAsRead(notificationId)).called(1);
      });

      test('should return UnauthorizedFailure on UnauthorizedException', () async {
        // Arrange
        const notificationId = '123';
        when(mockDataSource.markAsRead(notificationId))
            .thenThrow(UnauthorizedException(message: 'Unauthorized'));

        // Act
        final result = await repository.markAsRead(notificationId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        const notificationId = '123';
        when(mockDataSource.markAsRead(notificationId)).thenThrow(
          ServerException(message: 'Server error', statusCode: 404),
        );

        // Act
        final result = await repository.markAsRead(notificationId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        const notificationId = '123';
        when(mockDataSource.markAsRead(notificationId))
            .thenThrow(NetworkException(message: 'No internet'));

        // Act
        final result = await repository.markAsRead(notificationId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('markAllAsRead', () {
      test('should return Right(null) on success', () async {
        // Arrange
        when(mockDataSource.markAllAsRead()).thenAnswer((_) async => {});

        // Act
        final result = await repository.markAllAsRead();

        // Assert
        expect(result.isRight(), true);
        verify(mockDataSource.markAllAsRead()).called(1);
      });

      test('should return UnauthorizedFailure on UnauthorizedException', () async {
        // Arrange
        when(mockDataSource.markAllAsRead())
            .thenThrow(UnauthorizedException(message: 'Unauthorized'));

        // Act
        final result = await repository.markAllAsRead();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockDataSource.markAllAsRead()).thenThrow(
          ServerException(message: 'Server error', statusCode: 500),
        );

        // Act
        final result = await repository.markAllAsRead();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockDataSource.markAllAsRead())
            .thenThrow(NetworkException(message: 'No internet'));

        // Act
        final result = await repository.markAllAsRead();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('deleteNotification', () {
      test('should return Right(null) on success', () async {
        // Arrange
        const notificationId = '456';
        when(mockDataSource.deleteNotification(notificationId))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteNotification(notificationId);

        // Assert
        expect(result.isRight(), true);
        verify(mockDataSource.deleteNotification(notificationId)).called(1);
      });

      test('should return UnauthorizedFailure on UnauthorizedException', () async {
        // Arrange
        const notificationId = '456';
        when(mockDataSource.deleteNotification(notificationId))
            .thenThrow(UnauthorizedException(message: 'Unauthorized'));

        // Act
        final result = await repository.deleteNotification(notificationId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        const notificationId = '456';
        when(mockDataSource.deleteNotification(notificationId)).thenThrow(
          ServerException(message: 'Not found', statusCode: 404),
        );

        // Act
        final result = await repository.deleteNotification(notificationId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        const notificationId = '456';
        when(mockDataSource.deleteNotification(notificationId))
            .thenThrow(NetworkException(message: 'No internet'));

        // Act
        final result = await repository.deleteNotification(notificationId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on unexpected exception', () async {
        // Arrange
        const notificationId = '456';
        when(mockDataSource.deleteNotification(notificationId))
            .thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.deleteNotification(notificationId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });
  });
}
