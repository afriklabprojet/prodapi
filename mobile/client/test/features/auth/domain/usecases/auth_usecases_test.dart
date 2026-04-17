import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/auth/domain/entities/auth_response_entity.dart';
import 'package:drpharma_client/features/auth/domain/entities/user_entity.dart';
import 'package:drpharma_client/features/auth/domain/repositories/auth_repository.dart';
import 'package:drpharma_client/features/auth/domain/usecases/login_usecase.dart';
import 'package:drpharma_client/features/auth/domain/usecases/register_usecase.dart';
import 'package:drpharma_client/features/auth/domain/usecases/logout_usecase.dart';
import 'package:drpharma_client/features/auth/domain/usecases/get_current_user_usecase.dart';

@GenerateMocks([AuthRepository])
import 'auth_usecases_test.mocks.dart';

// ────────────────────────────────────────────────────────────────────────────
// Fixtures
// ────────────────────────────────────────────────────────────────────────────

final _user = UserEntity(
  id: 1,
  name: 'Jean Dupont',
  email: 'jean@example.com',
  phone: '+2250700000001',
  createdAt: DateTime(2024, 1, 1),
);

final _authResponse = AuthResponseEntity(user: _user, token: 'tok_abc123');

const _serverFailure = ServerFailure(message: 'Erreur serveur');
const _networkFailure = NetworkFailure(message: 'Pas de connexion');
const _unauthorizedFailure = UnauthorizedFailure(message: 'Non autorisé');

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  // ────────────────────────────────────────────────────────────────────────────
  // LoginUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('LoginUseCase', () {
    late LoginUseCase useCase;

    setUp(() => useCase = LoginUseCase(mockRepo));

    test('returns AuthResponseEntity on success', () async {
      when(
        mockRepo.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => Right(_authResponse));

      final result = await useCase(
        email: 'jean@example.com',
        password: 'Pass1234!',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (r) => expect(r, _authResponse),
      );
      verify(
        mockRepo.login(email: 'jean@example.com', password: 'Pass1234!'),
      ).called(1);
    });

    test('returns ServerFailure on server error', () async {
      when(
        mockRepo.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => const Left(_serverFailure));

      final result = await useCase(email: 'user@test.com', password: 'bad');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns NetworkFailure when offline', () async {
      when(
        mockRepo.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => const Left(_networkFailure));

      final result = await useCase(email: 'user@test.com', password: 'pass');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns UnauthorizedFailure for wrong credentials', () async {
      when(
        mockRepo.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => const Left(_unauthorizedFailure));

      final result = await useCase(email: 'user@test.com', password: 'wrong');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // RegisterUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('RegisterUseCase', () {
    late RegisterUseCase useCase;

    setUp(() => useCase = RegisterUseCase(mockRepo));

    test('returns AuthResponseEntity on success', () async {
      when(
        mockRepo.register(
          name: anyNamed('name'),
          email: anyNamed('email'),
          phone: anyNamed('phone'),
          password: anyNamed('password'),
          address: anyNamed('address'),
        ),
      ).thenAnswer((_) async => Right(_authResponse));

      final result = await useCase(
        name: 'Jean',
        email: 'jean@example.com',
        phone: '+2250700000001',
        password: 'Pass1234!',
        passwordConfirmation: 'Pass1234!',
      );

      expect(result.isRight(), isTrue);
      verify(
        mockRepo.register(
          name: 'Jean',
          email: 'jean@example.com',
          phone: '+2250700000001',
          password: 'Pass1234!',
          address: null,
        ),
      ).called(1);
    });

    test('passes optional address to repository', () async {
      when(
        mockRepo.register(
          name: anyNamed('name'),
          email: anyNamed('email'),
          phone: anyNamed('phone'),
          password: anyNamed('password'),
          address: anyNamed('address'),
        ),
      ).thenAnswer((_) async => Right(_authResponse));

      await useCase(
        name: 'Jean',
        email: 'jean@example.com',
        phone: '+2250700000001',
        password: 'Pass1234!',
        passwordConfirmation: 'Pass1234!',
        address: '12 rue de la Paix, Abidjan',
      );

      verify(
        mockRepo.register(
          name: 'Jean',
          email: 'jean@example.com',
          phone: '+2250700000001',
          password: 'Pass1234!',
          address: '12 rue de la Paix, Abidjan',
        ),
      ).called(1);
    });

    test('returns ServerFailure on duplicate email/phone', () async {
      when(
        mockRepo.register(
          name: anyNamed('name'),
          email: anyNamed('email'),
          phone: anyNamed('phone'),
          password: anyNamed('password'),
          address: anyNamed('address'),
        ),
      ).thenAnswer((_) async => const Left(_serverFailure));

      final result = await useCase(
        name: 'Jean',
        email: 'existing@test.com',
        phone: '+225000',
        password: 'Pass1234!',
        passwordConfirmation: 'Pass1234!',
      );

      expect(result.isLeft(), isTrue);
    });

    test('returns ValidationFailure on invalid input', () async {
      const validationFailure = ValidationFailure(
        message: 'Email invalide',
        errors: <String, List<String>>{
          'email': ['Le format est invalide'],
        },
      );
      when(
        mockRepo.register(
          name: anyNamed('name'),
          email: anyNamed('email'),
          phone: anyNamed('phone'),
          password: anyNamed('password'),
          address: anyNamed('address'),
        ),
      ).thenAnswer((_) async => const Left(validationFailure));

      final result = await useCase(
        name: 'J',
        email: 'notanemail',
        phone: '123',
        password: 'weak',
        passwordConfirmation: 'weak',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // LogoutUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('LogoutUseCase', () {
    late LogoutUseCase useCase;

    setUp(() => useCase = LogoutUseCase(mockRepo));

    test('returns Right(null) on success', () async {
      when(mockRepo.logout()).thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      verify(mockRepo.logout()).called(1);
    });

    test('returns ServerFailure on failure', () async {
      when(
        mockRepo.logout(),
      ).thenAnswer((_) async => const Left(_serverFailure));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // GetCurrentUserUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetCurrentUserUseCase', () {
    late GetCurrentUserUseCase useCase;

    setUp(() => useCase = GetCurrentUserUseCase(mockRepo));

    test('returns UserEntity on success', () async {
      when(mockRepo.getCurrentUser()).thenAnswer((_) async => Right(_user));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (u) {
        expect(u.id, _user.id);
        expect(u.email, _user.email);
      });
      verify(mockRepo.getCurrentUser()).called(1);
    });

    test('returns UnauthorizedFailure when not logged in', () async {
      when(
        mockRepo.getCurrentUser(),
      ).thenAnswer((_) async => const Left(_unauthorizedFailure));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns ServerFailure on network error', () async {
      when(
        mockRepo.getCurrentUser(),
      ).thenAnswer((_) async => const Left(_serverFailure));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
    });
  });
}
