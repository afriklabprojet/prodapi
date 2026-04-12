import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/profile/domain/entities/profile_entity.dart';
import 'package:drpharma_client/features/profile/domain/repositories/profile_repository.dart';
import 'package:drpharma_client/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:drpharma_client/features/profile/domain/usecases/delete_avatar_usecase.dart';

import 'get_profile_usecase_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
  });

  final tProfile = ProfileEntity(
    id: 1,
    name: 'Alice Koné',
    email: 'alice@example.com',
    createdAt: DateTime(2024, 1, 1),
    totalOrders: 3,
    completedOrders: 2,
    totalSpent: 8000.0,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // GetProfileUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetProfileUseCase', () {
    late GetProfileUseCase useCase;

    setUp(() {
      useCase = GetProfileUseCase(repository: mockRepository);
    });

    test('returns profile on success', () async {
      when(
        mockRepository.getProfile(),
      ).thenAnswer((_) async => Right(tProfile));

      final result = await useCase();

      expect(result, Right(tProfile));
      verify(mockRepository.getProfile()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns failure on error', () async {
      const failure = ServerFailure(message: 'Erreur serveur');
      when(
        mockRepository.getProfile(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      expect(result, const Left(failure));
    });

    test('returns NetworkFailure on connectivity issue', () async {
      const failure = NetworkFailure(message: 'Pas de connexion');
      when(
        mockRepository.getProfile(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, const NetworkFailure(message: 'Pas de connexion')),
        (_) => fail('expected Left'),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // DeleteAvatarUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('DeleteAvatarUseCase', () {
    late DeleteAvatarUseCase useCase;

    setUp(() {
      useCase = DeleteAvatarUseCase(repository: mockRepository);
    });

    test('returns Right(void) on success', () async {
      when(
        mockRepository.deleteAvatar(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      verify(mockRepository.deleteAvatar()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns failure on error', () async {
      const failure = ServerFailure(message: 'Suppression impossible');
      when(
        mockRepository.deleteAvatar(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
    });
  });
}
