import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/auth/domain/entities/auth_response_entity.dart';
import 'package:drpharma_client/features/auth/domain/entities/user_entity.dart';
import 'package:drpharma_client/features/auth/domain/repositories/auth_repository.dart';
import 'package:drpharma_client/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:drpharma_client/features/auth/domain/usecases/login_usecase.dart';
import 'package:drpharma_client/features/auth/domain/usecases/logout_usecase.dart';
import 'package:drpharma_client/features/auth/domain/usecases/register_usecase.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_notifier.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockLoginUseCase mockLogin;
  late MockRegisterUseCase mockRegister;
  late MockLogoutUseCase mockLogout;
  late MockGetCurrentUserUseCase mockGetCurrentUser;
  late MockAuthRepository mockAuthRepo;
  late AuthNotifier notifier;

  final testUser = UserEntity(
    id: 1,
    name: 'Kofi Mensah',
    email: 'kofi@example.com',
    phone: '+2250700000001',
    createdAt: DateTime(2024, 1, 1),
  );

  final testAuthResponse = AuthResponseEntity(
    user: testUser,
    token: 'test-token-abc',
  );

  // CRITICAL: stub before construction (constructor calls _checkAuthStatus())
  AuthNotifier _buildNotifier({bool checkAuthReturnsUser = false}) {
    when(() => mockGetCurrentUser()).thenAnswer(
      (_) async => checkAuthReturnsUser
          ? Right(testUser)
          : Left(const UnauthorizedFailure()),
    );
    return AuthNotifier(
      loginUseCase: mockLogin,
      registerUseCase: mockRegister,
      logoutUseCase: mockLogout,
      getCurrentUserUseCase: mockGetCurrentUser,
      authRepository: mockAuthRepo,
    );
  }

  setUp(() {
    mockLogin = MockLoginUseCase();
    mockRegister = MockRegisterUseCase();
    mockLogout = MockLogoutUseCase();
    mockGetCurrentUser = MockGetCurrentUserUseCase();
    mockAuthRepo = MockAuthRepository();
  });

  tearDown(() {
    notifier.dispose();
  });

  group('AuthNotifier — initial state & _checkAuthStatus', () {
    test('initial state is AuthStatus.initial before async check finishes', () {
      notifier = _buildNotifier();
      expect(notifier.state.status, AuthStatus.initial);
    });

    test(
      '_checkAuthStatus sets unauthenticated when getCurrentUser fails',
      () async {
        notifier = _buildNotifier(checkAuthReturnsUser: false);
        await Future.microtask(() {});
        expect(notifier.state.status, AuthStatus.unauthenticated);
      },
    );

    test(
      '_checkAuthStatus sets authenticated when getCurrentUser succeeds',
      () async {
        notifier = _buildNotifier(checkAuthReturnsUser: true);
        await Future.microtask(() {});
        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user, testUser);
      },
    );
  });

  group('AuthNotifier — login', () {
    setUp(() {
      notifier = _buildNotifier();
    });

    test('login success sets authenticated state with user', () async {
      when(
        () => mockLogin(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testAuthResponse));

      await notifier.login(email: 'kofi@example.com', password: 'password123');

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user, testUser);
      expect(notifier.state.errorMessage, isNull);
    });

    test('login sets loading state then resolves', () async {
      final states = <AuthStatus>[];
      notifier.addListener((s) => states.add(s.status));

      when(
        () => mockLogin(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testAuthResponse));

      await notifier.login(email: 'kofi@example.com', password: 'pass');
      expect(states, contains(AuthStatus.loading));
    });

    test(
      'login with ValidationFailure sets error with validationErrors',
      () async {
        const failure = ValidationFailure(
          message: 'Champs invalides',
          errors: {
            'email': ['Email invalide'],
            'password': ['Trop court'],
          },
        );
        when(
          () => mockLogin(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Left(failure));

        await notifier.login(email: 'bad', password: '123');

        expect(notifier.state.status, AuthStatus.error);
        expect(notifier.state.errorMessage, 'Champs invalides');
        expect(notifier.state.validationErrors, isNotNull);
        expect(
          notifier.state.validationErrors!['email'],
          contains('Email invalide'),
        );
      },
    );

    test(
      'login with ServerFailure sets error without validationErrors',
      () async {
        const failure = ServerFailure(
          message: 'Identifiants incorrects',
          statusCode: 401,
        );
        when(
          () => mockLogin(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Left(failure));

        await notifier.login(email: 'x@x.com', password: 'wrong');

        expect(notifier.state.status, AuthStatus.error);
        expect(notifier.state.errorMessage, 'Identifiants incorrects');
        expect(notifier.state.validationErrors, isNull);
      },
    );

    test(
      'login with NetworkFailure sets error without validationErrors',
      () async {
        const failure = NetworkFailure();
        when(
          () => mockLogin(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Left(failure));

        await notifier.login(email: 'x@x.com', password: 'pass');

        expect(notifier.state.status, AuthStatus.error);
        expect(notifier.state.validationErrors, isNull);
      },
    );
  });

  group('AuthNotifier — register', () {
    setUp(() {
      notifier = _buildNotifier();
    });

    test('register success sets authenticated state', () async {
      when(
        () => mockRegister(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
          address: any(named: 'address'),
        ),
      ).thenAnswer((_) async => Right(testAuthResponse));

      await notifier.register(
        name: 'Kofi Mensah',
        email: 'kofi@example.com',
        phone: '+2250700000001',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user, testUser);
    });

    test('register with ValidationFailure sets error with fields', () async {
      const failure = ValidationFailure(
        message: 'Données invalides',
        errors: {
          'phone': ['Numéro déjà utilisé'],
        },
      );
      when(
        () => mockRegister(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
          address: any(named: 'address'),
        ),
      ).thenAnswer((_) async => Left(failure));

      await notifier.register(
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        password: '123456',
        passwordConfirmation: '123456',
      );

      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.validationErrors, contains('phone'));
    });

    test(
      'register with ServerFailure sets error without validationErrors',
      () async {
        const failure = ServerFailure(
          message: 'Erreur serveur',
          statusCode: 500,
        );
        when(
          () => mockRegister(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
            passwordConfirmation: any(named: 'passwordConfirmation'),
            address: any(named: 'address'),
          ),
        ).thenAnswer((_) async => Left(failure));

        await notifier.register(
          name: 'Kofi',
          email: 'k@k.com',
          phone: '+22507',
          password: '123456',
          passwordConfirmation: '123456',
        );

        expect(notifier.state.status, AuthStatus.error);
        expect(notifier.state.validationErrors, isNull);
      },
    );
  });

  group('AuthNotifier — logout', () {
    setUp(() {
      notifier = _buildNotifier();
    });

    test('logout success sets unauthenticated', () async {
      when(() => mockLogout()).thenAnswer((_) async => const Right(null));

      await notifier.logout();

      expect(notifier.state.status, AuthStatus.unauthenticated);
    });

    test('logout failure sets error state', () async {
      const failure = ServerFailure(
        message: 'Erreur de déconnexion',
        statusCode: 500,
      );
      when(() => mockLogout()).thenAnswer((_) async => Left(failure));

      await notifier.logout();

      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.errorMessage, 'Erreur de déconnexion');
    });
  });

  group('AuthNotifier — clearAuthStateSync', () {
    setUp(() {
      notifier = _buildNotifier();
    });

    test('clearAuthStateSync immediately sets unauthenticated', () {
      // stub logoutUseCase for fire-and-forget background call
      when(() => mockLogout()).thenAnswer((_) async => const Right(null));

      notifier.clearAuthStateSync();

      expect(notifier.state.status, AuthStatus.unauthenticated);
    });
  });

  group('AuthNotifier — clearError', () {
    setUp(() {
      notifier = _buildNotifier();
    });

    test('clearError when in error state sets unauthenticated', () async {
      const failure = ServerFailure(message: 'err', statusCode: 401);
      when(
        () => mockLogin(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Left(failure));

      await notifier.login(email: 'x@x.com', password: 'wrong');
      expect(notifier.state.status, AuthStatus.error);

      notifier.clearError();
      expect(notifier.state.status, AuthStatus.unauthenticated);
    });

    test('clearError when NOT in error state does nothing', () async {
      await Future.microtask(() {});
      expect(notifier.state.status, AuthStatus.unauthenticated);

      notifier.clearError(); // should no-op
      expect(notifier.state.status, AuthStatus.unauthenticated);
    });
  });
}
