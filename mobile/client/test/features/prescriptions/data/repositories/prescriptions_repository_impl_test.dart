import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/prescriptions/data/datasources/prescriptions_remote_datasource.dart';
import 'package:drpharma_client/features/prescriptions/data/repositories/prescriptions_repository_impl.dart';

@GenerateMocks([PrescriptionsRemoteDataSource])
import 'prescriptions_repository_impl_test.mocks.dart';

void main() {
  late PrescriptionsRepositoryImpl repository;
  late MockPrescriptionsRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockPrescriptionsRemoteDataSource();
    repository = PrescriptionsRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
    );
  });

  // Helper pour créer des données de prescription de test
  Map<String, dynamic> createTestPrescriptionJson({
    int id = 1,
    String status = 'pending',
    String? notes,
  }) {
    return {
      'id': id,
      'status': status,
      'notes': notes,
      'images': [
        {'id': 1, 'url': 'https://example.com/image1.jpg'},
      ],
      'total_amount': '5000.00',
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-01T00:00:00.000Z',
    };
  }

  group('PrescriptionsRepositoryImpl', () {
    group('getPrescriptions', () {
      test('should return list of prescriptions when successful', () async {
        // Arrange
        final prescriptionsJson = [
          createTestPrescriptionJson(id: 1, status: 'pending'),
          createTestPrescriptionJson(id: 2, status: 'validated'),
        ];
        when(mockRemoteDataSource.getPrescriptions())
            .thenAnswer((_) async => prescriptionsJson);

        // Act
        final result = await repository.getPrescriptions();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) {
            expect(r.length, 2);
            expect(r[0].id, 1);
            expect(r[1].id, 2);
          },
        );
        verify(mockRemoteDataSource.getPrescriptions()).called(1);
      });

      test('should return empty list when no prescriptions', () async {
        // Arrange
        when(mockRemoteDataSource.getPrescriptions())
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getPrescriptions();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) => expect(r.isEmpty, true),
        );
      });

      test('should return UnauthorizedFailure on UnauthorizedException', () async {
        // Arrange
        when(mockRemoteDataSource.getPrescriptions()).thenThrow(
          UnauthorizedException(message: 'Token expired'),
        );

        // Act
        final result = await repository.getPrescriptions();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<UnauthorizedFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.getPrescriptions()).thenThrow(
          ServerException(message: 'Server error', statusCode: 500),
        );

        // Act
        final result = await repository.getPrescriptions();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(l, isA<ServerFailure>());
            expect((l as ServerFailure).statusCode, 500);
          },
          (r) => fail('Should not return success'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockRemoteDataSource.getPrescriptions()).thenThrow(
          NetworkException(message: 'No connection'),
        );

        // Act
        final result = await repository.getPrescriptions();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(mockRemoteDataSource.getPrescriptions()).thenAnswer(
          (_) async => throw Exception('Unknown error'),
        );

        // Act
        final result = await repository.getPrescriptions();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('getPrescriptionDetails', () {
      test('should return prescription details when successful', () async {
        // Arrange
        final prescriptionJson = createTestPrescriptionJson(
          id: 1,
          status: 'validated',
          notes: 'Test notes',
        );
        when(mockRemoteDataSource.getPrescriptionDetails(1))
            .thenAnswer((_) async => prescriptionJson);

        // Act
        final result = await repository.getPrescriptionDetails(1);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) {
            expect(r.id, 1);
            expect(r.notes, 'Test notes');
          },
        );
        verify(mockRemoteDataSource.getPrescriptionDetails(1)).called(1);
      });

      test('should return UnauthorizedFailure on UnauthorizedException', () async {
        // Arrange
        when(mockRemoteDataSource.getPrescriptionDetails(1)).thenThrow(
          UnauthorizedException(message: 'Unauthorized'),
        );

        // Act
        final result = await repository.getPrescriptionDetails(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<UnauthorizedFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.getPrescriptionDetails(1)).thenThrow(
          ServerException(message: 'Not found', statusCode: 404),
        );

        // Act
        final result = await repository.getPrescriptionDetails(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(l, isA<ServerFailure>());
            expect((l as ServerFailure).statusCode, 404);
          },
          (r) => fail('Should not return success'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockRemoteDataSource.getPrescriptionDetails(1)).thenThrow(
          NetworkException(message: 'No connection'),
        );

        // Act
        final result = await repository.getPrescriptionDetails(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(mockRemoteDataSource.getPrescriptionDetails(1)).thenAnswer(
          (_) async => throw Exception('Unknown error'),
        );

        // Act
        final result = await repository.getPrescriptionDetails(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('payPrescription', () {
      test('should return payment response when successful', () async {
        // Arrange
        final paymentResponse = {
          'success': true,
          'payment_url': 'https://payment.example.com/pay/123',
          'transaction_id': 'TXN123',
        };
        when(mockRemoteDataSource.payPrescription(1, 'mobile_money'))
            .thenAnswer((_) async => paymentResponse);

        // Act
        final result = await repository.payPrescription(
          prescriptionId: 1,
          paymentMethod: 'mobile_money',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) {
            expect(r['success'], true);
            expect(r['payment_url'], isNotNull);
            expect(r['transaction_id'], 'TXN123');
          },
        );
        verify(mockRemoteDataSource.payPrescription(1, 'mobile_money')).called(1);
      });

      test('should return UnauthorizedFailure on UnauthorizedException', () async {
        // Arrange
        when(mockRemoteDataSource.payPrescription(1, 'mobile_money')).thenThrow(
          UnauthorizedException(message: 'Token expired'),
        );

        // Act
        final result = await repository.payPrescription(
          prescriptionId: 1,
          paymentMethod: 'mobile_money',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<UnauthorizedFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ValidationFailure on ValidationException', () async {
        // Arrange
        when(mockRemoteDataSource.payPrescription(1, 'invalid_method')).thenThrow(
          ValidationException(errors: {
            'payment_method': ['Invalid payment method'],
          }),
        );

        // Act
        final result = await repository.payPrescription(
          prescriptionId: 1,
          paymentMethod: 'invalid_method',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(l, isA<ValidationFailure>());
            expect((l as ValidationFailure).errors, containsPair('payment_method', ['Invalid payment method']));
          },
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.payPrescription(1, 'mobile_money')).thenThrow(
          ServerException(message: 'Payment failed', statusCode: 500),
        );

        // Act
        final result = await repository.payPrescription(
          prescriptionId: 1,
          paymentMethod: 'mobile_money',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(l, isA<ServerFailure>());
            expect((l as ServerFailure).message, 'Payment failed');
          },
          (r) => fail('Should not return success'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockRemoteDataSource.payPrescription(1, 'mobile_money')).thenThrow(
          NetworkException(message: 'No connection'),
        );

        // Act
        final result = await repository.payPrescription(
          prescriptionId: 1,
          paymentMethod: 'mobile_money',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(mockRemoteDataSource.payPrescription(1, 'mobile_money')).thenAnswer(
          (_) async => throw Exception('Unknown error'),
        );

        // Act
        final result = await repository.payPrescription(
          prescriptionId: 1,
          paymentMethod: 'mobile_money',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });
  });
}
