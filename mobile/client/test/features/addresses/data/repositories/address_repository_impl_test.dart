import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/addresses/data/datasources/address_remote_datasource.dart';
import 'package:drpharma_client/features/addresses/data/models/address_model.dart';
import 'package:drpharma_client/features/addresses/data/repositories/address_repository_impl.dart';

@GenerateMocks([AddressRemoteDataSource])
import 'address_repository_impl_test.mocks.dart';

void main() {
  late AddressRepositoryImpl repository;
  late MockAddressRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAddressRemoteDataSource();
    repository = AddressRepositoryImpl(mockRemoteDataSource);
  });

  // Helper pour créer un AddressModel de test
  AddressModel createTestAddressModel({
    int id = 1,
    String label = 'Maison',
    String address = '123 Rue Test',
    bool isDefault = true,
  }) {
    return AddressModel(
      id: id,
      label: label,
      address: address,
      isDefault: isDefault,
      fullAddress: '$address, Abidjan',
      hasCoordinates: false,
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
      city: 'Abidjan',
      district: 'Cocody',
      phone: '+2250700000000',
    );
  }

  group('AddressRepositoryImpl', () {
    group('getAddresses', () {
      test('should return list of addresses when successful', () async {
        // Arrange
        final addresses = [
          createTestAddressModel(id: 1, label: 'Maison'),
          createTestAddressModel(id: 2, label: 'Bureau', isDefault: false),
        ];
        when(
          mockRemoteDataSource.getAddresses(),
        ).thenAnswer((_) async => addresses);

        // Act
        final result = await repository.getAddresses();

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Should not return failure'), (r) {
          expect(r.length, 2);
          expect(r[0].id, 1);
          expect(r[1].id, 2);
        });
        verify(mockRemoteDataSource.getAddresses()).called(1);
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(
          mockRemoteDataSource.getAddresses(),
        ).thenThrow(ServerException(message: 'Server error', statusCode: 500));

        // Act
        final result = await repository.getAddresses();

        // Assert
        expect(result.isLeft(), true);
        result.fold((l) {
          expect(l, isA<ServerFailure>());
          expect((l as ServerFailure).message, 'Server error');
          expect(l.statusCode, 500);
        }, (r) => fail('Should not return success'));
      });

      test(
        'should return UnauthorizedFailure on UnauthorizedException',
        () async {
          // Arrange
          when(
            mockRemoteDataSource.getAddresses(),
          ).thenThrow(UnauthorizedException(message: 'Unauthorized'));

          // Act
          final result = await repository.getAddresses();

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (l) => expect(l, isA<UnauthorizedFailure>()),
            (r) => fail('Should not return success'),
          );
        },
      );

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(
          mockRemoteDataSource.getAddresses(),
        ).thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.getAddresses();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('getAddress', () {
      test('should return address when successful', () async {
        // Arrange
        final address = createTestAddressModel(id: 1, label: 'Maison');
        when(
          mockRemoteDataSource.getAddress(1),
        ).thenAnswer((_) async => address);

        // Act
        final result = await repository.getAddress(1);

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Should not return failure'), (r) {
          expect(r.id, 1);
          expect(r.label, 'Maison');
        });
        verify(mockRemoteDataSource.getAddress(1)).called(1);
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(
          mockRemoteDataSource.getAddress(1),
        ).thenThrow(ServerException(message: 'Not found', statusCode: 404));

        // Act
        final result = await repository.getAddress(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold((l) {
          expect(l, isA<ServerFailure>());
          expect((l as ServerFailure).statusCode, 404);
        }, (r) => fail('Should not return success'));
      });

      test(
        'should return UnauthorizedFailure on UnauthorizedException',
        () async {
          // Arrange
          when(
            mockRemoteDataSource.getAddress(1),
          ).thenThrow(UnauthorizedException(message: 'Unauthorized'));

          // Act
          final result = await repository.getAddress(1);

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (l) => expect(l, isA<UnauthorizedFailure>()),
            (r) => fail('Should not return success'),
          );
        },
      );

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(
          mockRemoteDataSource.getAddress(1),
        ).thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.getAddress(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('getDefaultAddress', () {
      test('should return default address when successful', () async {
        // Arrange
        final address = createTestAddressModel(id: 1, isDefault: true);
        when(
          mockRemoteDataSource.getDefaultAddress(),
        ).thenAnswer((_) async => address);

        // Act
        final result = await repository.getDefaultAddress();

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Should not return failure'), (r) {
          expect(r.isDefault, true);
        });
        verify(mockRemoteDataSource.getDefaultAddress()).called(1);
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.getDefaultAddress()).thenThrow(
          ServerException(message: 'No default address', statusCode: 404),
        );

        // Act
        final result = await repository.getDefaultAddress();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test(
        'should return UnauthorizedFailure on UnauthorizedException',
        () async {
          // Arrange
          when(
            mockRemoteDataSource.getDefaultAddress(),
          ).thenThrow(UnauthorizedException(message: 'Unauthorized'));

          // Act
          final result = await repository.getDefaultAddress();

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (l) => expect(l, isA<UnauthorizedFailure>()),
            (r) => fail('Should not return success'),
          );
        },
      );

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(
          mockRemoteDataSource.getDefaultAddress(),
        ).thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.getDefaultAddress();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('createAddress', () {
      test('should return created address when successful', () async {
        // Arrange
        final address = createTestAddressModel(id: 1, label: 'Bureau');
        when(
          mockRemoteDataSource.createAddress(
            label: anyNamed('label'),
            address: anyNamed('address'),
            city: anyNamed('city'),
            district: anyNamed('district'),
            phone: anyNamed('phone'),
            instructions: anyNamed('instructions'),
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            isDefault: anyNamed('isDefault'),
          ),
        ).thenAnswer((_) async => address);

        // Act
        final result = await repository.createAddress(
          label: 'Bureau',
          address: '456 Rue Office',
          city: 'Abidjan',
          district: 'Plateau',
          phone: '+2250700000001',
          isDefault: false,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Should not return failure'), (r) {
          expect(r.label, 'Bureau');
        });
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(
          mockRemoteDataSource.createAddress(
            label: anyNamed('label'),
            address: anyNamed('address'),
            city: anyNamed('city'),
            district: anyNamed('district'),
            phone: anyNamed('phone'),
            instructions: anyNamed('instructions'),
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            isDefault: anyNamed('isDefault'),
          ),
        ).thenThrow(
          ServerException(message: 'Validation error', statusCode: 422),
        );

        // Act
        final result = await repository.createAddress(
          label: 'Bureau',
          address: '456 Rue Office',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold((l) {
          expect(l, isA<ServerFailure>());
          expect((l as ServerFailure).statusCode, 422);
        }, (r) => fail('Should not return success'));
      });

      test(
        'should return UnauthorizedFailure on UnauthorizedException',
        () async {
          // Arrange
          when(
            mockRemoteDataSource.createAddress(
              label: anyNamed('label'),
              address: anyNamed('address'),
              city: anyNamed('city'),
              district: anyNamed('district'),
              phone: anyNamed('phone'),
              instructions: anyNamed('instructions'),
              latitude: anyNamed('latitude'),
              longitude: anyNamed('longitude'),
              isDefault: anyNamed('isDefault'),
            ),
          ).thenThrow(UnauthorizedException(message: 'Unauthorized'));

          // Act
          final result = await repository.createAddress(
            label: 'Bureau',
            address: '456 Rue Office',
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (l) => expect(l, isA<UnauthorizedFailure>()),
            (r) => fail('Should not return success'),
          );
        },
      );

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(
          mockRemoteDataSource.createAddress(
            label: anyNamed('label'),
            address: anyNamed('address'),
            city: anyNamed('city'),
            district: anyNamed('district'),
            phone: anyNamed('phone'),
            instructions: anyNamed('instructions'),
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            isDefault: anyNamed('isDefault'),
          ),
        ).thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.createAddress(
          label: 'Bureau',
          address: '456 Rue Office',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('updateAddress', () {
      test('should return updated address when successful', () async {
        // Arrange
        final address = createTestAddressModel(id: 1, label: 'Bureau Updated');
        when(
          mockRemoteDataSource.updateAddress(
            id: anyNamed('id'),
            label: anyNamed('label'),
            address: anyNamed('address'),
            city: anyNamed('city'),
            district: anyNamed('district'),
            phone: anyNamed('phone'),
            instructions: anyNamed('instructions'),
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            isDefault: anyNamed('isDefault'),
          ),
        ).thenAnswer((_) async => address);

        // Act
        final result = await repository.updateAddress(
          id: 1,
          label: 'Bureau Updated',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Should not return failure'), (r) {
          expect(r.label, 'Bureau Updated');
        });
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(
          mockRemoteDataSource.updateAddress(
            id: anyNamed('id'),
            label: anyNamed('label'),
            address: anyNamed('address'),
            city: anyNamed('city'),
            district: anyNamed('district'),
            phone: anyNamed('phone'),
            instructions: anyNamed('instructions'),
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            isDefault: anyNamed('isDefault'),
          ),
        ).thenThrow(ServerException(message: 'Not found', statusCode: 404));

        // Act
        final result = await repository.updateAddress(
          id: 999,
          label: 'Updated',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test(
        'should return UnauthorizedFailure on UnauthorizedException',
        () async {
          // Arrange
          when(
            mockRemoteDataSource.updateAddress(
              id: anyNamed('id'),
              label: anyNamed('label'),
              address: anyNamed('address'),
              city: anyNamed('city'),
              district: anyNamed('district'),
              phone: anyNamed('phone'),
              instructions: anyNamed('instructions'),
              latitude: anyNamed('latitude'),
              longitude: anyNamed('longitude'),
              isDefault: anyNamed('isDefault'),
            ),
          ).thenThrow(UnauthorizedException(message: 'Unauthorized'));

          // Act
          final result = await repository.updateAddress(
            id: 1,
            label: 'Updated',
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (l) => expect(l, isA<UnauthorizedFailure>()),
            (r) => fail('Should not return success'),
          );
        },
      );

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(
          mockRemoteDataSource.updateAddress(
            id: anyNamed('id'),
            label: anyNamed('label'),
            address: anyNamed('address'),
            city: anyNamed('city'),
            district: anyNamed('district'),
            phone: anyNamed('phone'),
            instructions: anyNamed('instructions'),
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            isDefault: anyNamed('isDefault'),
          ),
        ).thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.updateAddress(id: 1, label: 'Updated');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('deleteAddress', () {
      test('should return void when deletion is successful', () async {
        // Arrange
        when(mockRemoteDataSource.deleteAddress(1)).thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteAddress(1);

        // Assert
        expect(result.isRight(), true);
        verify(mockRemoteDataSource.deleteAddress(1)).called(1);
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(
          mockRemoteDataSource.deleteAddress(1),
        ).thenThrow(ServerException(message: 'Not found', statusCode: 404));

        // Act
        final result = await repository.deleteAddress(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test(
        'should return UnauthorizedFailure on UnauthorizedException',
        () async {
          // Arrange
          when(
            mockRemoteDataSource.deleteAddress(1),
          ).thenThrow(UnauthorizedException(message: 'Unauthorized'));

          // Act
          final result = await repository.deleteAddress(1);

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (l) => expect(l, isA<UnauthorizedFailure>()),
            (r) => fail('Should not return success'),
          );
        },
      );

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(
          mockRemoteDataSource.deleteAddress(1),
        ).thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.deleteAddress(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('setDefaultAddress', () {
      test('should return address when set as default successfully', () async {
        // Arrange
        final address = createTestAddressModel(id: 2, isDefault: true);
        when(
          mockRemoteDataSource.setDefaultAddress(2),
        ).thenAnswer((_) async => address);

        // Act
        final result = await repository.setDefaultAddress(2);

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Should not return failure'), (r) {
          expect(r.id, 2);
          expect(r.isDefault, true);
        });
        verify(mockRemoteDataSource.setDefaultAddress(2)).called(1);
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(
          mockRemoteDataSource.setDefaultAddress(2),
        ).thenThrow(ServerException(message: 'Not found', statusCode: 404));

        // Act
        final result = await repository.setDefaultAddress(2);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test(
        'should return UnauthorizedFailure on UnauthorizedException',
        () async {
          // Arrange
          when(
            mockRemoteDataSource.setDefaultAddress(2),
          ).thenThrow(UnauthorizedException(message: 'Unauthorized'));

          // Act
          final result = await repository.setDefaultAddress(2);

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (l) => expect(l, isA<UnauthorizedFailure>()),
            (r) => fail('Should not return success'),
          );
        },
      );

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(
          mockRemoteDataSource.setDefaultAddress(2),
        ).thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.setDefaultAddress(2);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('getLabels', () {
      test('should return labels when successful', () async {
        // Arrange
        final formData = AddressFormData(
          labels: ['Maison', 'Bureau', 'Autre'],
          defaultPhone: '+2250700000000',
          userName: 'Test User',
        );
        when(
          mockRemoteDataSource.getLabels(),
        ).thenAnswer((_) async => formData);

        // Act
        final result = await repository.getLabels();

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Should not return failure'), (r) {
          expect(r.labels, contains('Maison'));
          expect(r.labels, contains('Bureau'));
        });
        verify(mockRemoteDataSource.getLabels()).called(1);
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(
          mockRemoteDataSource.getLabels(),
        ).thenThrow(ServerException(message: 'Server error', statusCode: 500));

        // Act
        final result = await repository.getLabels();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test(
        'should return UnauthorizedFailure on UnauthorizedException',
        () async {
          // Arrange
          when(
            mockRemoteDataSource.getLabels(),
          ).thenThrow(UnauthorizedException(message: 'Unauthorized'));

          // Act
          final result = await repository.getLabels();

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (l) => expect(l, isA<UnauthorizedFailure>()),
            (r) => fail('Should not return success'),
          );
        },
      );

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(
          mockRemoteDataSource.getLabels(),
        ).thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.getLabels();

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
