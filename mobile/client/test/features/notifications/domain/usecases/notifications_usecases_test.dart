import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/notifications/domain/entities/notification_entity.dart';
import 'package:drpharma_client/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:drpharma_client/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:drpharma_client/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:drpharma_client/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';

import 'notifications_usecases_test.mocks.dart';

@GenerateMocks([NotificationsRepository])
void main() {
  late MockNotificationsRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationsRepository();
  });

  final now = DateTime(2024, 6, 1);

  final tNotification = NotificationEntity(
    id: 'notif-1',
    type: 'orderUpdate',
    title: 'Commande confirmée',
    body: 'Votre commande est confirmée.',
    isRead: false,
    createdAt: now,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // GetNotificationsUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetNotificationsUseCase', () {
    late GetNotificationsUseCase useCase;

    setUp(() {
      useCase = GetNotificationsUseCase(mockRepository);
    });

    test('returns list of notifications on success', () async {
      final tList = [tNotification];
      when(
        mockRepository.getNotifications(),
      ).thenAnswer((_) async => Right(tList));

      final result = await useCase();

      expect(result, Right(tList));
      verify(mockRepository.getNotifications()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns empty list when no notifications', () async {
      when(
        mockRepository.getNotifications(),
      ).thenAnswer((_) async => const Right([]));

      final result = await useCase();

      result.fold(
        (_) => fail('expected Right'),
        (list) => expect(list, isEmpty),
      );
    });

    test('returns failure on server error', () async {
      const failure = ServerFailure(message: 'Erreur serveur');
      when(
        mockRepository.getNotifications(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      expect(result, const Left(failure));
    });

    test('returns NetworkFailure on no connection', () async {
      const failure = NetworkFailure(message: 'Aucune connexion');
      when(
        mockRepository.getNotifications(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // MarkNotificationAsReadUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('MarkNotificationAsReadUseCase', () {
    late MarkNotificationAsReadUseCase useCase;

    setUp(() {
      useCase = MarkNotificationAsReadUseCase(mockRepository);
    });

    test('calls repository.markAsRead with correct id', () async {
      when(
        mockRepository.markAsRead('notif-1'),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase('notif-1');

      expect(result.isRight(), isTrue);
      verify(mockRepository.markAsRead('notif-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns failure when repository fails', () async {
      const failure = ServerFailure(message: 'Notification introuvable');
      when(
        mockRepository.markAsRead('bad-id'),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase('bad-id');

      expect(result, const Left(failure));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // MarkAllNotificationsReadUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('MarkAllNotificationsReadUseCase', () {
    late MarkAllNotificationsReadUseCase useCase;

    setUp(() {
      useCase = MarkAllNotificationsReadUseCase(mockRepository);
    });

    test('calls repository.markAllAsRead', () async {
      when(
        mockRepository.markAllAsRead(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      verify(mockRepository.markAllAsRead()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns failure when repository fails', () async {
      const failure = ServerFailure(message: 'Erreur lors du marquage');
      when(
        mockRepository.markAllAsRead(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      expect(result, const Left(failure));
    });
  });
}
