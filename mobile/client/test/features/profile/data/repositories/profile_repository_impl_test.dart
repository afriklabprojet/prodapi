import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:drpharma_client/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:drpharma_client/features/profile/data/models/profile_model.dart';
import 'package:drpharma_client/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:drpharma_client/features/profile/domain/entities/update_profile_entity.dart';

@GenerateMocks([ProfileRemoteDataSource, ProfileLocalDataSource])
import 'profile_repository_impl_test.mocks.dart';

void main() {
  late ProfileRepositoryImpl repository;
  late MockProfileRemoteDataSource mockRemoteDataSource;
  late MockProfileLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockProfileRemoteDataSource();
    mockLocalDataSource = MockProfileLocalDataSource();
    repository = ProfileRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  // Helper pour créer un ProfileModel de test
  ProfileModel createTestProfileModel({
    int id = 1,
    String name = 'Test User',
    String email = 'test@example.com',
  }) {
    return ProfileModel(
      id: id,
      name: name,
      email: email,
      phone: '+2250700000000',
      avatar: 'https://example.com/avatar.jpg',
      defaultAddress: '123 Rue Test, Abidjan',
      createdAt: '2024-01-01T00:00:00.000Z',
      totalOrders: 10,
      completedOrders: 8,
      totalSpent: 50000,
    );
  }

  group('ProfileRepositoryImpl', () {
    group('getProfile', () {
      test('should return profile and cache it when successful', () async {
        // Arrange
        final profile = createTestProfileModel();
        when(mockRemoteDataSource.getProfile())
            .thenAnswer((_) async => profile);
        when(mockLocalDataSource.cacheProfile(profile))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getProfile();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) {
            expect(r.id, 1);
            expect(r.name, 'Test User');
            expect(r.email, 'test@example.com');
          },
        );
        verify(mockRemoteDataSource.getProfile()).called(1);
        verify(mockLocalDataSource.cacheProfile(profile)).called(1);
      });

      test('should return cached profile on NetworkException', () async {
        // Arrange
        final cachedProfile = createTestProfileModel(name: 'Cached User');
        when(mockRemoteDataSource.getProfile()).thenThrow(
          NetworkException(message: 'No connection'),
        );
        when(mockLocalDataSource.getCachedProfile())
            .thenAnswer((_) async => cachedProfile);

        // Act
        final result = await repository.getProfile();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) => expect(r.name, 'Cached User'),
        );
      });

      test('should return NetworkFailure if no cached profile', () async {
        // Arrange
        when(mockRemoteDataSource.getProfile()).thenThrow(
          NetworkException(message: 'No connection'),
        );
        when(mockLocalDataSource.getCachedProfile())
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getProfile();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.getProfile()).thenThrow(
          ServerException(message: 'Server error', statusCode: 500),
        );

        // Act
        final result = await repository.getProfile();

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

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(mockRemoteDataSource.getProfile()).thenThrow(
          Exception('Unknown error'),
        );

        // Act
        final result = await repository.getProfile();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('updateProfile', () {
      test('should update profile and cache it when successful', () async {
        // Arrange
        final updateEntity = UpdateProfileEntity(
          name: 'Updated Name',
          email: 'updated@example.com',
        );
        final updatedProfile = createTestProfileModel(
          name: 'Updated Name',
          email: 'updated@example.com',
        );
        when(mockRemoteDataSource.updateProfile(any))
            .thenAnswer((_) async => updatedProfile);
        when(mockLocalDataSource.cacheProfile(updatedProfile))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateProfile(updateEntity);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) {
            expect(r.name, 'Updated Name');
            expect(r.email, 'updated@example.com');
          },
        );
        verify(mockLocalDataSource.cacheProfile(updatedProfile)).called(1);
      });

      test('should return ValidationFailure on ValidationException', () async {
        // Arrange
        final updateEntity = UpdateProfileEntity(
          name: '',
          email: 'invalid-email',
        );
        when(mockRemoteDataSource.updateProfile(any)).thenThrow(
          ValidationException(errors: {
            'name': ['Name is required'],
            'email': ['Invalid email format'],
          }),
        );

        // Act
        final result = await repository.updateProfile(updateEntity);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(l, isA<ValidationFailure>());
            expect((l as ValidationFailure).errors.containsKey('name'), true);
            expect(l.errors.containsKey('email'), true);
          },
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        final updateEntity = UpdateProfileEntity(name: 'Test');
        when(mockRemoteDataSource.updateProfile(any)).thenThrow(
          ServerException(message: 'Server error', statusCode: 500),
        );

        // Act
        final result = await repository.updateProfile(updateEntity);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        final updateEntity = UpdateProfileEntity(name: 'Test');
        when(mockRemoteDataSource.updateProfile(any)).thenThrow(
          NetworkException(message: 'No connection'),
        );

        // Act
        final result = await repository.updateProfile(updateEntity);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        final updateEntity = UpdateProfileEntity(name: 'Test');
        when(mockRemoteDataSource.updateProfile(any)).thenThrow(
          Exception('Unknown error'),
        );

        // Act
        final result = await repository.updateProfile(updateEntity);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('uploadAvatar', () {
      test('should return avatar URL when successful', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        const avatarUrl = 'https://example.com/new-avatar.jpg';
        when(mockRemoteDataSource.uploadAvatar(imageBytes))
            .thenAnswer((_) async => avatarUrl);

        // Act
        final result = await repository.uploadAvatar(imageBytes);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) => expect(r, avatarUrl),
        );
        verify(mockRemoteDataSource.uploadAvatar(imageBytes)).called(1);
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        when(mockRemoteDataSource.uploadAvatar(imageBytes)).thenThrow(
          ServerException(message: 'Upload failed', statusCode: 500),
        );

        // Act
        final result = await repository.uploadAvatar(imageBytes);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        when(mockRemoteDataSource.uploadAvatar(imageBytes)).thenThrow(
          NetworkException(message: 'No connection'),
        );

        // Act
        final result = await repository.uploadAvatar(imageBytes);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        when(mockRemoteDataSource.uploadAvatar(imageBytes)).thenThrow(
          Exception('Unknown error'),
        );

        // Act
        final result = await repository.uploadAvatar(imageBytes);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('deleteAvatar', () {
      test('should return void when deletion is successful', () async {
        // Arrange
        when(mockRemoteDataSource.deleteAvatar())
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteAvatar();

        // Assert
        expect(result.isRight(), true);
        verify(mockRemoteDataSource.deleteAvatar()).called(1);
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.deleteAvatar()).thenThrow(
          ServerException(message: 'Delete failed', statusCode: 500),
        );

        // Act
        final result = await repository.deleteAvatar();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockRemoteDataSource.deleteAvatar()).thenThrow(
          NetworkException(message: 'No connection'),
        );

        // Act
        final result = await repository.deleteAvatar();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(mockRemoteDataSource.deleteAvatar()).thenThrow(
          Exception('Unknown error'),
        );

        // Act
        final result = await repository.deleteAvatar();

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
