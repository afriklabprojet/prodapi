import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/profile/domain/usecases/upload_avatar_usecase.dart';

import 'get_profile_usecase_test.mocks.dart';

void main() {
  late UploadAvatarUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UploadAvatarUseCase(repository: mockRepository);
  });

  group('UploadAvatarUseCase', () {
    group('constructor', () {
      test('should create instance with repository', () {
        expect(useCase.repository, equals(mockRepository));
      });
    });

    group('validation - empty image', () {
      test('should return ValidationFailure when image is empty', () async {
        // Arrange
        final emptyImage = Uint8List(0);

        // Act
        final result = await useCase(emptyImage);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message, 'Image invalide');
            expect(failure.errors['avatar'], contains('Aucune image sélectionnée'));
          },
          (r) => fail('Should return validation failure'),
        );
        verifyZeroInteractions(mockRepository);
      });
    });

    group('validation - image size', () {
      test('should return ValidationFailure when image exceeds 5MB', () async {
        // Arrange
        final largeImage = Uint8List(5 * 1024 * 1024 + 1); // 5MB + 1 byte

        // Act
        final result = await useCase(largeImage);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message, 'Image trop volumineuse');
            expect(failure.errors['avatar'], contains('L\'image ne doit pas dépasser 5MB'));
          },
          (r) => fail('Should return validation failure'),
        );
        verifyZeroInteractions(mockRepository);
      });

      test('should allow image exactly at 5MB limit', () async {
        // Arrange
        final exactLimit = Uint8List(5 * 1024 * 1024); // Exactly 5MB
        const avatarUrl = 'https://example.com/avatar.jpg';
        when(mockRepository.uploadAvatar(exactLimit))
            .thenAnswer((_) async => const Right(avatarUrl));

        // Act
        final result = await useCase(exactLimit);

        // Assert
        expect(result.isRight(), true);
        expect(result.fold((l) => '', (r) => r), avatarUrl);
        verify(mockRepository.uploadAvatar(exactLimit)).called(1);
      });

      test('should allow small image', () async {
        // Arrange
        final smallImage = Uint8List(1024); // 1KB
        const avatarUrl = 'https://example.com/small-avatar.jpg';
        when(mockRepository.uploadAvatar(smallImage))
            .thenAnswer((_) async => const Right(avatarUrl));

        // Act
        final result = await useCase(smallImage);

        // Assert
        expect(result.isRight(), true);
      });

      test('should allow image of 1MB', () async {
        // Arrange
        final oneMbImage = Uint8List(1024 * 1024); // 1MB
        const avatarUrl = 'https://example.com/avatar-1mb.jpg';
        when(mockRepository.uploadAvatar(oneMbImage))
            .thenAnswer((_) async => const Right(avatarUrl));

        // Act
        final result = await useCase(oneMbImage);

        // Assert
        expect(result.isRight(), true);
      });

      test('should allow image of 4.9MB', () async {
        // Arrange
        final almostLimit = Uint8List((4.9 * 1024 * 1024).toInt()); // 4.9MB
        const avatarUrl = 'https://example.com/avatar-4.9mb.jpg';
        when(mockRepository.uploadAvatar(almostLimit))
            .thenAnswer((_) async => const Right(avatarUrl));

        // Act
        final result = await useCase(almostLimit);

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('successful upload', () {
      test('should return avatar URL on success', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        const avatarUrl = 'https://storage.example.com/avatars/user1.jpg';
        when(mockRepository.uploadAvatar(imageBytes))
            .thenAnswer((_) async => const Right(avatarUrl));

        // Act
        final result = await useCase(imageBytes);

        // Assert
        expect(result, const Right(avatarUrl));
        verify(mockRepository.uploadAvatar(imageBytes)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should return URL with different formats', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        const avatarUrl = 'https://cdn.example.com/users/123/avatar.png?v=1';
        when(mockRepository.uploadAvatar(imageBytes))
            .thenAnswer((_) async => const Right(avatarUrl));

        // Act
        final result = await useCase(imageBytes);

        // Assert
        expect(result.fold((l) => '', (r) => r), contains('avatar.png'));
      });
    });

    group('repository errors', () {
      test('should return ServerFailure from repository', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final failure = ServerFailure(message: 'Upload failed');
        when(mockRepository.uploadAvatar(imageBytes))
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await useCase(imageBytes);

        // Assert
        expect(result, Left(failure));
      });

      test('should return NetworkFailure from repository', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final failure = NetworkFailure(message: 'No internet connection');
        when(mockRepository.uploadAvatar(imageBytes))
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await useCase(imageBytes);

        // Assert
        expect(result, Left(failure));
        expect(result.isLeft(), true);
      });

      test('should return UnauthorizedFailure from repository', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final failure = UnauthorizedFailure(message: 'Token expired');
        when(mockRepository.uploadAvatar(imageBytes))
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await useCase(imageBytes);

        // Assert
        expect(result, Left(failure));
      });

      test('should return ValidationFailure from repository', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final failure = ValidationFailure(
          message: 'Invalid image format',
          errors: {'avatar': ['Only JPG and PNG are allowed']},
        );
        when(mockRepository.uploadAvatar(imageBytes))
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await useCase(imageBytes);

        // Assert
        expect(result, Left(failure));
      });
    });

    group('image bytes content', () {
      test('should handle typical JPEG image bytes', () async {
        // Arrange - Simulated JPEG header
        final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, ...List.filled(100, 0)]);
        const avatarUrl = 'https://example.com/avatar.jpg';
        when(mockRepository.uploadAvatar(jpegBytes))
            .thenAnswer((_) async => const Right(avatarUrl));

        // Act
        final result = await useCase(jpegBytes);

        // Assert
        expect(result.isRight(), true);
      });

      test('should handle typical PNG image bytes', () async {
        // Arrange - Simulated PNG header
        final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, ...List.filled(100, 0)]);
        const avatarUrl = 'https://example.com/avatar.png';
        when(mockRepository.uploadAvatar(pngBytes))
            .thenAnswer((_) async => const Right(avatarUrl));

        // Act
        final result = await useCase(pngBytes);

        // Assert
        expect(result.isRight(), true);
      });

      test('should handle minimum valid image (1 byte)', () async {
        // Arrange
        final minImage = Uint8List.fromList([1]);
        const avatarUrl = 'https://example.com/tiny.jpg';
        when(mockRepository.uploadAvatar(minImage))
            .thenAnswer((_) async => const Right(avatarUrl));

        // Act
        final result = await useCase(minImage);

        // Assert
        expect(result.isRight(), true);
      });
    });
  });
}
