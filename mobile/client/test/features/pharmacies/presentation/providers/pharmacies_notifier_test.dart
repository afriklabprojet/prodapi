import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/pharmacies/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/pharmacies/domain/usecases/get_pharmacies_usecase.dart';
import 'package:drpharma_client/features/pharmacies/domain/usecases/get_nearby_pharmacies_usecase.dart';
import 'package:drpharma_client/features/pharmacies/domain/usecases/get_on_duty_pharmacies_usecase.dart';
import 'package:drpharma_client/features/pharmacies/domain/usecases/get_pharmacy_details_usecase.dart';
import 'package:drpharma_client/features/pharmacies/domain/usecases/get_featured_pharmacies_usecase.dart';
import 'package:drpharma_client/features/pharmacies/presentation/providers/pharmacies_notifier.dart';
import 'package:drpharma_client/features/pharmacies/presentation/providers/pharmacies_state.dart';

class MockGetPharmaciesUseCase extends Mock implements GetPharmaciesUseCase {}

class MockGetNearbyPharmaciesUseCase extends Mock
    implements GetNearbyPharmaciesUseCase {}

class MockGetOnDutyPharmaciesUseCase extends Mock
    implements GetOnDutyPharmaciesUseCase {}

class MockGetPharmacyDetailsUseCase extends Mock
    implements GetPharmacyDetailsUseCase {}

class MockGetFeaturedPharmaciesUseCase extends Mock
    implements GetFeaturedPharmaciesUseCase {}

PharmacyEntity _makePharmacy({
  int id = 1,
  String name = 'Pharmacie du Centre',
  bool isOpen = true,
}) => PharmacyEntity(
  id: id,
  name: name,
  address: 'Rue des Pharmaciens',
  phone: '+2250700000001',
  status: 'active',
  isOpen: isOpen,
);

void main() {
  late MockGetPharmaciesUseCase mockGetPharmacies;
  late MockGetNearbyPharmaciesUseCase mockGetNearby;
  late MockGetOnDutyPharmaciesUseCase mockGetOnDuty;
  late MockGetPharmacyDetailsUseCase mockGetDetails;
  late MockGetFeaturedPharmaciesUseCase mockGetFeatured;
  late PharmaciesNotifier notifier;

  setUp(() {
    mockGetPharmacies = MockGetPharmaciesUseCase();
    mockGetNearby = MockGetNearbyPharmaciesUseCase();
    mockGetOnDuty = MockGetOnDutyPharmaciesUseCase();
    mockGetDetails = MockGetPharmacyDetailsUseCase();
    mockGetFeatured = MockGetFeaturedPharmaciesUseCase();

    notifier = PharmaciesNotifier(
      getPharmaciesUseCase: mockGetPharmacies,
      getNearbyPharmaciesUseCase: mockGetNearby,
      getOnDutyPharmaciesUseCase: mockGetOnDuty,
      getPharmacyDetailsUseCase: mockGetDetails,
      getFeaturedPharmaciesUseCase: mockGetFeatured,
    );
  });

  tearDown(() {
    notifier.dispose();
  });

  group('PharmaciesNotifier — initial state', () {
    test('starts at initial status with empty lists', () {
      expect(notifier.state.status, PharmaciesStatus.initial);
      expect(notifier.state.pharmacies, isEmpty);
    });
  });

  group('PharmaciesNotifier — fetchPharmacies', () {
    test('success populates pharmacies list', () async {
      final pharmacies = [_makePharmacy(id: 1), _makePharmacy(id: 2)];
      when(
        () => mockGetPharmacies(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Right(pharmacies));

      await notifier.fetchPharmacies();

      expect(notifier.state.status, PharmaciesStatus.success);
      expect(notifier.state.pharmacies.length, 2);
      expect(notifier.state.hasReachedMax, isTrue);
    });

    test('failure sets error status with message', () async {
      const failure = ServerFailure(message: 'Erreur réseau', statusCode: 503);
      when(
        () => mockGetPharmacies(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Left(failure));

      await notifier.fetchPharmacies();

      expect(notifier.state.status, PharmaciesStatus.error);
      expect(notifier.state.errorMessage, 'Erreur réseau');
    });

    test('refresh=true resets state and refetches from page 1', () async {
      final pharmacies = [_makePharmacy(id: 1)];
      when(
        () => mockGetPharmacies(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Right(pharmacies));

      await notifier.fetchPharmacies();
      expect(notifier.state.pharmacies.length, 1);

      final morePharmacies = [_makePharmacy(id: 10), _makePharmacy(id: 11)];
      when(
        () => mockGetPharmacies(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Right(morePharmacies));

      await notifier.fetchPharmacies(refresh: true);

      // refresh should replace (not append)
      expect(notifier.state.pharmacies.length, 2);
      expect(notifier.state.pharmacies.first.id, 10);
    });

    test('transitions through loading state before resolving', () async {
      final states = <PharmaciesStatus>[];
      notifier.addListener((s) => states.add(s.status));

      when(
        () => mockGetPharmacies(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Right([_makePharmacy()]));

      await notifier.fetchPharmacies();

      expect(states, contains(PharmaciesStatus.loading));
      expect(notifier.state.status, PharmaciesStatus.success);
    });
  });

  group('PharmaciesNotifier — fetchNearbyPharmacies', () {
    test('success populates nearbyPharmacies', () async {
      final pharmacies = [_makePharmacy(id: 5)];
      when(
        () => mockGetNearby(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          radius: any(named: 'radius'),
        ),
      ).thenAnswer((_) async => Right(pharmacies));

      await notifier.fetchNearbyPharmacies(latitude: 5.3, longitude: -4.0);

      expect(notifier.state.status, PharmaciesStatus.success);
      expect(notifier.state.nearbyPharmacies.length, 1);
      expect(notifier.state.nearbyPharmacies.first.id, 5);
    });

    test('failure sets error', () async {
      const failure = NetworkFailure();
      when(
        () => mockGetNearby(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          radius: any(named: 'radius'),
        ),
      ).thenAnswer((_) async => Left(failure));

      await notifier.fetchNearbyPharmacies(latitude: 5.3, longitude: -4.0);

      expect(notifier.state.status, PharmaciesStatus.error);
    });
  });

  group('PharmaciesNotifier — fetchPharmacyDetails', () {
    test('success sets selectedPharmacy', () async {
      final pharmacy = _makePharmacy(id: 99);
      when(
        () => mockGetDetails(any()),
      ).thenAnswer((_) async => Right(pharmacy));

      await notifier.fetchPharmacyDetails(99);

      expect(notifier.state.status, PharmaciesStatus.success);
      expect(notifier.state.selectedPharmacy!.id, 99);
    });

    test('failure sets error', () async {
      const failure = ServerFailure(message: 'Non trouvé', statusCode: 404);
      when(() => mockGetDetails(any())).thenAnswer((_) async => Left(failure));

      await notifier.fetchPharmacyDetails(999);

      expect(notifier.state.status, PharmaciesStatus.error);
      expect(notifier.state.errorMessage, 'Non trouvé');
    });
  });

  group('PharmaciesNotifier — fetchOnDutyPharmacies', () {
    test('success populates onDutyPharmacies', () async {
      final pharmacies = [_makePharmacy(id: 3), _makePharmacy(id: 4)];
      when(
        () => mockGetOnDuty(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          radius: any(named: 'radius'),
        ),
      ).thenAnswer((_) async => Right(pharmacies));

      await notifier.fetchOnDutyPharmacies();

      expect(notifier.state.status, PharmaciesStatus.success);
      expect(notifier.state.onDutyPharmacies.length, 2);
    });

    test('failure sets error', () async {
      const failure = ServerFailure(message: 'err');
      when(
        () => mockGetOnDuty(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          radius: any(named: 'radius'),
        ),
      ).thenAnswer((_) async => Left(failure));

      await notifier.fetchOnDutyPharmacies();

      expect(notifier.state.status, PharmaciesStatus.error);
    });
  });

  group('PharmaciesNotifier — fetchFeaturedPharmacies', () {
    test('success sets featuredPharmacies and isFeaturedLoaded', () async {
      final pharmacies = [_makePharmacy(id: 7)];
      when(() => mockGetFeatured()).thenAnswer((_) async => Right(pharmacies));

      await notifier.fetchFeaturedPharmacies();

      expect(notifier.state.featuredPharmacies.length, 1);
      expect(notifier.state.isFeaturedLoaded, isTrue);
      expect(notifier.state.isFeaturedLoading, isFalse);
    });

    test('failure with isRetry=true marks isFeaturedLoaded=true', () async {
      const failure = ServerFailure(message: 'err');
      when(() => mockGetFeatured()).thenAnswer((_) async => Left(failure));

      await notifier.fetchFeaturedPharmacies(isRetry: true);

      expect(
        notifier.state.isFeaturedLoaded,
        isTrue,
      ); // isRetry=true → loaded=true on failure
      expect(notifier.state.isFeaturedLoading, isFalse);
    });
  });

  group('PharmaciesNotifier — clearError', () {
    test('clears error message when in error state', () async {
      const failure = ServerFailure(message: 'Erreur');
      when(
        () => mockGetPharmacies(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Left(failure));

      await notifier.fetchPharmacies();
      expect(notifier.state.errorMessage, isNotNull);

      notifier.clearError();
      expect(notifier.state.errorMessage, isNull);
    });

    test('clearError is no-op when no error', () {
      expect(notifier.state.errorMessage, isNull);
      notifier.clearError(); // should not crash
      expect(notifier.state.errorMessage, isNull);
    });
  });

  group('PharmaciesNotifier — clearSelectedPharmacy', () {
    test('clears selectedPharmacy', () async {
      final pharmacy = _makePharmacy(id: 55);
      when(() => mockGetDetails(55)).thenAnswer((_) async => Right(pharmacy));

      await notifier.fetchPharmacyDetails(55);
      expect(notifier.state.selectedPharmacy, isNotNull);

      notifier.clearSelectedPharmacy();
      expect(notifier.state.selectedPharmacy, isNull);
    });
  });
}
