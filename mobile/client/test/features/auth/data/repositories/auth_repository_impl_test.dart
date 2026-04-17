import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_client/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:drpharma_client/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:drpharma_client/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:drpharma_client/features/auth/data/models/auth_response_model.dart';
import 'package:drpharma_client/features/auth/data/models/user_model.dart';
import 'package:drpharma_client/core/network/api_client.dart';
import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/core/errors/failures.dart';

// ──────────────────────────────────────────────────────
// Mocks
// ──────────────────────────────────────────────────────
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockApiClient extends Mock implements ApiClient {}

class _FakeUserModel extends Fake implements UserModel {}

// ──────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────
UserModel _makeUserModel({int id = 1}) => UserModel(
  id: id,
  name: 'Test User',
  email: 'test@example.com',
  phone: '+22507',
);

AuthResponseModel _makeAuthResponse({String? firebaseToken}) =>
    AuthResponseModel(
      user: _makeUserModel(),
      token: 'access-token-123',
      firebaseToken: firebaseToken,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUserModel());
  });

  late MockAuthRemoteDataSource mockRemote;
  late MockAuthLocalDataSource mockLocal;
  late MockApiClient mockApi;
  late AuthRepositoryImpl repo;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockLocal = MockAuthLocalDataSource();
    mockApi = MockApiClient();
    repo = AuthRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      apiClient: mockApi,
    );

    // Stub void / future-void methods
    when(() => mockLocal.cacheToken(any())).thenAnswer((_) async {});
    when(() => mockLocal.cacheUser(any())).thenAnswer((_) async {});
    when(() => mockLocal.clearToken()).thenAnswer((_) async {});
    when(() => mockLocal.clearUser()).thenAnswer((_) async {});
    when(() => mockApi.setToken(any())).thenReturn(null);
    when(() => mockApi.clearToken()).thenReturn(null);
  });

  // ──────────────────────────────────────────────────────
  // login
  // ──────────────────────────────────────────────────────
  group('login', () {
    test('success — no firebaseToken', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      final result = await repo.login(email: 'u@e.com', password: 'pass');
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (entity) => expect(entity.token, 'access-token-123'));
    });

    test(
      'success — with firebaseToken (swallowed if Firebase not init)',
      () async {
        when(
          () => mockRemote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => _makeAuthResponse(firebaseToken: 'fb-tok'));

        final result = await repo.login(email: 'u@e.com', password: 'pass');
        expect(result.isRight(), isTrue);
      },
    );

    test('ValidationException → ValidationFailure', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        ValidationException(
          errors: {
            'email': ['Email invalide'],
          },
        ),
      );

      final result = await repo.login(email: 'bad', password: 'x');
      expect(result.isLeft(), isTrue);
      result.fold((f) {
        expect(f, isA<ValidationFailure>());
        final vf = f as ValidationFailure;
        expect(vf.errors['email'], isNotEmpty);
      }, (_) => fail('should be Left'));
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(ServerException(message: 'Server error', statusCode: 500));

      final result = await repo.login(email: 'u@e.com', password: 'p');
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('unexpected'),
      );
    });

    test('NetworkException → NetworkFailure', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(NetworkException(message: 'No connection'));

      final result = await repo.login(email: 'u@e.com', password: 'p');
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('unexpected'),
      );
    });

    test('UnauthorizedException → ServerFailure(401)', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(UnauthorizedException(message: 'Unauthorized'));

      final result = await repo.login(email: 'u@e.com', password: 'p');
      result.fold((f) {
        expect(f, isA<ServerFailure>());
        expect((f as ServerFailure).statusCode, 401);
      }, (_) => fail('unexpected'));
    });
  });

  // ──────────────────────────────────────────────────────
  // register
  // ──────────────────────────────────────────────────────
  group('register', () {
    test('success', () async {
      when(
        () => mockRemote.register(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          address: any(named: 'address'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      final result = await repo.register(
        name: 'Jean',
        email: 'jean@e.com',
        phone: '+22507',
        password: 'Secret1',
      );
      expect(result.isRight(), isTrue);
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockRemote.register(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          address: any(named: 'address'),
        ),
      ).thenThrow(ServerException(message: 'E', statusCode: 422));

      final result = await repo.register(
        name: 'X',
        email: 'x@e.com',
        phone: '+225',
        password: 'Pw1',
      );
      expect(result.isLeft(), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // logout
  // ──────────────────────────────────────────────────────
  group('logout', () {
    test('success with cached token', () async {
      when(
        () => mockLocal.getCachedToken(),
      ).thenAnswer((_) async => 'my-token');
      when(() => mockRemote.logout(any())).thenAnswer((_) async {});

      final result = await repo.logout();
      expect(result.isRight(), isTrue);
      verify(() => mockLocal.clearToken()).called(1);
      verify(() => mockLocal.clearUser()).called(1);
    });

    test('success when no cached token', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => null);

      final result = await repo.logout();
      expect(result.isRight(), isTrue);
    });

    test('ServerException — still clears local data', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => 'tok');
      when(
        () => mockRemote.logout(any()),
      ).thenThrow(ServerException(message: 'E', statusCode: 500));

      final result = await repo.logout();
      expect(result.isLeft(), isTrue);
      verify(() => mockLocal.clearToken()).called(1);
    });
  });

  // ──────────────────────────────────────────────────────
  // getCurrentUser
  // ──────────────────────────────────────────────────────
  group('getCurrentUser', () {
    test('no token → UnauthorizedFailure', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => null);

      final result = await repo.getCurrentUser();
      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('unexpected'),
      );
    });

    test('has cached user → returns it without fetching', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => 'tok');
      when(
        () => mockLocal.getCachedUser(),
      ).thenAnswer((_) async => _makeUserModel());

      final result = await repo.getCurrentUser();
      expect(result.isRight(), isTrue);
      verifyNever(() => mockRemote.getCurrentUser(any()));
    });

    test('no cached user — fetches from server', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => 'tok');
      when(() => mockLocal.getCachedUser()).thenAnswer((_) async => null);
      when(
        () => mockRemote.getCurrentUser(any()),
      ).thenAnswer((_) async => _makeUserModel());

      final result = await repo.getCurrentUser();
      expect(result.isRight(), isTrue);
    });

    test('UnauthorizedException — clears local data', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => 'tok');
      when(() => mockLocal.getCachedUser()).thenAnswer((_) async => null);
      when(
        () => mockRemote.getCurrentUser(any()),
      ).thenThrow(UnauthorizedException(message: 'Expired'));

      final result = await repo.getCurrentUser();
      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('unexpected'),
      );
      verify(() => mockLocal.clearToken()).called(1);
    });

    test('NetworkException with cached user → returns cached user', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => 'tok');
      when(() => mockLocal.getCachedUser()).thenAnswer((_) async => null);
      when(
        () => mockRemote.getCurrentUser(any()),
      ).thenThrow(NetworkException(message: 'Offline'));
      when(
        () => mockLocal.getCachedUser(),
      ).thenAnswer((_) async => _makeUserModel());

      final result = await repo.getCurrentUser();
      expect(result.isRight(), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // isLoggedIn / getToken
  // ──────────────────────────────────────────────────────
  group('isLoggedIn', () {
    test('true when token is non-empty', () async {
      when(
        () => mockLocal.getCachedToken(),
      ).thenAnswer((_) async => 'some-token');
      expect(await repo.isLoggedIn(), isTrue);
    });

    test('false when token is null', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => null);
      expect(await repo.isLoggedIn(), isFalse);
    });

    test('false when token is empty string', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => '');
      expect(await repo.isLoggedIn(), isFalse);
    });
  });

  group('getToken', () {
    test('returns cached token', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => 'abc');
      expect(await repo.getToken(), 'abc');
    });

    test('returns null when missing', () async {
      when(() => mockLocal.getCachedToken()).thenAnswer((_) async => null);
      expect(await repo.getToken(), isNull);
    });
  });

  // ──────────────────────────────────────────────────────
  // updatePassword
  // ──────────────────────────────────────────────────────
  group('updatePassword', () {
    test('success', () async {
      when(
        () => mockRemote.updatePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.updatePassword(
        currentPassword: 'old',
        newPassword: 'New1',
      );
      expect(result.isRight(), isTrue);
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockRemote.updatePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenThrow(ServerException(message: 'Err', statusCode: 422));

      final result = await repo.updatePassword(
        currentPassword: 'old',
        newPassword: 'new',
      );
      expect(result.isLeft(), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // verifyOtp
  // ──────────────────────────────────────────────────────
  group('verifyOtp', () {
    test('success', () async {
      when(
        () => mockRemote.verifyOtp(
          identifier: any(named: 'identifier'),
          otp: any(named: 'otp'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      final result = await repo.verifyOtp(identifier: '+225', otp: '123456');
      expect(result.isRight(), isTrue);
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockRemote.verifyOtp(
          identifier: any(named: 'identifier'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(ServerException(message: 'Bad OTP', statusCode: 400));

      final result = await repo.verifyOtp(identifier: '+225', otp: 'bad');
      expect(result.isLeft(), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // resendOtp
  // ──────────────────────────────────────────────────────
  group('resendOtp', () {
    test('success', () async {
      when(
        () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
      ).thenAnswer((_) async => {'message': 'Sent', 'channel': 'sms'});

      final result = await repo.resendOtp(identifier: '+225');
      expect(result.isRight(), isTrue);
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
      ).thenThrow(ServerException(message: 'E', statusCode: 429));

      final result = await repo.resendOtp(identifier: '+225');
      expect(result.isLeft(), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // forgotPassword
  // ──────────────────────────────────────────────────────
  group('forgotPassword', () {
    test('success', () async {
      when(
        () => mockRemote.forgotPassword(email: any(named: 'email')),
      ).thenAnswer((_) async {});

      final result = await repo.forgotPassword(email: 'u@e.com');
      expect(result.isRight(), isTrue);
    });

    test('NetworkException → NetworkFailure', () async {
      when(
        () => mockRemote.forgotPassword(email: any(named: 'email')),
      ).thenThrow(NetworkException(message: 'No net'));

      final result = await repo.forgotPassword(email: 'u@e.com');
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('unexpected'),
      );
    });
  });

  // ──────────────────────────────────────────────────────
  // verifyResetOtp
  // ──────────────────────────────────────────────────────
  group('verifyResetOtp', () {
    test('success', () async {
      when(
        () => mockRemote.verifyResetOtp(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.verifyResetOtp(email: 'u@e.com', otp: '999999');
      expect(result.isRight(), isTrue);
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockRemote.verifyResetOtp(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(ServerException(message: 'E', statusCode: 400));

      final result = await repo.verifyResetOtp(email: 'u@e.com', otp: 'bad');
      expect(result.isLeft(), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // resetPassword
  // ──────────────────────────────────────────────────────
  group('resetPassword', () {
    test('success', () async {
      when(
        () => mockRemote.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.resetPassword(
        email: 'u@e.com',
        otp: '123456',
        password: 'NewPass1',
        passwordConfirmation: 'NewPass1',
      );
      expect(result.isRight(), isTrue);
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockRemote.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        ),
      ).thenThrow(ServerException(message: 'E', statusCode: 422));

      final result = await repo.resetPassword(
        email: 'u@e.com',
        otp: '123456',
        password: 'x',
        passwordConfirmation: 'x',
      );
      expect(result.isLeft(), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // verifyFirebaseOtp
  // ──────────────────────────────────────────────────────
  group('verifyFirebaseOtp', () {
    test('success — caches token and user', () async {
      when(
        () => mockRemote.verifyFirebaseOtp(
          phone: any(named: 'phone'),
          firebaseUid: any(named: 'firebaseUid'),
          firebaseIdToken: any(named: 'firebaseIdToken'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      final result = await repo.verifyFirebaseOtp(
        phone: '+225',
        firebaseUid: 'uid-123',
        firebaseIdToken: 'id-token-abc',
      );
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (e) => expect(e.token, 'access-token-123'));
    });

    test('ValidationException → ValidationFailure', () async {
      when(
        () => mockRemote.verifyFirebaseOtp(
          phone: any(named: 'phone'),
          firebaseUid: any(named: 'firebaseUid'),
          firebaseIdToken: any(named: 'firebaseIdToken'),
        ),
      ).thenThrow(
        ValidationException(
          errors: {
            'token': ['Token invalide'],
          },
        ),
      );

      final result = await repo.verifyFirebaseOtp(
        phone: '+225',
        firebaseUid: 'uid',
        firebaseIdToken: 'bad',
      );
      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail(''));
    });

    test('ValidationException empty errors → default message', () async {
      when(
        () => mockRemote.verifyFirebaseOtp(
          phone: any(named: 'phone'),
          firebaseUid: any(named: 'firebaseUid'),
          firebaseIdToken: any(named: 'firebaseIdToken'),
        ),
      ).thenThrow(ValidationException(errors: {}));

      final result = await repo.verifyFirebaseOtp(
        phone: '+225',
        firebaseUid: 'uid',
        firebaseIdToken: 'bad',
      );
      result.fold((f) {
        expect(f, isA<ValidationFailure>());
        expect((f as ValidationFailure).message, contains('Firebase'));
      }, (_) => fail(''));
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockRemote.verifyFirebaseOtp(
          phone: any(named: 'phone'),
          firebaseUid: any(named: 'firebaseUid'),
          firebaseIdToken: any(named: 'firebaseIdToken'),
        ),
      ).thenThrow(ServerException(message: 'Err', statusCode: 400));

      final result = await repo.verifyFirebaseOtp(
        phone: '+225',
        firebaseUid: 'uid',
        firebaseIdToken: 'bad',
      );
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail(''));
    });

    test('NetworkException → NetworkFailure', () async {
      when(
        () => mockRemote.verifyFirebaseOtp(
          phone: any(named: 'phone'),
          firebaseUid: any(named: 'firebaseUid'),
          firebaseIdToken: any(named: 'firebaseIdToken'),
        ),
      ).thenThrow(NetworkException(message: 'No net'));

      final result = await repo.verifyFirebaseOtp(
        phone: '+225',
        firebaseUid: 'uid',
        firebaseIdToken: 'tok',
      );
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail(''));
    });

    test('generic exception → ServerFailure', () async {
      when(
        () => mockRemote.verifyFirebaseOtp(
          phone: any(named: 'phone'),
          firebaseUid: any(named: 'firebaseUid'),
          firebaseIdToken: any(named: 'firebaseIdToken'),
        ),
      ).thenThrow(Exception('unexpected'));

      final result = await repo.verifyFirebaseOtp(
        phone: '+225',
        firebaseUid: 'uid',
        firebaseIdToken: 'tok',
      );
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail(''));
    });
  });
}
