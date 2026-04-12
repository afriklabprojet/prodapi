import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/pharmacies/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/pharmacies/domain/repositories/pharmacies_repository.dart';
import 'package:drpharma_client/features/pharmacies/domain/usecases/get_pharmacies_usecase.dart';
import 'package:drpharma_client/features/pharmacies/domain/usecases/get_pharmacy_details_usecase.dart';
import 'package:drpharma_client/features/pharmacies/domain/usecases/get_nearby_pharmacies_usecase.dart';
import 'package:drpharma_client/features/pharmacies/domain/usecases/get_featured_pharmacies_usecase.dart';
import 'package:drpharma_client/features/pharmacies/domain/usecases/get_on_duty_pharmacies_usecase.dart';

@GenerateMocks([PharmaciesRepository])
import 'pharmacies_usecases_test.mocks.dart';

PharmacyEntity _pharmacy({int id = 1, String name = 'Pharmacie du Centre'}) =>
    PharmacyEntity(
      id: id,
      name: name,
      address: 'Plateau, Abidjan',
      phone: '+2250700000001',
      status: 'active',
      isOpen: true,
      latitude: 5.3545,
      longitude: -4.0018,
    );

void main() {
  late MockPharmaciesRepository mockRepo;

  setUp(() => mockRepo = MockPharmaciesRepository());

  // ────────────────────────────────────────────────────────────────────────────
  // GetPharmaciesUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetPharmaciesUseCase', () {
    late GetPharmaciesUseCase useCase;
    setUp(() => useCase = GetPharmaciesUseCase(mockRepo));

    test('returns list of pharmacies on success', () async {
      final pharmacies = [_pharmacy(id: 1), _pharmacy(id: 2)];
      when(
        mockRepo.getPharmacies(page: 1, perPage: 20),
      ).thenAnswer((_) async => Right(pharmacies));

      final result = await useCase(page: 1, perPage: 20);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (p) => expect(p.length, 2));
    });

    test('defaults page 1 and perPage 20', () async {
      when(
        mockRepo.getPharmacies(page: 1, perPage: 20),
      ).thenAnswer((_) async => const Right([]));
      await useCase();
      verify(mockRepo.getPharmacies(page: 1, perPage: 20)).called(1);
    });

    test('returns failure on server error', () async {
      when(
        mockRepo.getPharmacies(page: 1, perPage: 20),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Err')));
      final result = await useCase();
      expect(result.isLeft(), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // GetPharmacyDetailsUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetPharmacyDetailsUseCase', () {
    late GetPharmacyDetailsUseCase useCase;
    setUp(() => useCase = GetPharmacyDetailsUseCase(mockRepo));

    test('returns pharmacy details for valid id', () async {
      final pharmacy = _pharmacy(id: 5, name: 'Grande Pharmacie');
      when(
        mockRepo.getPharmacyDetails(5),
      ).thenAnswer((_) async => Right(pharmacy));

      final result = await useCase(5);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (p) {
        expect(p.id, 5);
        expect(p.name, 'Grande Pharmacie');
      });
    });

    test('returns failure for unknown id', () async {
      when(mockRepo.getPharmacyDetails(999)).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: 'Not found', statusCode: 404)),
      );

      final result = await useCase(999);
      expect(result.isLeft(), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // GetNearbyPharmaciesUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetNearbyPharmaciesUseCase', () {
    late GetNearbyPharmaciesUseCase useCase;
    setUp(() => useCase = GetNearbyPharmaciesUseCase(mockRepo));

    const lat = 5.3545, lon = -4.0018, radius = 5.0;

    test('returns nearby pharmacies on success', () async {
      when(
        mockRepo.getNearbyPharmacies(
          latitude: lat,
          longitude: lon,
          radius: radius,
        ),
      ).thenAnswer((_) async => Right([_pharmacy()]));

      final result = await useCase(
        latitude: lat,
        longitude: lon,
        radius: radius,
      );
      expect(result.isRight(), isTrue);
    });

    test('defaults radius to 10.0', () async {
      when(
        mockRepo.getNearbyPharmacies(
          latitude: lat,
          longitude: lon,
          radius: 10.0,
        ),
      ).thenAnswer((_) async => const Right([]));

      await useCase(latitude: lat, longitude: lon);

      verify(
        mockRepo.getNearbyPharmacies(
          latitude: lat,
          longitude: lon,
          radius: 10.0,
        ),
      ).called(1);
    });

    test('returns failure on network error', () async {
      when(
        mockRepo.getNearbyPharmacies(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          radius: anyNamed('radius'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(latitude: lat, longitude: lon);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // GetFeaturedPharmaciesUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetFeaturedPharmaciesUseCase', () {
    late GetFeaturedPharmaciesUseCase useCase;
    setUp(() => useCase = GetFeaturedPharmaciesUseCase(mockRepo));

    test('returns featured pharmacies on success', () async {
      when(mockRepo.getFeaturedPharmacies()).thenAnswer(
        (_) async => Right([
          _pharmacy(name: 'Featured ONE'),
          _pharmacy(id: 2, name: 'Featured TWO'),
        ]),
      );

      final result = await useCase();
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (p) => expect(p.length, 2));
    });

    test('returns failure when service unavailable', () async {
      when(mockRepo.getFeaturedPharmacies()).thenAnswer(
        (_) async => const Left(
          ServerFailure(message: 'Service unavailable', statusCode: 503),
        ),
      );

      final result = await useCase();
      expect(result.isLeft(), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // GetOnDutyPharmaciesUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetOnDutyPharmaciesUseCase', () {
    late GetOnDutyPharmaciesUseCase useCase;
    setUp(() => useCase = GetOnDutyPharmaciesUseCase(mockRepo));

    test('returns on-duty pharmacies with coordinates', () async {
      when(
        mockRepo.getOnDutyPharmacies(
          latitude: 5.3,
          longitude: -4.0,
          radius: 15.0,
        ),
      ).thenAnswer((_) async => Right([_pharmacy()]));

      final result = await useCase(
        latitude: 5.3,
        longitude: -4.0,
        radius: 15.0,
      );
      expect(result.isRight(), isTrue);
    });

    test('calls repository with null coords when none provided', () async {
      when(
        mockRepo.getOnDutyPharmacies(
          latitude: null,
          longitude: null,
          radius: null,
        ),
      ).thenAnswer((_) async => Right([_pharmacy()]));

      await useCase();

      verify(
        mockRepo.getOnDutyPharmacies(
          latitude: null,
          longitude: null,
          radius: null,
        ),
      ).called(1);
    });

    test('returns failure on error', () async {
      when(
        mockRepo.getOnDutyPharmacies(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          radius: anyNamed('radius'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase();
      expect(result.isLeft(), isTrue);
    });
  });
}
