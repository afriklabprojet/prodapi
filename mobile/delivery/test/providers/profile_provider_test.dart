import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/data/models/user.dart';
import 'package:courier/presentation/providers/profile_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('profileProvider', () {
    late MockAuthRepository mockAuthRepo;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
    });

    test('returns User when getProfile succeeds', () async {
      final testUser = User(
        id: 1,
        name: 'Test User',
        email: 'test@test.com',
        phone: '+225071234567',
      );
      when(() => mockAuthRepo.getProfile()).thenAnswer((_) async => testUser);

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
      );
      addTearDown(container.dispose);

      final future = container.read(profileProvider.future);
      final result = await future;

      expect(result.id, 1);
      expect(result.name, 'Test User');
      expect(result.email, 'test@test.com');
      verify(() => mockAuthRepo.getProfile()).called(1);
    });

    test('returns correct phone number', () async {
      final testUser = User(
        id: 2,
        name: 'Marie',
        email: 'marie@test.com',
        phone: '+225070000000',
      );
      when(() => mockAuthRepo.getProfile()).thenAnswer((_) async => testUser);

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(profileProvider.future);
      expect(result.phone, '+225070000000');
    });

    test('returns correct email', () async {
      final testUser = User(
        id: 3,
        name: 'Admin',
        email: 'admin@test.com',
        phone: '+225072222222',
      );
      when(() => mockAuthRepo.getProfile()).thenAnswer((_) async => testUser);

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(profileProvider.future);
      expect(result.email, 'admin@test.com');
    });

    test('returns User with id 2', () async {
      final testUser = User(
        id: 2,
        name: 'Jean',
        email: 'jean@test.com',
        phone: '+225071111111',
      );
      when(() => mockAuthRepo.getProfile()).thenAnswer((_) async => testUser);

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(profileProvider.future);
      expect(result.id, 2);
      expect(result.name, 'Jean');
    });
  });
}
