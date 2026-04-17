import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/features/pharmacies/data/repositories/pharmacies_repository_impl.dart';
import 'package:drpharma_client/features/pharmacies/data/datasources/pharmacies_remote_datasource.dart';
import 'package:drpharma_client/features/pharmacies/data/models/pharmacy_model.dart';
import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/core/errors/failures.dart';

@GenerateMocks([PharmaciesRemoteDataSource])
import 'pharmacies_repository_impl_test.mocks.dart';

void main() {
  late PharmaciesRepositoryImpl repository;
  late MockPharmaciesRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockPharmaciesRemoteDataSource();
    repository = PharmaciesRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
    );
  });

  // Helper to create test pharmacy model
  PharmacyModel createTestPharmacyModel({
    int id = 1,
    String name = 'Test Pharmacy',
    bool isOpen = true,
  }) {
    return PharmacyModel(
      id: id,
      name: name,
      address: 'Test Address',
      phone: '+24107000000',
      status: 'active',
      isOpen: isOpen,
      latitude: 0.4162,
      longitude: 9.4673,
    );
  }

  group('PharmaciesRepositoryImpl', () {
    group('getPharmacies', () {
      test('should return list of pharmacies on success', () async {
        // Arrange
        final models = [
          createTestPharmacyModel(id: 1, name: 'Pharmacy 1'),
          createTestPharmacyModel(id: 2, name: 'Pharmacy 2'),
        ];
        when(
          mockRemoteDataSource.getPharmacies(page: 1, perPage: 20),
        ).thenAnswer((_) async => models);

        // Act
        final result = await repository.getPharmacies();

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Expected Right, got Left'), (pharmacies) {
          expect(pharmacies.length, 2);
          expect(pharmacies[0].name, 'Pharmacy 1');
          expect(pharmacies[1].name, 'Pharmacy 2');
        });
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(
          mockRemoteDataSource.getPharmacies(page: 1, perPage: 20),
        ).thenThrow(ServerException(message: 'Server error', statusCode: 500));

        // Act
        final result = await repository.getPharmacies();

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).message, 'Server error');
        }, (r) => fail('Expected Left, got Right'));
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(
          mockRemoteDataSource.getPharmacies(page: 1, perPage: 20),
        ).thenThrow(NetworkException(message: 'No internet'));

        // Act
        final result = await repository.getPharmacies();

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<NetworkFailure>());
        }, (r) => fail('Expected Left, got Right'));
      });

      test('should pass pagination parameters', () async {
        // Arrange
        when(
          mockRemoteDataSource.getPharmacies(page: 2, perPage: 10),
        ).thenAnswer((_) async => []);

        // Act
        await repository.getPharmacies(page: 2, perPage: 10);

        // Assert
        verify(
          mockRemoteDataSource.getPharmacies(page: 2, perPage: 10),
        ).called(1);
      });
    });

    group('getNearbyPharmacies', () {
      test('should return nearby pharmacies on success', () async {
        // Arrange
        final models = [
          createTestPharmacyModel(id: 1, name: 'Nearby Pharmacy'),
        ];
        when(
          mockRemoteDataSource.getNearbyPharmacies(
            latitude: 0.4162,
            longitude: 9.4673,
            radius: 5.0,
          ),
        ).thenAnswer((_) async => models);

        // Act
        final result = await repository.getNearbyPharmacies(
          latitude: 0.4162,
          longitude: 9.4673,
          radius: 5.0,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Expected Right'), (pharmacies) {
          expect(pharmacies.length, 1);
          expect(pharmacies[0].name, 'Nearby Pharmacy');
        });
      });

      test('should return ServerFailure on error', () async {
        // Arrange
        when(
          mockRemoteDataSource.getNearbyPharmacies(
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            radius: anyNamed('radius'),
          ),
        ).thenThrow(ServerException(message: 'Error', statusCode: 500));

        // Act
        final result = await repository.getNearbyPharmacies(
          latitude: 0.0,
          longitude: 0.0,
        );

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('getOnDutyPharmacies', () {
      test('should return on-duty pharmacies on success', () async {
        // Arrange
        final models = [
          createTestPharmacyModel(id: 1, name: 'On Duty Pharmacy'),
        ];
        when(
          mockRemoteDataSource.getOnDutyPharmacies(
            latitude: null,
            longitude: null,
            radius: null,
          ),
        ).thenAnswer((_) async => models);

        // Act
        final result = await repository.getOnDutyPharmacies();

        // Assert
        expect(result.isRight(), true);
      });

      test('should pass location parameters when provided', () async {
        // Arrange
        when(
          mockRemoteDataSource.getOnDutyPharmacies(
            latitude: 0.4162,
            longitude: 9.4673,
            radius: 10.0,
          ),
        ).thenAnswer((_) async => []);

        // Act
        await repository.getOnDutyPharmacies(
          latitude: 0.4162,
          longitude: 9.4673,
          radius: 10.0,
        );

        // Assert
        verify(
          mockRemoteDataSource.getOnDutyPharmacies(
            latitude: 0.4162,
            longitude: 9.4673,
            radius: 10.0,
          ),
        ).called(1);
      });
    });

    group('getPharmacyDetails', () {
      test('should return pharmacy details on success', () async {
        // Arrange
        final model = createTestPharmacyModel(id: 1, name: 'Detailed Pharmacy');
        when(
          mockRemoteDataSource.getPharmacyDetails(1),
        ).thenAnswer((_) async => model);

        // Act
        final result = await repository.getPharmacyDetails(1);

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Expected Right'), (pharmacy) {
          expect(pharmacy.id, 1);
          expect(pharmacy.name, 'Detailed Pharmacy');
        });
      });

      test('should return ServerFailure when pharmacy not found', () async {
        // Arrange
        when(
          mockRemoteDataSource.getPharmacyDetails(999),
        ).thenThrow(ServerException(message: 'Not found', statusCode: 404));

        // Act
        final result = await repository.getPharmacyDetails(999);

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect((failure as ServerFailure).statusCode, 404);
        }, (r) => fail('Expected Left'));
      });
    });

    // ── getFeaturedPharmacies ─────────────────────────────
    group('getFeaturedPharmacies', () {
      test('should return list of featured pharmacies on success', () async {
        final models = [
          createTestPharmacyModel(id: 1, name: 'Featured Pharmacy A'),
          createTestPharmacyModel(id: 2, name: 'Featured Pharmacy B'),
        ];
        when(
          mockRemoteDataSource.getFeaturedPharmacies(),
        ).thenAnswer((_) async => models);

        final result = await repository.getFeaturedPharmacies();

        expect(result.isRight(), true);
        result.fold((l) => fail('Expected Right'), (list) {
          expect(list.length, 2);
          expect(list[0].name, 'Featured Pharmacy A');
        });
      });

      test('should return empty list when no featured pharmacies', () async {
        when(
          mockRemoteDataSource.getFeaturedPharmacies(),
        ).thenAnswer((_) async => []);

        final result = await repository.getFeaturedPharmacies();

        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Expected Right'),
          (list) => expect(list, isEmpty),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        when(
          mockRemoteDataSource.getFeaturedPharmacies(),
        ).thenThrow(ServerException(message: 'Server error', statusCode: 500));

        final result = await repository.getFeaturedPharmacies();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (r) => fail('Expected Left'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        when(
          mockRemoteDataSource.getFeaturedPharmacies(),
        ).thenThrow(NetworkException(message: 'No connection'));

        final result = await repository.getFeaturedPharmacies();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (r) => fail('Expected Left'),
        );
      });

      test(
        'should return UnauthorizedFailure on UnauthorizedException',
        () async {
          when(
            mockRemoteDataSource.getFeaturedPharmacies(),
          ).thenThrow(UnauthorizedException(message: 'Unauthorized'));

          final result = await repository.getFeaturedPharmacies();

          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<UnauthorizedFailure>()),
            (r) => fail('Expected Left'),
          );
        },
      );
    });
  });
}
