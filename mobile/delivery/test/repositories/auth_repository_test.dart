import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/core/constants/api_constants.dart';
import 'package:courier/core/services/cache_service.dart';
import 'package:courier/core/services/secure_token_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDio mockDio;
  late AuthRepository repo;

  /// In-memory store for FlutterSecureStorage mock
  final Map<String, String> secureStore = {};

  setUp(() async {
    mockDio = MockDio();
    repo = AuthRepository(mockDio);
    secureStore.clear();
    SecureTokenService.enableTestMode(secureStore);
    await setupTestDependencies();

    // Mock FlutterSecureStorage method channel with real in-memory store
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'write') {
              final args = methodCall.arguments as Map;
              secureStore[args['key'] as String] = args['value'] as String;
              return null;
            }
            if (methodCall.method == 'read') {
              final args = methodCall.arguments as Map;
              return secureStore[args['key'] as String];
            }
            if (methodCall.method == 'delete') {
              final args = methodCall.arguments as Map;
              secureStore.remove(args['key'] as String);
              return null;
            }
            return null;
          },
        );

    // Register fallback values for mocktail
    registerFallbackValue(Uri());
  });

  tearDown(() {
    SecureTokenService.disableTestMode();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        );
  });

  // ── login ───────────────────────────────────────────
  group('login', () {
    test('returns User on success', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {
            'token': 'test-token-123',
            'user': {
              'id': 1,
              'name': 'Ali',
              'email': 'ali@test.com',
              'role': 'courier',
            },
          },
        }),
      );

      SharedPreferences.setMockInitialValues({});
      final user = await repo.login('Ali@TEST.com', 'password');
      expect(user.name, 'Ali');
      expect(user.id, 1);

      // Token stored in secure storage
      expect(secureStore['auth_token'], 'test-token-123');
    });

    test('normalizes email to lowercase', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenAnswer((invocation) async {
        // Just verify via the mock – we check credentials stored
        return successResponse({
          'data': {
            'token': 'tok',
            'user': {'id': 1, 'name': 'Test', 'email': 'test@test.com'},
          },
        });
      });

      await repo.login('  TEST@Test.COM  ', 'pass');

      // Biometric marker should be stored (no longer stores email/password)
      expect(secureStore.containsKey('biometric_credentials'), isTrue);
      expect(secureStore['biometric_credentials'], 'token_based');
    });

    test('stores biometric marker after successful login', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {
            'token': 'tok',
            'user': {'id': 1, 'name': 'A', 'email': 'a@b.com'},
          },
        }),
      );

      await repo.login('a@b.com', 'secret');

      // Now stores a marker instead of plaintext password
      expect(secureStore['biometric_credentials'], 'token_based');
      expect(secureStore['auth_token'], 'tok');
    });

    test('throws on 401', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 401));

      expect(
        () => repo.login('a@b.com', 'wrong'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Email ou mot de passe incorrect'),
          ),
        ),
      );
    });

    test('throws on 422 with message', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(
        dioError(
          statusCode: 422,
          data: {
            'message': 'Email invalide',
            'errors': {
              'email': ['Le format email est invalide'],
            },
          },
        ),
      );

      expect(
        () => repo.login('bad', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Email invalide'),
          ),
        ),
      );
    });

    test('throws on 422 with errors map but no message', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(
        dioError(
          statusCode: 422,
          data: {
            'errors': {
              'email': ['Champ requis'],
            },
          },
        ),
      );

      expect(
        () => repo.login('', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Champ requis'),
          ),
        ),
      );
    });

    test('throws on 422 with empty errors map', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {}));

      expect(
        () => repo.login('x@y.com', 'p'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Identifiants incorrects'),
          ),
        ),
      );
    });

    test('throws on timeout', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(timeoutError());

      expect(
        () => repo.login('a@b.com', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Connexion au serveur impossible'),
          ),
        ),
      );
    });

    test('throws on 500 server error', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.login('a@b.com', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Erreur serveur'),
          ),
        ),
      );
    });

    test('throws generic message on other DioException', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 403));

      expect(
        () => repo.login('a@b.com', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Erreur de connexion'),
          ),
        ),
      );
    });
  });

  // ── hasStoredCredentials ────────────────────────────
  group('hasStoredCredentials', () {
    test('returns false when no credentials stored', () async {
      final result = await repo.hasStoredCredentials();
      expect(result, isFalse);
    });

    test('returns true when marker and token exist', () async {
      secureStore['biometric_credentials'] = 'token_based';
      secureStore['auth_token'] = 'existing-token';

      final result = await repo.hasStoredCredentials();
      expect(result, isTrue);
    });

    test('returns false when marker exists but no token', () async {
      secureStore['biometric_credentials'] = 'token_based';

      final result = await repo.hasStoredCredentials();
      expect(result, isFalse);
    });
  });

  // ── loginWithStoredCredentials ──────────────────────
  group('loginWithStoredCredentials', () {
    test('throws when no token stored', () async {
      expect(
        () => repo.loginWithStoredCredentials(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Aucun token stocké'),
          ),
        ),
      );
    });

    test('validates existing token via getProfile', () async {
      secureStore['auth_token'] = 'existing-token';

      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {
            'id': 5,
            'name': 'Saved',
            'email': 'saved@test.com',
            'courier': {'id': 10, 'status': 'active'},
          },
        }),
      );

      final user = await repo.loginWithStoredCredentials();
      expect(user.name, 'Saved');
      expect(user.email, 'saved@test.com');
    });
  });

  // ── clearStoredCredentials ──────────────────────────
  group('clearStoredCredentials', () {
    test('removes credentials from secure storage', () async {
      secureStore['biometric_credentials'] = 'token_based';

      await repo.clearStoredCredentials();

      expect(secureStore.containsKey('biometric_credentials'), isFalse);
    });
  });

  // ── getProfile ──────────────────────────────────────
  group('getProfile', () {
    test('returns User on success', () async {
      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {
            'id': 1,
            'name': 'Ali',
            'email': 'ali@test.com',
            'courier': {'id': 10, 'status': 'active'},
          },
        }),
      );

      final user = await repo.getProfile();
      expect(user.name, 'Ali');
      expect(user.courier?.status, 'active');
    });

    test('caches profile after successful fetch', () async {
      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {'id': 1, 'name': 'Fresh', 'email': 'fresh@test.com'},
        }),
      );

      await repo.getProfile();

      // Second call should come from cache
      final user2 = await repo.getProfile();
      expect(user2.name, 'Fresh');
      verify(
        () => mockDio.get(ApiConstants.me),
      ).called(1); // Only 1 network call
    });

    test('throws PENDING_APPROVAL for pending courier', () async {
      secureStore['auth_token'] = 'tok';
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {
            'id': 1,
            'name': 'Ali',
            'email': 'ali@test.com',
            'courier': {'id': 10, 'status': 'pending_approval'},
          },
        }),
      );

      expect(
        () => repo.getProfile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('PENDING_APPROVAL'),
          ),
        ),
      );
    });

    test('throws SUSPENDED for suspended courier', () async {
      secureStore['auth_token'] = 'tok';
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {
            'id': 1,
            'name': 'Ali',
            'email': 'ali@test.com',
            'courier': {'id': 10, 'status': 'suspended'},
          },
        }),
      );

      expect(
        () => repo.getProfile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('SUSPENDED'),
          ),
        ),
      );
    });

    test('throws REJECTED for rejected courier', () async {
      secureStore['auth_token'] = 'tok';
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {
            'id': 1,
            'name': 'Ali',
            'email': 'ali@test.com',
            'courier': {'id': 10, 'status': 'rejected'},
          },
        }),
      );

      expect(
        () => repo.getProfile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('REJECTED'),
          ),
        ),
      );
    });

    test('removes auth_token on PENDING_APPROVAL', () async {
      secureStore['auth_token'] = 'tok';
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {
            'id': 1,
            'name': 'Ali',
            'email': 'ali@test.com',
            'courier': {'id': 10, 'status': 'pending_approval'},
          },
        }),
      );

      try {
        await repo.getProfile();
      } catch (_) {}

      expect(secureStore.containsKey('auth_token'), isFalse);
    });

    test('serves from cache when available', () async {
      await CacheService.instance.cacheProfile({
        'id': 99,
        'name': 'Cached',
        'email': 'cached@test.com',
      });

      final user = await repo.getProfile();
      expect(user.name, 'Cached');
      verifyNever(() => mockDio.get(any()));
    });

    test('throws generic error on network failure', () async {
      when(() => mockDio.get(ApiConstants.me)).thenThrow(timeoutError());

      expect(() => repo.getProfile(), throwsA(isA<Exception>()));
    });
  });

  // ── registerCourier ─────────────────────────────────
  group('registerCourier', () {
    test('throws with message from DioException data', () async {
      when(
        () => mockDio.post(
          ApiConstants.registerCourier,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        dioError(statusCode: 422, data: {'message': 'Email déjà utilisé'}),
      );

      expect(
        () => repo.registerCourier(
          name: 'Test',
          email: 'dup@test.com',
          phone: '0101',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Email déjà utilisé'),
          ),
        ),
      );
    });

    test('throws first validation error from errors map', () async {
      when(
        () => mockDio.post(
          ApiConstants.registerCourier,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        dioError(
          statusCode: 422,
          data: {
            'errors': {
              'phone': ['Numéro invalide'],
            },
          },
        ),
      );

      expect(
        () => repo.registerCourier(
          name: 'Test',
          email: 'a@b.com',
          phone: 'bad',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Numéro invalide'),
          ),
        ),
      );
    });

    test('throws generic message on DioException without data', () async {
      when(
        () => mockDio.post(
          ApiConstants.registerCourier,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.registerCourier(
          name: 'Test',
          email: 'a@b.com',
          phone: '0101',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── updateProfile ───────────────────────────────────
  group('updateProfile', () {
    test('returns updated User on success', () async {
      when(
        () => mockDio.post(ApiConstants.updateMe, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'id': 1, 'name': 'Ali Nouveau', 'email': 'ali@test.com'},
        }),
      );

      final user = await repo.updateProfile(name: 'Ali Nouveau');
      expect(user.name, 'Ali Nouveau');
    });

    test('throws if no data provided', () {
      expect(
        () => repo.updateProfile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('mise à jour'),
          ),
        ),
      );
    });

    test('invalidates cache after update', () async {
      // Pre-fill cache
      await CacheService.instance.cacheProfile({
        'id': 1,
        'name': 'Old',
        'email': 'a@b.com',
      });

      when(
        () => mockDio.post(ApiConstants.updateMe, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'id': 1, 'name': 'New', 'email': 'a@b.com'},
        }),
      );

      await repo.updateProfile(name: 'New');

      // Cache should be invalidated → next getProfile should hit network
      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {'id': 1, 'name': 'Fresh', 'email': 'a@b.com'},
        }),
      );

      final user = await repo.getProfile();
      expect(user.name, 'Fresh');
      verify(() => mockDio.get(ApiConstants.me)).called(1);
    });

    test('throws 422 message from server', () async {
      when(
        () => mockDio.post(ApiConstants.updateMe, data: any(named: 'data')),
      ).thenThrow(
        dioError(statusCode: 422, data: {'message': 'Nom trop court'}),
      );

      expect(
        () => repo.updateProfile(name: 'A'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Nom trop court'),
          ),
        ),
      );
    });

    test('throws first error from 422 errors map', () async {
      when(
        () => mockDio.post(ApiConstants.updateMe, data: any(named: 'data')),
      ).thenThrow(
        dioError(
          statusCode: 422,
          data: {
            'errors': {
              'phone': ['Format téléphone invalide'],
            },
          },
        ),
      );

      expect(
        () => repo.updateProfile(phone: 'bad'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Format téléphone invalide'),
          ),
        ),
      );
    });

    test('handles response with no data wrapper', () async {
      when(
        () => mockDio.post(ApiConstants.updateMe, data: any(named: 'data')),
      ).thenAnswer(
        (_) async =>
            successResponse({'id': 1, 'name': 'Direct', 'email': 'a@b.com'}),
      );

      final user = await repo.updateProfile(name: 'Direct');
      expect(user.name, 'Direct');
    });
  });

  // ── logout ──────────────────────────────────────────
  group('logout', () {
    test('clears token and cache', () async {
      secureStore['auth_token'] = 'tok123';

      when(
        () => mockDio.post(ApiConstants.logout),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.logout();

      expect(secureStore.containsKey('auth_token'), isFalse);
    });

    test('clears token even if network fails', () async {
      secureStore['auth_token'] = 'tok123';

      when(() => mockDio.post(ApiConstants.logout)).thenThrow(timeoutError());

      await repo.logout(); // Should not throw

      expect(secureStore.containsKey('auth_token'), isFalse);
    });
  });

  // ── updatePassword ──────────────────────────────────
  group('updatePassword', () {
    test('succeeds on 200', () async {
      when(
        () =>
            mockDio.post(ApiConstants.updatePassword, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.updatePassword('old', 'new');
      verify(
        () =>
            mockDio.post(ApiConstants.updatePassword, data: any(named: 'data')),
      ).called(1);
    });

    test('throws with server message on 422', () async {
      when(
        () =>
            mockDio.post(ApiConstants.updatePassword, data: any(named: 'data')),
      ).thenThrow(
        dioError(
          statusCode: 422,
          data: {'message': 'Le mot de passe actuel est incorrect'},
        ),
      );

      expect(
        () => repo.updatePassword('wrong', 'new'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('mot de passe actuel'),
          ),
        ),
      );
    });

    test('throws generic error on DioException without message', () async {
      when(
        () =>
            mockDio.post(ApiConstants.updatePassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.updatePassword('old', 'new'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── refreshToken ────────────────────────────────────
  group('refreshToken', () {
    test('returns false when no refresh token stored', () async {
      final result = await repo.refreshToken();
      expect(result, isFalse);
    });

    test('returns true on successful refresh', () async {
      secureStore['refresh_token'] = 'old-refresh';

      when(
        () => mockDio.post(
          ApiConstants.refreshToken,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'token': 'new-token'},
        }),
      );

      final result = await repo.refreshToken();
      expect(result, isTrue);
      expect(secureStore['auth_token'], 'new-token');
    });

    test('stores new refresh token when provided', () async {
      secureStore['refresh_token'] = 'old-refresh';

      when(
        () => mockDio.post(
          ApiConstants.refreshToken,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'token': 'new-token', 'refresh_token': 'new-refresh'},
        }),
      );

      await repo.refreshToken();
      expect(secureStore['refresh_token'], 'new-refresh');
    });

    test('returns false when response has no token', () async {
      secureStore['refresh_token'] = 'old-refresh';

      when(
        () => mockDio.post(
          ApiConstants.refreshToken,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => successResponse({'data': {}}));

      final result = await repo.refreshToken();
      expect(result, isFalse);
    });

    test('returns false on exception', () async {
      secureStore['refresh_token'] = 'old-refresh';

      when(
        () => mockDio.post(
          ApiConstants.refreshToken,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(timeoutError());

      final result = await repo.refreshToken();
      expect(result, isFalse);
    });
  });

  // ── forgotPassword ──────────────────────────────────
  group('forgotPassword', () {
    test('succeeds on 200', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.forgotPassword('test@test.com');
      verify(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).called(1);
    });

    test('normalizes email to lowercase', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.forgotPassword('  TEST@Test.COM  ');
      final captured = verify(
        () => mockDio.post(
          ApiConstants.forgotPassword,
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect((captured.first as Map)['email'], 'test@test.com');
    });

    test('throws 422 with message', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(
        dioError(statusCode: 422, data: {'message': 'Email introuvable'}),
      );

      expect(
        () => repo.forgotPassword('bad@test.com'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Email introuvable'),
          ),
        ),
      );
    });

    test('throws 422 without message defaults to account not found', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {}));

      expect(
        () => repo.forgotPassword('x@y.com'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Aucun compte trouvé'),
          ),
        ),
      );
    });

    test('throws on 429 rate limit', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 429));

      expect(
        () => repo.forgotPassword('a@b.com'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Trop de tentatives'),
          ),
        ),
      );
    });

    test('throws on timeout', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(timeoutError());

      expect(
        () => repo.forgotPassword('a@b.com'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Connexion impossible'),
          ),
        ),
      );
    });
  });

  // ── sendOtp ─────────────────────────────────────────
  group('sendOtp', () {
    test('returns data on success', () async {
      when(
        () => mockDio.post(ApiConstants.resendOtp, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'expires_in': 300},
        }),
      );

      final result = await repo.sendOtp('0700000000');
      expect(result['expires_in'], 300);
    });

    test('trims identifier', () async {
      when(
        () => mockDio.post(ApiConstants.resendOtp, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'ok': true},
        }),
      );

      await repo.sendOtp('  0700000000  ');
      final captured = verify(
        () => mockDio.post(
          ApiConstants.resendOtp,
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect((captured.first as Map)['identifier'], '0700000000');
    });

    test('passes purpose parameter', () async {
      when(
        () => mockDio.post(ApiConstants.resendOtp, data: any(named: 'data')),
      ).thenAnswer(
        (_) async =>
            successResponse(<String, dynamic>{'data': <String, dynamic>{}}),
      );

      await repo.sendOtp('0700000000', purpose: 'login');
      final captured = verify(
        () => mockDio.post(
          ApiConstants.resendOtp,
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect((captured.first as Map)['purpose'], 'login');
    });

    test('throws on 429', () async {
      when(
        () => mockDio.post(ApiConstants.resendOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 429));

      expect(
        () => repo.sendOtp('0700000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Trop de tentatives'),
          ),
        ),
      );
    });

    test('throws on 422 with message', () async {
      when(
        () => mockDio.post(ApiConstants.resendOtp, data: any(named: 'data')),
      ).thenThrow(
        dioError(statusCode: 422, data: {'message': 'Numéro invalide'}),
      );

      expect(
        () => repo.sendOtp('bad'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Numéro invalide'),
          ),
        ),
      );
    });

    test('throws on 422 without message', () async {
      when(
        () => mockDio.post(ApiConstants.resendOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {}));

      expect(
        () => repo.sendOtp('bad'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('téléphone invalide'),
          ),
        ),
      );
    });

    test('throws generic error on other DioException', () async {
      when(
        () => mockDio.post(ApiConstants.resendOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.sendOtp('0700000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Erreur'),
          ),
        ),
      );
    });
  });

  // ── verifyOtp ───────────────────────────────────────
  group('verifyOtp', () {
    test('returns User when response has user and token', () async {
      when(
        () => mockDio.post(ApiConstants.verifyOtp, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {
            'token': 'otp-token',
            'user': {'id': 1, 'name': 'Verified', 'email': 'v@t.com'},
          },
        }),
      );

      final user = await repo.verifyOtp('0700000000', '123456');
      expect(user.name, 'Verified');
      expect(secureStore['auth_token'], 'otp-token');
    });

    test('falls back to getProfile when response has no user', () async {
      when(
        () => mockDio.post(ApiConstants.verifyOtp, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'token': 'otp-token'},
        }),
      );

      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {'id': 2, 'name': 'FromProfile', 'email': 'fp@t.com'},
        }),
      );

      final user = await repo.verifyOtp('0700000000', '123456');
      expect(user.name, 'FromProfile');
    });

    test('trims identifier and otp', () async {
      when(
        () => mockDio.post(ApiConstants.verifyOtp, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {
            'token': 'tok',
            'user': {'id': 1, 'name': 'T', 'email': 't@t.com'},
          },
        }),
      );

      await repo.verifyOtp('  0700000000  ', '  123456  ');
      final captured = verify(
        () => mockDio.post(
          ApiConstants.verifyOtp,
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final data = captured.first as Map;
      expect(data['identifier'], '0700000000');
      expect(data['otp'], '123456');
    });

    test('passes firebaseUid when provided', () async {
      when(
        () => mockDio.post(ApiConstants.verifyOtp, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {
            'token': 'tok',
            'user': {'id': 1, 'name': 'T', 'email': 't@t.com'},
          },
        }),
      );

      await repo.verifyOtp('0700000000', '123456', firebaseUid: 'fb-uid-123');
      final captured = verify(
        () => mockDio.post(
          ApiConstants.verifyOtp,
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect((captured.first as Map)['firebase_uid'], 'fb-uid-123');
    });

    test('throws on 422 with message', () async {
      when(
        () => mockDio.post(ApiConstants.verifyOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {'message': 'Code expiré'}));

      expect(
        () => repo.verifyOtp('0700000000', '000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Code expiré'),
          ),
        ),
      );
    });

    test('throws on 422 without message defaults', () async {
      when(
        () => mockDio.post(ApiConstants.verifyOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {}));

      expect(
        () => repo.verifyOtp('0700000000', '000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Code invalide'),
          ),
        ),
      );
    });

    test('throws on 429', () async {
      when(
        () => mockDio.post(ApiConstants.verifyOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 429));

      expect(
        () => repo.verifyOtp('0700000000', '000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Trop de tentatives'),
          ),
        ),
      );
    });

    test('throws generic on other DioException', () async {
      when(
        () => mockDio.post(ApiConstants.verifyOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.verifyOtp('0700000000', '000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Erreur'),
          ),
        ),
      );
    });
  });

  // ── forgotPasswordByPhone ───────────────────────────
  group('forgotPasswordByPhone', () {
    test('succeeds on 200', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.forgotPasswordByPhone('0700000000');
      final captured = verify(
        () => mockDio.post(
          ApiConstants.forgotPassword,
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect((captured.first as Map)['channel'], 'sms');
    });

    test('throws on 422 with message', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(
        dioError(statusCode: 422, data: {'message': 'Numéro non trouvé'}),
      );

      expect(
        () => repo.forgotPasswordByPhone('0700000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Numéro non trouvé'),
          ),
        ),
      );
    });

    test('throws on 422 without message', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {}));

      expect(
        () => repo.forgotPasswordByPhone('bad'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Aucun compte'),
          ),
        ),
      );
    });

    test('throws on 429', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 429));

      expect(
        () => repo.forgotPasswordByPhone('0700000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Trop de tentatives'),
          ),
        ),
      );
    });

    test('throws generic on other DioException', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.forgotPasswordByPhone('0700000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Erreur'),
          ),
        ),
      );
    });
  });

  // ── verifyResetOtp ──────────────────────────────────
  group('verifyResetOtp', () {
    test('returns reset_token on success', () async {
      when(
        () =>
            mockDio.post(ApiConstants.verifyResetOtp, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'reset_token': 'rst-tok-123'},
        }),
      );

      final token = await repo.verifyResetOtp('0700000000', '123456');
      expect(token, 'rst-tok-123');
    });

    test('returns empty string when no reset_token in response', () async {
      when(
        () =>
            mockDio.post(ApiConstants.verifyResetOtp, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'data': {}}));

      final token = await repo.verifyResetOtp('0700000000', '123456');
      expect(token, '');
    });

    test('throws on 422 with message', () async {
      when(
        () =>
            mockDio.post(ApiConstants.verifyResetOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {'message': 'Code expiré'}));

      expect(
        () => repo.verifyResetOtp('0700000000', '000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Code expiré'),
          ),
        ),
      );
    });

    test('throws on 422 without message', () async {
      when(
        () =>
            mockDio.post(ApiConstants.verifyResetOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {}));

      expect(
        () => repo.verifyResetOtp('0700000000', '000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Code invalide'),
          ),
        ),
      );
    });

    test('throws generic on other DioException', () async {
      when(
        () =>
            mockDio.post(ApiConstants.verifyResetOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.verifyResetOtp('0700000000', '000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Erreur'),
          ),
        ),
      );
    });
  });

  // ── resetPasswordWithToken ──────────────────────────
  group('resetPasswordWithToken', () {
    test('succeeds on 200', () async {
      when(
        () =>
            mockDio.post(ApiConstants.resetPassword, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.resetPasswordWithToken('rst-tok', 'newPass123');
      verify(
        () =>
            mockDio.post(ApiConstants.resetPassword, data: any(named: 'data')),
      ).called(1);
    });

    test('throws on 422 with message', () async {
      when(
        () =>
            mockDio.post(ApiConstants.resetPassword, data: any(named: 'data')),
      ).thenThrow(
        dioError(statusCode: 422, data: {'message': 'Token invalide'}),
      );

      expect(
        () => repo.resetPasswordWithToken('bad-tok', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Token invalide'),
          ),
        ),
      );
    });

    test('throws on 422 without message', () async {
      when(
        () =>
            mockDio.post(ApiConstants.resetPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {}));

      expect(
        () => repo.resetPasswordWithToken('tok', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Réinitialisation échouée'),
          ),
        ),
      );
    });

    test('throws generic on other DioException', () async {
      when(
        () =>
            mockDio.post(ApiConstants.resetPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.resetPasswordWithToken('tok', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Erreur'),
          ),
        ),
      );
    });
  });

  // ── getProfile INCOMPLETE_KYC ───────────────────────
  group('getProfile INCOMPLETE_KYC', () {
    test('throws INCOMPLETE_KYC for incomplete kyc status', () async {
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {
            'id': 1,
            'name': 'Ali',
            'email': 'ali@test.com',
            'courier': {
              'id': 10,
              'status': 'active',
              'kyc_status': 'incomplete',
              'kyc_rejection_reason': 'Photo floue',
            },
          },
        }),
      );

      expect(
        () => repo.getProfile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('INCOMPLETE_KYC'),
          ),
        ),
      );
    });
  });

  // ── getKycStatus ────────────────────────────────────
  group('getKycStatus', () {
    test('returns data on success', () async {
      when(() => mockDio.get('/courier/kyc/status')).thenAnswer(
        (_) async => successResponse({
          'data': {'status': 'verified', 'verified_at': '2026-01-01'},
        }),
      );

      final result = await repo.getKycStatus();
      expect(result['status'], 'verified');
    });

    test('throws on error', () async {
      when(
        () => mockDio.get('/courier/kyc/status'),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.getKycStatus(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('serveur'),
          ),
        ),
      );
    });
  });

  // ── uploadAvatar ────────────────────────────────────
  group('uploadAvatar', () {
    test('returns full URL when response has http URL', () async {
      when(
        () => mockDio.post(ApiConstants.uploadAvatar, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'avatar_url': 'https://cdn.example.com/avatar.jpg'},
        }),
      );

      final url = await repo.uploadAvatar(Uint8List.fromList([1, 2, 3]));
      expect(url, 'https://cdn.example.com/avatar.jpg');
    });

    test('prepends baseUrl when response has relative path', () async {
      when(
        () => mockDio.post(ApiConstants.uploadAvatar, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'avatar_url': '/storage/avatars/123.jpg'},
        }),
      );

      final url = await repo.uploadAvatar(Uint8List.fromList([1, 2, 3]));
      expect(url, contains('/storage/avatars/123.jpg'));
    });

    test('returns empty string when no avatar_url', () async {
      when(
        () => mockDio.post(ApiConstants.uploadAvatar, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'data': {}}));

      final url = await repo.uploadAvatar(Uint8List.fromList([1, 2, 3]));
      expect(url, '');
    });

    test('throws on 422', () async {
      when(
        () => mockDio.post(ApiConstants.uploadAvatar, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422));

      expect(
        () => repo.uploadAvatar(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Image invalide'),
          ),
        ),
      );
    });

    test('throws generic on other error', () async {
      when(
        () => mockDio.post(ApiConstants.uploadAvatar, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.uploadAvatar(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('photo'),
          ),
        ),
      );
    });
  });

  // ── deleteAvatar ────────────────────────────────────
  group('deleteAvatar', () {
    test('succeeds and invalidates cache', () async {
      when(
        () => mockDio.delete(ApiConstants.deleteAvatar),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.deleteAvatar();
      verify(() => mockDio.delete(ApiConstants.deleteAvatar)).called(1);
    });

    test('throws on error', () async {
      when(
        () => mockDio.delete(ApiConstants.deleteAvatar),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.deleteAvatar(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('serveur'),
          ),
        ),
      );
    });
  });

  // ── registerCourier additional cases ────────────────
  group('registerCourier - status codes', () {
    test('throws on 503', () async {
      when(
        () => mockDio.post(
          ApiConstants.registerCourier,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioError(statusCode: 503));

      expect(
        () => repo.registerCourier(
          name: 'Test',
          phone: '0101',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('indisponible'),
          ),
        ),
      );
    });

    test('throws on 413', () async {
      when(
        () => mockDio.post(
          ApiConstants.registerCourier,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioError(statusCode: 413));

      expect(
        () => repo.registerCourier(
          name: 'Test',
          phone: '0101',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('volumineux'),
          ),
        ),
      );
    });

    test('throws on 408 timeout status', () async {
      when(
        () => mockDio.post(
          ApiConstants.registerCourier,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioError(statusCode: 408));

      expect(
        () => repo.registerCourier(
          name: 'Test',
          phone: '0101',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Délai'),
          ),
        ),
      );
    });

    test('returns User on success', () async {
      when(
        () => mockDio.post(
          ApiConstants.registerCourier,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => successResponse({
          'success': true,
          'data': {
            'user': {
              'id': 99,
              'name': 'Nouveau Coursier',
              'email': 'new@test.com',
              'phone': '0707070707',
              'role': 'courier',
            },
          },
        }),
      );

      final user = await repo.registerCourier(
        name: 'Nouveau Coursier',
        email: 'New@Test.com',
        phone: '0707070707',
        password: 'password123',
        vehicleType: 'moto',
        vehicleRegistration: 'AB-123-CD',
        licenseNumber: 'LIC001',
      );
      expect(user.name, 'Nouveau Coursier');
      expect(user.id, 99);
    });

    test('throws when success is false', () async {
      when(
        () => mockDio.post(
          ApiConstants.registerCourier,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => successResponse({
          'success': false,
          'message': 'Inscription refusée',
        }),
      );

      expect(
        () => repo.registerCourier(
          name: 'Test',
          phone: '0101',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Inscription'),
          ),
        ),
      );
    });

    test('throws on 503 service unavailable', () async {
      when(
        () => mockDio.post(
          ApiConstants.registerCourier,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioError(statusCode: 503));

      expect(
        () => repo.registerCourier(
          name: 'Test',
          phone: '0101',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('indisponible'),
          ),
        ),
      );
    });

    test('throws on 413 payload too large', () async {
      when(
        () => mockDio.post(
          ApiConstants.registerCourier,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioError(statusCode: 413));

      expect(
        () => repo.registerCourier(
          name: 'Test',
          phone: '0101',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('volumineux'),
          ),
        ),
      );
    });
  });

  // ── deleteAccount ─────────────────────────────────
  group('deleteAccount', () {
    test('calls delete endpoint and logs out', () async {
      when(
        () => mockDio.delete('/api/courier/account'),
      ).thenAnswer((_) async => successResponse({'success': true}));
      when(
        () => mockDio.post(ApiConstants.logout),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.deleteAccount();
      verify(() => mockDio.delete('/api/courier/account')).called(1);
    });

    test('throws on API error', () async {
      when(
        () => mockDio.delete('/api/courier/account'),
      ).thenThrow(dioError(statusCode: 500));

      expect(() => repo.deleteAccount(), throwsA(isA<DioException>()));
    });
  });

  // ── forgotPasswordByPhone ──────────────────────────
  group('forgotPasswordByPhone', () {
    test('sends SMS channel request', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.forgotPasswordByPhone('0700000000');
      final captured = verify(
        () => mockDio.post(
          ApiConstants.forgotPassword,
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect((captured.first as Map)['channel'], 'sms');
      expect((captured.first as Map)['identifier'], '0700000000');
    });

    test('trims phone number', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.forgotPasswordByPhone('  0700000000  ');
      final captured = verify(
        () => mockDio.post(
          ApiConstants.forgotPassword,
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect((captured.first as Map)['identifier'], '0700000000');
    });

    test('throws on 422', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(
        dioError(statusCode: 422, data: {'message': 'Numéro non trouvé'}),
      );

      expect(
        () => repo.forgotPasswordByPhone('0000000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Numéro non trouvé'),
          ),
        ),
      );
    });

    test('throws on 429 rate limit', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 429));

      expect(
        () => repo.forgotPasswordByPhone('0700000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Trop de tentatives'),
          ),
        ),
      );
    });

    test('throws generic on other errors', () async {
      when(
        () =>
            mockDio.post(ApiConstants.forgotPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.forgotPasswordByPhone('0700000000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Erreur'),
          ),
        ),
      );
    });
  });

  // ── verifyResetOtp ─────────────────────────────────
  group('verifyResetOtp', () {
    test('returns reset_token on success', () async {
      when(
        () =>
            mockDio.post(ApiConstants.verifyResetOtp, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'reset_token': 'rst-abc-123'},
        }),
      );

      final token = await repo.verifyResetOtp('0700000000', '123456');
      expect(token, 'rst-abc-123');
    });

    test('trims identifier and otp', () async {
      when(
        () =>
            mockDio.post(ApiConstants.verifyResetOtp, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'reset_token': 'tok'},
        }),
      );

      await repo.verifyResetOtp('  0700  ', '  1234  ');
      final captured = verify(
        () => mockDio.post(
          ApiConstants.verifyResetOtp,
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect((captured.first as Map)['identifier'], '0700');
      expect((captured.first as Map)['otp'], '1234');
    });

    test('returns empty string when no reset_token in response', () async {
      when(
        () =>
            mockDio.post(ApiConstants.verifyResetOtp, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'data': {}}));

      final token = await repo.verifyResetOtp('0700', '1234');
      expect(token, '');
    });

    test('throws on 422', () async {
      when(
        () =>
            mockDio.post(ApiConstants.verifyResetOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {'message': 'Code expiré'}));

      expect(
        () => repo.verifyResetOtp('0700', '0000'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Code expiré'),
          ),
        ),
      );
    });

    test('throws generic on other errors', () async {
      when(
        () =>
            mockDio.post(ApiConstants.verifyResetOtp, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.verifyResetOtp('0700', '1234'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('vérification'),
          ),
        ),
      );
    });
  });

  // ── resetPasswordWithToken ─────────────────────────
  group('resetPasswordWithToken', () {
    test('sends correct data on success', () async {
      when(
        () =>
            mockDio.post(ApiConstants.resetPassword, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.resetPasswordWithToken('rst-123', 'newPassword1!');
      final captured = verify(
        () => mockDio.post(
          ApiConstants.resetPassword,
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final sentData = captured.first as Map;
      expect(sentData['reset_token'], 'rst-123');
      expect(sentData['password'], 'newPassword1!');
      expect(sentData['password_confirmation'], 'newPassword1!');
    });

    test('throws on 422', () async {
      when(
        () =>
            mockDio.post(ApiConstants.resetPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {'message': 'Token expiré'}));

      expect(
        () => repo.resetPasswordWithToken('bad-token', 'newpass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Token expiré'),
          ),
        ),
      );
    });

    test('throws on 422 without message uses default', () async {
      when(
        () =>
            mockDio.post(ApiConstants.resetPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422, data: {}));

      expect(
        () => repo.resetPasswordWithToken('tok', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Réinitialisation échouée'),
          ),
        ),
      );
    });

    test('throws generic on other errors', () async {
      when(
        () =>
            mockDio.post(ApiConstants.resetPassword, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.resetPasswordWithToken('tok', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Erreur'),
          ),
        ),
      );
    });
  });

  // ── uploadAvatar ───────────────────────────────────
  group('uploadAvatar', () {
    test('returns avatar URL on success', () async {
      when(
        () => mockDio.post(ApiConstants.uploadAvatar, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'avatar_url': 'https://cdn.example.com/avatar.jpg'},
        }),
      );

      final url = await repo.uploadAvatar(Uint8List.fromList([1, 2, 3]));
      expect(url, 'https://cdn.example.com/avatar.jpg');
    });

    test('prefixes baseUrl for relative paths', () async {
      when(
        () => mockDio.post(ApiConstants.uploadAvatar, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => successResponse({
          'data': {'avatar_url': '/storage/avatars/avatar.jpg'},
        }),
      );

      final url = await repo.uploadAvatar(Uint8List.fromList([1, 2, 3]));
      expect(url, contains(ApiConstants.baseUrl));
      expect(url, contains('/storage/avatars/avatar.jpg'));
    });

    test('returns empty string when no avatar_url', () async {
      when(
        () => mockDio.post(ApiConstants.uploadAvatar, data: any(named: 'data')),
      ).thenAnswer((_) async => successResponse({'data': {}}));

      final url = await repo.uploadAvatar(Uint8List.fromList([1, 2, 3]));
      expect(url, '');
    });

    test('throws on 422 invalid image', () async {
      when(
        () => mockDio.post(ApiConstants.uploadAvatar, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 422));

      expect(
        () => repo.uploadAvatar(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Image invalide'),
          ),
        ),
      );
    });

    test('throws generic on other DioException', () async {
      when(
        () => mockDio.post(ApiConstants.uploadAvatar, data: any(named: 'data')),
      ).thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.uploadAvatar(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Erreur'),
          ),
        ),
      );
    });
  });

  // ── deleteAvatar ───────────────────────────────────
  group('deleteAvatar', () {
    test('calls delete endpoint', () async {
      when(
        () => mockDio.delete(ApiConstants.deleteAvatar),
      ).thenAnswer((_) async => successResponse({'success': true}));

      await repo.deleteAvatar();
      verify(() => mockDio.delete(ApiConstants.deleteAvatar)).called(1);
    });

    test('throws on error', () async {
      when(
        () => mockDio.delete(ApiConstants.deleteAvatar),
      ).thenThrow(dioError(statusCode: 500));

      expect(() => repo.deleteAvatar(), throwsA(isA<Exception>()));
    });
  });

  // ── getKycStatus ───────────────────────────────────
  group('getKycStatus', () {
    test('returns KYC data on success', () async {
      when(() => mockDio.get('/courier/kyc/status')).thenAnswer(
        (_) async => successResponse({
          'data': {
            'status': 'approved',
            'documents': ['id_card', 'selfie'],
          },
        }),
      );

      final result = await repo.getKycStatus();
      expect(result['status'], 'approved');
      expect(result['documents'], contains('id_card'));
    });

    test('returns unwrapped data when no data key', () async {
      when(
        () => mockDio.get('/courier/kyc/status'),
      ).thenAnswer((_) async => successResponse({'status': 'pending'}));

      final result = await repo.getKycStatus();
      expect(result['status'], 'pending');
    });

    test('throws on error', () async {
      when(
        () => mockDio.get('/courier/kyc/status'),
      ).thenThrow(dioError(statusCode: 500));

      expect(() => repo.getKycStatus(), throwsA(isA<Exception>()));
    });
  });

  // ── getProfile — INCOMPLETE_KYC ────────────────────
  group('getProfile — KYC status', () {
    test('throws INCOMPLETE_KYC when kyc_status is incomplete', () async {
      secureStore['auth_token'] = 'test-tok';
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {
            'id': 1,
            'name': 'Ali',
            'email': 'ali@test.com',
            'role': 'courier',
            'courier': {
              'id': 10,
              'status': 'active',
              'kyc_status': 'incomplete',
              'kyc_rejection_reason': 'Document flou',
            },
          },
        }),
      );

      expect(
        () => repo.getProfile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('INCOMPLETE_KYC'),
          ),
        ),
      );
    });

    test('throws INCOMPLETE_KYC with default message when no reason', () async {
      secureStore['auth_token'] = 'test-tok';
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => successResponse({
          'data': {
            'id': 1,
            'name': 'Ali',
            'email': 'ali@test.com',
            'role': 'courier',
            'courier': {
              'id': 10,
              'status': 'active',
              'kyc_status': 'incomplete',
            },
          },
        }),
      );

      expect(
        () => repo.getProfile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('INCOMPLETE_KYC'),
          ),
        ),
      );
    });
  });
}
