import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:drpharma_pharmacy/features/profile/presentation/providers/profile_provider.dart';
import 'package:drpharma_pharmacy/features/profile/data/repositories/profile_repository.dart';
import 'package:drpharma_pharmacy/core/errors/failure.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_pharmacy/features/auth/presentation/providers/auth_provider.dart';
import 'package:drpharma_pharmacy/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockRef extends Mock implements Ref {}
class MockAuthRepository extends Mock implements AuthRepository {}

/// Fake ProviderListenable for registerFallbackValue
class _FakeProviderListenable extends Fake
    implements ProviderListenable<Object?> {}

void main() {
  late MockProfileRepository mockRepository;
  late MockRef mockRef;
  late ProfileNotifier notifier;
  late AuthNotifier authNotifier;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(_FakeProviderListenable());
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    mockRef = MockRef();
    mockAuthRepository = MockAuthRepository();
    authNotifier = AuthNotifier(mockAuthRepository);
    notifier = ProfileNotifier(mockRepository, mockRef);
  });

  group('ProfileNotifier initial state', () {
    test('initial state is AsyncData(null)', () {
      expect(notifier.state, isA<AsyncData<void>>());
    });
  });

  group('ProfileNotifier updatePharmacy', () {
    test('sets loading then data on success', () async {
      final pharmacy = PharmacyEntity(
        id: 1,
        name: 'Pharmacie Mise à Jour',
        status: 'active',
      );
      when(() => mockRepository.updatePharmacy(1, any()))
          .thenAnswer((_) async => Right(pharmacy));
      // Mock ref.read to return a real AuthNotifier so .checkAuthStatus() works
      when(() => mockRef.read(authProvider.notifier)).thenReturn(authNotifier);
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Left(ServerFailure('no user')));

      await notifier.updatePharmacy(1, {'name': 'Pharmacie Mise à Jour'});

      expect(notifier.state, isA<AsyncData<void>>());
    });

    test('sets error state on failure', () async {
      when(() => mockRepository.updatePharmacy(1, any()))
          .thenAnswer((_) async => Left(ServerFailure('Erreur serveur')));

      await notifier.updatePharmacy(1, {'name': 'Test'});

      expect(notifier.state, isA<AsyncError<void>>());
    });
  });

  group('ProfileNotifier updateProfile', () {
    test('sets loading then data on success', () async {
      when(() => mockRepository.updateProfile(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => mockRef.read(authProvider.notifier)).thenReturn(authNotifier);
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Left(ServerFailure('no user')));

      await notifier.updateProfile({'name': 'Updated Name'});

      expect(notifier.state, isA<AsyncData<void>>());
    });

    test('sets error state and throws on failure', () async {
      when(() => mockRepository.updateProfile(any()))
          .thenAnswer((_) async => Left(ServerFailure('Profil non trouvé')));

      expect(
        () => notifier.updateProfile({'name': 'Failed'}),
        throwsA(isA<Exception>()),
      );
    });
  });
}
