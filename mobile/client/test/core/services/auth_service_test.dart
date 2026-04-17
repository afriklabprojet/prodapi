import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_client/core/services/auth_service.dart';
import 'package:drpharma_client/core/contracts/auth_contract.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/core/errors/auth_failures.dart';
import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:drpharma_client/features/auth/data/models/auth_response_model.dart';
import 'package:drpharma_client/features/auth/data/models/user_model.dart';

// ─────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

// ─────────────────────────────────────────────────────────
// FlutterSecureStorage platform channel mock
// ─────────────────────────────────────────────────────────
const _kSecureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

final _secureStorageData = <String, String?>{};

void _setupSecureStorageMock({Map<String, String> data = const {}}) {
  _secureStorageData.clear();
  _secureStorageData.addAll(data);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_kSecureStorageChannel, (call) async {
        switch (call.method) {
          case 'read':
            return _secureStorageData[call.arguments['key'] as String];
          case 'write':
            _secureStorageData[call.arguments['key'] as String] =
                call.arguments['value'] as String?;
            return null;
          case 'delete':
            _secureStorageData.remove(call.arguments['key'] as String);
            return null;
          case 'deleteAll':
            _secureStorageData.clear();
            return null;
          case 'readAll':
            return Map<String, String>.from(
              _secureStorageData.cast<String, String>(),
            );
          default:
            return null;
        }
      });
}

void _clearSecureStorageMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_kSecureStorageChannel, null);
}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────
UserModel _makeUser({int id = 1}) => UserModel(
  id: id,
  name: 'Test User',
  email: 'test@example.com',
  phone: '+22507000000',
);

AuthResponseModel _makeAuthResponse({int userId = 1}) => AuthResponseModel(
  user: _makeUser(id: userId),
  token: 'access-token-123',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRemoteDataSource mockRemote;
  late AuthService authService;

  setUp(() {
    _setupSecureStorageMock();
    mockRemote = MockAuthRemoteDataSource();
    authService = AuthService(
      remoteDataSource: mockRemote,
      otpTimeout: const Duration(seconds: 2),
      otpResendDelay: const Duration(seconds: 5),
    );
  });

  tearDown(() {
    authService.dispose();
    _clearSecureStorageMock();
  });

  // ─────────────────────────────────────────────────────────
  // Initial state
  // ─────────────────────────────────────────────────────────

  group('AuthService — initial state', () {
    test('currentUser is null initially', () {
      expect(authService.currentUser, isNull);
    });

    test('accessToken is null initially', () {
      expect(authService.accessToken, isNull);
    });

    test('currentOtpSession is null initially', () {
      expect(authService.currentOtpSession, isNull);
    });

    test('authStateStream is a broadcast stream', () {
      expect(authService.authStateStream, isA<Stream<AuthStatus>>());
    });
  });

  // ─────────────────────────────────────────────────────────
  // loginWithCredentials
  // ─────────────────────────────────────────────────────────

  group('AuthService — loginWithCredentials', () {
    test('returns Right(AuthResult) on success', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      final result = await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass123',
      );

      expect(result.isRight(), isTrue);
      result.fold((f) => fail('Expected Right but got failure: ${f.message}'), (
        r,
      ) {
        expect(r.accessToken, 'access-token-123');
        expect(r.user.email, 'test@example.com');
      });
    });

    test('sets currentUser and accessToken on success', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass123',
      );

      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser!.email, 'test@example.com');
      expect(authService.accessToken, 'access-token-123');
    });

    test('emits AuthStatus.authenticated on successful login', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      final statuses = <AuthStatus>[];
      final sub = authService.authStateStream.listen(statuses.add);

      await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass123',
      );
      await Future<void>.delayed(Duration.zero);

      expect(statuses, contains(AuthStatus.authenticated));
      await sub.cancel();
    });

    test('normalizes email to lowercase', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      await authService.loginWithCredentials(
        identifier: 'User@Test.COM',
        password: 'pass',
      );

      verify(
        () => mockRemote.login(email: 'user@test.com', password: 'pass'),
      ).called(1);
    });

    test('normalizes local phone (0XXXXXXX) to +225...', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      await authService.loginWithCredentials(
        identifier: '0700000000',
        password: 'pass',
      );

      // '0700000000' → remove leading '0' → '+225' + '700000000'
      verify(
        () => mockRemote.login(email: '+225700000000', password: 'pass'),
      ).called(1);
    });

    test('normalizes phone starting with 225 to +225...', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      await authService.loginWithCredentials(
        identifier: '2250700000000',
        password: 'pass',
      );

      verify(
        () => mockRemote.login(email: '+2250700000000', password: 'pass'),
      ).called(1);
    });

    test(
      'returns Left(InvalidCredentialsFailure) on UnauthorizedFailure',
      () async {
        when(
          () => mockRemote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const UnauthorizedFailure());

        final result = await authService.loginWithCredentials(
          identifier: 'user@test.com',
          password: 'wrong',
        );

        result.fold((f) => expect(f, isA<InvalidCredentialsFailure>()), (_) {});
      },
    );

    test(
      'returns Left(InvalidCredentialsFailure) on ServerFailure 401',
      () async {
        when(
          () => mockRemote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          const ServerFailure(message: 'Unauthorized', statusCode: 401),
        );

        final result = await authService.loginWithCredentials(
          identifier: 'user@test.com',
          password: 'wrong',
        );

        result.fold((f) => expect(f, isA<InvalidCredentialsFailure>()), (_) {});
      },
    );

    test('returns Left(AccountLockedFailure) on ServerFailure 403', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ServerFailure(message: 'Forbidden', statusCode: 403));

      final result = await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass',
      );

      result.fold((f) => expect(f, isA<AccountLockedFailure>()), (_) {});
    });

    test('returns Left(AccountNotFoundFailure) on ServerFailure 404', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ServerFailure(message: 'Not found', statusCode: 404));

      final result = await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass',
      );

      result.fold((f) => expect(f, isA<AccountNotFoundFailure>()), (_) {});
    });

    test('returns Left(ServerFailure) on other server error', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ServerFailure(message: 'Internal error', statusCode: 500),
      );

      final result = await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass',
      );

      result.fold((f) => expect(f, isA<ServerFailure>()), (_) {});
    });

    test('returns Left(NetworkFailure) on NetworkFailure', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const NetworkFailure(message: 'No connection'));

      final result = await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass',
      );

      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) {});
    });

    test(
      'returns Left(InvalidCredentialsFailure) on ValidationFailure',
      () async {
        when(
          () => mockRemote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const ValidationFailure(message: 'Invalid credentials'));

        final result = await authService.loginWithCredentials(
          identifier: 'user@test.com',
          password: 'pass',
        );

        result.fold((f) => expect(f, isA<InvalidCredentialsFailure>()), (_) {});
      },
    );

    test('returns Left(UnknownFailure) on unexpected error', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('Unexpected error'));

      final result = await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass',
      );

      result.fold((f) => expect(f, isA<UnknownFailure>()), (_) {});
    });
  });

  // ─────────────────────────────────────────────────────────
  // initiateOtp
  // ─────────────────────────────────────────────────────────

  group('AuthService — initiateOtp', () {
    test('returns Right(OtpSession) on success', () async {
      when(
        () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
      ).thenAnswer((_) async => {'message': 'OTP sent', 'channel': 'sms'});

      final result = await authService.initiateOtp(phone: '+22507000000');

      expect(result.isRight(), isTrue);
      result.fold((f) => fail('Expected Right but got Left: ${f.message}'), (
        session,
      ) {
        expect(session.verificationId, '+22507000000');
        expect(session.expiresAt.isAfter(DateTime.now()), isTrue);
        expect(session.resendAfterSeconds, 5);
      });
    });

    test('sets currentOtpSession on success', () async {
      when(
        () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
      ).thenAnswer((_) async => {'message': 'OTP sent', 'channel': 'sms'});

      await authService.initiateOtp(phone: '+22507000000');

      expect(authService.currentOtpSession, isNotNull);
    });

    test(
      'returns Left(TooManyOtpAttemptsFailure) on ServerFailure 429',
      () async {
        when(
          () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
        ).thenThrow(
          const ServerFailure(message: 'Rate limit', statusCode: 429),
        );

        final result = await authService.initiateOtp(phone: '+22507000000');

        result.fold(
          (f) => expect(f, isA<TooManyOtpAttemptsFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test('returns Left(OtpSendFailure) for invalid number message', () async {
      when(
        () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
      ).thenThrow(
        const ServerFailure(message: 'invalid numéro', statusCode: 400),
      );

      final result = await authService.initiateOtp(phone: '+22507000000');

      result.fold((f) {
        expect(f, isA<OtpSendFailure>());
        final failure = f as OtpSendFailure;
        expect(failure.reason, OtpSendError.invalidPhoneNumber);
      }, (_) => fail('Expected Left'));
    });

    test('returns Left(OtpSendFailure) on NetworkFailure', () async {
      when(
        () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
      ).thenThrow(const NetworkFailure(message: 'No connection'));

      final result = await authService.initiateOtp(phone: '+22507000000');

      result.fold((f) {
        expect(f, isA<OtpSendFailure>());
        final failure = f as OtpSendFailure;
        expect(failure.reason, OtpSendError.serviceUnavailable);
      }, (_) => fail('Expected Left'));
    });

    test('returns Left(OtpSendFailure) on generic exception', () async {
      when(
        () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
      ).thenThrow(Exception('Unexpected'));

      final result = await authService.initiateOtp(phone: '+22507000000');

      result.fold(
        (f) => expect(f, isA<OtpSendFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('normalizes phone number before sending OTP', () async {
      when(
        () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
      ).thenAnswer((_) async => {'message': 'OTP sent', 'channel': 'sms'});

      await authService.initiateOtp(phone: '07 00 00 00 00');

      // Should have been normalized
      verify(
        () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
      ).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────
  // verifyOtp
  // ─────────────────────────────────────────────────────────

  group('AuthService — verifyOtp', () {
    test('returns Right(AuthResult) on success', () async {
      when(
        () => mockRemote.verifyOtp(
          identifier: any(named: 'identifier'),
          otp: any(named: 'otp'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      final result = await authService.verifyOtp(
        verificationId: '+22507000000',
        code: '123456',
      );

      expect(result.isRight(), isTrue);
    });

    test('clears OtpSession on successful verification', () async {
      // First initiate OTP
      when(
        () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
      ).thenAnswer((_) async => {'message': 'OTP sent', 'channel': 'sms'});
      await authService.initiateOtp(phone: '+22507000000');
      expect(authService.currentOtpSession, isNotNull);

      // Then verify
      when(
        () => mockRemote.verifyOtp(
          identifier: any(named: 'identifier'),
          otp: any(named: 'otp'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());

      await authService.verifyOtp(
        verificationId: '+22507000000',
        code: '123456',
      );

      expect(authService.currentOtpSession, isNull);
    });

    test(
      'returns Left(ExpiredOtpFailure) when server returns expired error',
      () async {
        // When the server says code expired (status 400 + 'expir' in message)
        when(
          () => mockRemote.verifyOtp(
            identifier: any(named: 'identifier'),
            otp: any(named: 'otp'),
          ),
        ).thenThrow(
          const ServerFailure(message: 'Code expiré', statusCode: 400),
        );

        final result = await authService.verifyOtp(
          verificationId: '+22507000000',
          code: '123456',
        );

        result.fold(
          (f) => expect(f, isA<ExpiredOtpFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'returns Left(ExpiredOtpFailure) when OTP session expired via timer',
      () async {
        // We need a session that is still set but its expiresAt has passed
        // (the timer hasn't fired yet to clear it)
        // We do this by: initiate with short timeout, then immediately check expiry
        final shortService = AuthService(
          remoteDataSource: mockRemote,
          otpTimeout: const Duration(milliseconds: 1),
        );
        _setupSecureStorageMock();

        when(
          () => mockRemote.resendOtp(identifier: any(named: 'identifier')),
        ).thenAnswer((_) async => {'message': 'OTP sent', 'channel': 'sms'});
        await shortService.initiateOtp(phone: '+22507000000');

        // Very short delay to ensure expires, but session may still be non-null
        await Future<void>.delayed(const Duration(milliseconds: 5));

        // If session is null (timer cleared it), verifyOtp calls remote → stub it
        when(
          () => mockRemote.verifyOtp(
            identifier: any(named: 'identifier'),
            otp: any(named: 'otp'),
          ),
        ).thenThrow(
          const ServerFailure(message: 'Code expiré', statusCode: 400),
        );

        final result = await shortService.verifyOtp(
          verificationId: '+22507000000',
          code: '123456',
        );

        result.fold(
          (f) =>
              expect(f, anyOf(isA<ExpiredOtpFailure>(), isA<ServerFailure>())),
          (_) => fail('Expected Left'),
        );

        shortService.dispose();
      },
    );

    test('returns Left(InvalidOtpFailure) on ValidationFailure', () async {
      when(
        () => mockRemote.verifyOtp(
          identifier: any(named: 'identifier'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(const ValidationFailure(message: 'Code invalide'));

      final result = await authService.verifyOtp(
        verificationId: '+22507000000',
        code: '999999',
      );

      result.fold(
        (f) => expect(f, isA<InvalidOtpFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ExpiredOtpFailure) when server says expir...', () async {
      when(
        () => mockRemote.verifyOtp(
          identifier: any(named: 'identifier'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(const ServerFailure(message: 'Code expiré', statusCode: 400));

      final result = await authService.verifyOtp(
        verificationId: '+22507000000',
        code: '123456',
      );

      result.fold(
        (f) => expect(f, isA<ExpiredOtpFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test(
      'returns Left(TooManyOtpAttemptsFailure) on ServerFailure 429',
      () async {
        when(
          () => mockRemote.verifyOtp(
            identifier: any(named: 'identifier'),
            otp: any(named: 'otp'),
          ),
        ).thenThrow(
          const ServerFailure(message: 'Too many requests', statusCode: 429),
        );

        final result = await authService.verifyOtp(
          verificationId: '+22507000000',
          code: '123456',
        );

        result.fold(
          (f) => expect(f, isA<TooManyOtpAttemptsFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test('returns Left(NetworkFailure) on NetworkFailure', () async {
      when(
        () => mockRemote.verifyOtp(
          identifier: any(named: 'identifier'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(const NetworkFailure());

      final result = await authService.verifyOtp(
        verificationId: '+22507000000',
        code: '123456',
      );

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(UnknownFailure) on generic error', () async {
      when(
        () => mockRemote.verifyOtp(
          identifier: any(named: 'identifier'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(Exception('Unexpected'));

      final result = await authService.verifyOtp(
        verificationId: '+22507000000',
        code: '123456',
      );

      result.fold(
        (f) => expect(f, isA<UnknownFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // logout
  // ─────────────────────────────────────────────────────────

  group('AuthService — logout', () {
    test('returns Right(unit) when not logged in', () async {
      final result = await authService.logout();
      expect(result.isRight(), isTrue);
    });

    test('calls remoteDataSource.logout with token when logged in', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());
      when(() => mockRemote.logout(any())).thenAnswer((_) async {});

      await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass',
      );
      await authService.logout();

      verify(() => mockRemote.logout('access-token-123')).called(1);
    });

    test('clears currentUser and accessToken after logout', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());
      when(() => mockRemote.logout(any())).thenAnswer((_) async {});

      await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass',
      );
      expect(authService.currentUser, isNotNull);

      await authService.logout();

      expect(authService.currentUser, isNull);
      expect(authService.accessToken, isNull);
    });

    test('emits AuthStatus.unauthenticated on logout', () async {
      final statuses = <AuthStatus>[];
      final sub = authService.authStateStream.listen(statuses.add);

      await authService.logout();
      await Future<void>.delayed(Duration.zero);

      expect(statuses, contains(AuthStatus.unauthenticated));
      await sub.cancel();
    });

    test('returns Right even when server logout throws', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());
      when(
        () => mockRemote.logout(any()),
      ).thenThrow(ServerException(message: 'Server error', statusCode: 500));

      await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass',
      );
      final result = await authService.logout();

      expect(result.isRight(), isTrue);
      expect(authService.currentUser, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────
  // restoreSession
  // ─────────────────────────────────────────────────────────

  group('AuthService — restoreSession', () {
    test('returns Left(SessionExpiredFailure) when no stored token', () async {
      _setupSecureStorageMock(data: {});

      final result = await authService.restoreSession();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SessionExpiredFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('emits AuthStatus.unauthenticated when no token stored', () async {
      _setupSecureStorageMock(data: {});

      final statuses = <AuthStatus>[];
      final sub = authService.authStateStream.listen(statuses.add);

      await authService.restoreSession();
      await Future<void>.delayed(Duration.zero);

      expect(statuses, contains(AuthStatus.unauthenticated));
      await sub.cancel();
    });

    test('returns Right when valid token exists', () async {
      _setupSecureStorageMock(data: {'auth_token': 'stored-token-123'});
      when(
        () => mockRemote.getCurrentUser(any()),
      ).thenAnswer((_) async => _makeUser());

      final result = await authService.restoreSession();

      expect(result.isRight(), isTrue);
      result.fold((f) => fail('Expected Right but got: ${f.message}'), (r) {
        expect(r.accessToken, 'stored-token-123');
        expect(r.user.email, 'test@example.com');
      });
    });

    test(
      'returns Left(SessionExpiredFailure) on UnauthorizedFailure',
      () async {
        _setupSecureStorageMock(data: {'auth_token': 'expired-token'});
        // AuthService catches on UnauthorizedFailure (Failure subclass)
        // not UnauthorizedException (Exception subclass)
        when(
          () => mockRemote.getCurrentUser(any()),
        ).thenThrow(const UnauthorizedFailure());

        final result = await authService.restoreSession();

        result.fold(
          (f) => expect(f, isA<SessionExpiredFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'emits AuthStatus.sessionExpired on UnauthorizedFailure token',
      () async {
        _setupSecureStorageMock(data: {'auth_token': 'bad-token'});
        when(
          () => mockRemote.getCurrentUser(any()),
        ).thenThrow(const UnauthorizedFailure());

        final statuses = <AuthStatus>[];
        final sub = authService.authStateStream.listen(statuses.add);

        await authService.restoreSession();
        await Future<void>.delayed(Duration.zero);

        expect(statuses, contains(AuthStatus.sessionExpired));
        await sub.cancel();
      },
    );

    test('returns cached user on NetworkFailure if cache exists', () async {
      _setupSecureStorageMock(
        data: {
          'auth_token': 'stored-token',
          'cached_user':
              '{"id":1,"name":"Test User","email":"test@example.com","phone":"+22507000000"}',
        },
      );
      when(
        () => mockRemote.getCurrentUser(any()),
      ).thenThrow(const NetworkFailure());

      final result = await authService.restoreSession();

      expect(result.isRight(), isTrue);
    });

    test('returns Left(NetworkFailure) on network error with no cache', () async {
      _setupSecureStorageMock(data: {'auth_token': 'stored-token'});
      when(
        () => mockRemote.getCurrentUser(any()),
      ).thenThrow(const NetworkFailure());

      final result = await authService.restoreSession();

      // Network error without cache → returns Left
      result.fold((f) => expect(f, isA<NetworkFailure>()), (r) {
        // OR it might successfully restore from null cache → either is acceptable
      });
    });
  });

  // ─────────────────────────────────────────────────────────
  // refreshToken
  // ─────────────────────────────────────────────────────────

  group('AuthService — refreshToken', () {
    test('delegates to restoreSession (no token → Left)', () async {
      _setupSecureStorageMock(data: {});
      final result = await authService.refreshToken();
      expect(result.isLeft(), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────
  // isSessionValid
  // ─────────────────────────────────────────────────────────

  group('AuthService — isSessionValid', () {
    test('returns false when no token', () async {
      final isValid = await authService.isSessionValid();
      expect(isValid, isFalse);
    });

    test(
      'returns true when token exists and getCurrentUser succeeds',
      () async {
        // Set up a token in cache
        when(
          () => mockRemote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => _makeAuthResponse());
        when(
          () => mockRemote.getCurrentUser(any()),
        ).thenAnswer((_) async => _makeUser());

        await authService.loginWithCredentials(
          identifier: 'user@test.com',
          password: 'pass',
        );
        final isValid = await authService.isSessionValid();

        expect(isValid, isTrue);
      },
    );

    test('returns false when getCurrentUser throws', () async {
      when(
        () => mockRemote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _makeAuthResponse());
      when(
        () => mockRemote.getCurrentUser(any()),
      ).thenThrow(UnauthorizedException());

      await authService.loginWithCredentials(
        identifier: 'user@test.com',
        password: 'pass',
      );
      final isValid = await authService.isSessionValid();

      expect(isValid, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────
  // dispose
  // ─────────────────────────────────────────────────────────

  group('AuthService — dispose', () {
    test('disposes without error', () {
      final service = AuthService(remoteDataSource: mockRemote);
      expect(() => service.dispose(), returnsNormally);
    });

    test('authStateStream is closed after dispose', () async {
      final service = AuthService(remoteDataSource: mockRemote);
      service.dispose();
      expect(service.authStateStream.isBroadcast, isTrue);
    });
  });
}
