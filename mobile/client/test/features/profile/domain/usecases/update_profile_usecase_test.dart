import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/profile/domain/entities/profile_entity.dart';
import 'package:drpharma_client/features/profile/domain/entities/update_profile_entity.dart';
import 'package:drpharma_client/features/profile/domain/usecases/update_profile_usecase.dart';

import 'get_profile_usecase_test.mocks.dart';

void main() {
  late UpdateProfileUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UpdateProfileUseCase(repository: mockRepository);
  });

  final tUpdatedProfile = ProfileEntity(
    id: 1,
    name: 'Updated Name',
    email: 'updated@example.com',
    phone: '0612345678',
    createdAt: DateTime(2024, 1, 1),
  );

  group('UpdateProfileUseCase', () {
    group('constructor', () {
      test('should create instance with repository', () {
        expect(useCase.repository, equals(mockRepository));
      });
    });

    group('name validation', () {
      test('should return ValidationFailure when name is empty', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(name: '   ');

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message, 'Le nom est requis');
            expect(failure.errors['name'], contains('Le nom ne peut pas être vide'));
          },
          (r) => fail('Should return validation failure'),
        );
        verifyZeroInteractions(mockRepository);
      });

      test('should not validate name when null', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(email: 'valid@email.com');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
        verify(mockRepository.updateProfile(updateProfile)).called(1);
      });

      test('should allow valid name', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(name: 'John Doe');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('email validation', () {
      test('should return ValidationFailure for invalid email', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(email: 'invalid-email');

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message, 'Email invalide');
            expect(failure.errors['email'], contains('Veuillez entrer un email valide'));
          },
          (r) => fail('Should return validation failure'),
        );
        verifyZeroInteractions(mockRepository);
      });

      test('should return ValidationFailure for email without @', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(email: 'testemail.com');

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isLeft(), true);
      });

      test('should return ValidationFailure for email without domain', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(email: 'test@');

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isLeft(), true);
      });

      test('should allow valid email', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(email: 'test@example.com');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });

      test('should allow email with subdomain', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(email: 'test@mail.example.com');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });

      test('should not validate email when null', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(name: 'Valid Name');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('phone validation', () {
      test('should return ValidationFailure for short phone number', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(phone: '1234567');

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message, 'Téléphone invalide');
            expect(failure.errors['phone'], contains('Le numéro doit contenir au moins 8 chiffres'));
          },
          (r) => fail('Should return validation failure'),
        );
        verifyZeroInteractions(mockRepository);
      });

      test('should allow phone with exactly 8 digits', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(phone: '12345678');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });

      test('should allow phone with more than 8 digits', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(phone: '0612345678');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });

      test('should allow empty phone', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(phone: '');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });

      test('should not validate phone when null', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(name: 'Valid Name');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('password change validation', () {
      test('should return ValidationFailure when current password is empty', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(
          currentPassword: '',
          newPassword: 'newpassword123',
          newPasswordConfirmation: 'newpassword123',
        );

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message, 'Mot de passe actuel requis');
            expect(failure.errors['current_password'], contains('Le mot de passe actuel est requis'));
          },
          (r) => fail('Should return validation failure'),
        );
        verifyZeroInteractions(mockRepository);
      });

      test('should return ValidationFailure when new password is too short', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(
          currentPassword: 'currentpass',
          newPassword: 'short',
          newPasswordConfirmation: 'short',
        );

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message, 'Mot de passe trop court');
            expect(failure.errors['password'], contains('Le mot de passe doit contenir au moins 8 caractères'));
          },
          (r) => fail('Should return validation failure'),
        );
      });

      test('should return ValidationFailure when passwords do not match', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(
          currentPassword: 'currentpass',
          newPassword: 'newpassword123',
          newPasswordConfirmation: 'differentpassword',
        );

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message, 'Les mots de passe ne correspondent pas');
            expect(failure.errors['password_confirmation'], contains('Les mots de passe ne correspondent pas'));
          },
          (r) => fail('Should return validation failure'),
        );
      });

      test('should allow valid password change', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(
          currentPassword: 'currentpassword',
          newPassword: 'newpassword123',
          newPasswordConfirmation: 'newpassword123',
        );
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
        verify(mockRepository.updateProfile(updateProfile)).called(1);
      });

      test('should allow exactly 8 character password', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(
          currentPassword: 'currentpass',
          newPassword: '12345678',
          newPasswordConfirmation: '12345678',
        );
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('successful update', () {
      test('should call repository and return updated profile', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(
          name: 'New Name',
          email: 'new@email.com',
          phone: '0612345678',
        );
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result, Right(tUpdatedProfile));
        verify(mockRepository.updateProfile(updateProfile)).called(1);
      });

      test('should update profile with only name', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(name: 'New Name');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });

      test('should update profile with only email', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(email: 'newemail@test.com');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });

      test('should update profile with only phone', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(phone: '0699999999');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Right(tUpdatedProfile));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('repository errors', () {
      test('should return ServerFailure from repository', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(name: 'Valid Name');
        final failure = ServerFailure(message: 'Server error');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result, Left(failure));
      });

      test('should return NetworkFailure from repository', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(name: 'Valid Name');
        final failure = NetworkFailure(message: 'No connection');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result, Left(failure));
      });

      test('should return UnauthorizedFailure from repository', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(name: 'Valid Name');
        final failure = UnauthorizedFailure(message: 'Unauthorized');
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result, Left(failure));
      });

      test('should return ValidationFailure from repository', () async {
        // Arrange
        const updateProfile = UpdateProfileEntity(name: 'Valid Name');
        final failure = ValidationFailure(
          message: 'Email already exists',
          errors: {'email': ['This email is already in use']},
        );
        when(mockRepository.updateProfile(updateProfile))
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await useCase(updateProfile);

        // Assert
        expect(result, Left(failure));
        result.fold(
          (f) => expect((f as ValidationFailure).errors['email'], isNotNull),
          (r) => fail('Should return failure'),
        );
      });
    });
  });

  group('UpdateProfileEntity', () {
    group('constructor', () {
      test('should create with all null values', () {
        const entity = UpdateProfileEntity();
        expect(entity.name, isNull);
        expect(entity.email, isNull);
        expect(entity.phone, isNull);
        expect(entity.currentPassword, isNull);
        expect(entity.newPassword, isNull);
        expect(entity.newPasswordConfirmation, isNull);
      });

      test('should create with all values', () {
        const entity = UpdateProfileEntity(
          name: 'Test',
          email: 'test@test.com',
          phone: '0612345678',
          currentPassword: 'current',
          newPassword: 'newpass',
          newPasswordConfirmation: 'newpass',
        );
        expect(entity.name, 'Test');
        expect(entity.email, 'test@test.com');
        expect(entity.phone, '0612345678');
        expect(entity.currentPassword, 'current');
        expect(entity.newPassword, 'newpass');
        expect(entity.newPasswordConfirmation, 'newpass');
      });
    });

    group('hasPasswordChange', () {
      test('should return true when both passwords are set', () {
        const entity = UpdateProfileEntity(
          currentPassword: 'current',
          newPassword: 'newpass',
        );
        expect(entity.hasPasswordChange, true);
      });

      test('should return false when only current password is set', () {
        const entity = UpdateProfileEntity(currentPassword: 'current');
        expect(entity.hasPasswordChange, false);
      });

      test('should return false when only new password is set', () {
        const entity = UpdateProfileEntity(newPassword: 'newpass');
        expect(entity.hasPasswordChange, false);
      });

      test('should return false when no passwords are set', () {
        const entity = UpdateProfileEntity(name: 'Test');
        expect(entity.hasPasswordChange, false);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        const entity1 = UpdateProfileEntity(name: 'Test', email: 'test@test.com');
        const entity2 = UpdateProfileEntity(name: 'Test', email: 'test@test.com');
        expect(entity1, equals(entity2));
      });

      test('should not be equal for different values', () {
        const entity1 = UpdateProfileEntity(name: 'Test1');
        const entity2 = UpdateProfileEntity(name: 'Test2');
        expect(entity1, isNot(equals(entity2)));
      });

      test('should have correct props list length', () {
        const entity = UpdateProfileEntity();
        expect(entity.props.length, 6);
      });
    });
  });
}
