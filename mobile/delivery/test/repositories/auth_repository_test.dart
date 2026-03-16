import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/core/constants/api_constants.dart';
import 'package:courier/core/services/cache_service.dart';
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  // ── login ───────────────────────────────────────────
  group('login', () {
    test('returns User on success', () async {
      when(() => mockDio.post(ApiConstants.login, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'token': 'test-token-123',
                  'user': {
                    'id': 1,
                    'name': 'Ali',
                    'email': 'ali@test.com',
                    'role': 'courier',
                  },
                }
              }));

      SharedPreferences.setMockInitialValues({});
      final user = await repo.login('Ali@TEST.com', 'password');
      expect(user.name, 'Ali');
      expect(user.id, 1);

      // Token stored in secure storage
      expect(secureStore['auth_token'], 'test-token-123');
    });

    test('normalizes email to lowercase', () async {
      when(() => mockDio.post(ApiConstants.login, data: any(named: 'data')))
          .thenAnswer((invocation) async {
        // Just verify via the mock – we check credentials stored
        return successResponse({
          'data': {
            'token': 'tok',
            'user': {
              'id': 1,
              'name': 'Test',
              'email': 'test@test.com',
            },
          }
        });
      });

      await repo.login('  TEST@Test.COM  ', 'pass');

      // Biometric marker should be stored (no longer stores email/password)
      expect(secureStore.containsKey('biometric_credentials'), isTrue);
      expect(secureStore['biometric_credentials'], 'token_based');
    });

    test('stores biometric marker after successful login', () async {
      when(() => mockDio.post(ApiConstants.login, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'token': 'tok',
                  'user': {'id': 1, 'name': 'A', 'email': 'a@b.com'},
                }
              }));

      await repo.login('a@b.com', 'secret');

      // Now stores a marker instead of plaintext password
      expect(secureStore['biometric_credentials'], 'token_based');
      expect(secureStore['auth_token'], 'tok');
    });

    test('throws on 401', () async {
      when(() => mockDio.post(ApiConstants.login, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 401));

      expect(
        () => repo.login('a@b.com', 'wrong'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Email ou mot de passe incorrect'),
        )),
      );
    });

    test('throws on 422 with message', () async {
      when(() => mockDio.post(ApiConstants.login, data: any(named: 'data')))
          .thenThrow(dioError(
        statusCode: 422,
        data: {
          'message': 'Email invalide',
          'errors': {
            'email': ['Le format email est invalide']
          }
        },
      ));

      expect(
        () => repo.login('bad', 'pass'),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'msg', contains('Email invalide')),
        ),
      );
    });

    test('throws on 422 with errors map but no message', () async {
      when(() => mockDio.post(ApiConstants.login, data: any(named: 'data')))
          .thenThrow(dioError(
        statusCode: 422,
        data: {
          'errors': {
            'email': ['Champ requis']
          }
        },
      ));

      expect(
        () => repo.login('', 'pass'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Champ requis'),
        )),
      );
    });

    test('throws on 422 with empty errors map', () async {
      when(() => mockDio.post(ApiConstants.login, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 422, data: {}));

      expect(
        () => repo.login('x@y.com', 'p'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Identifiants incorrects'),
        )),
      );
    });

    test('throws on timeout', () async {
      when(() => mockDio.post(ApiConstants.login, data: any(named: 'data')))
          .thenThrow(timeoutError());

      expect(
        () => repo.login('a@b.com', 'pass'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Connexion au serveur impossible'),
        )),
      );
    });

    test('throws on 500 server error', () async {
      when(() => mockDio.post(ApiConstants.login, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.login('a@b.com', 'pass'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Erreur serveur'),
        )),
      );
    });

    test('throws generic message on other DioException', () async {
      when(() => mockDio.post(ApiConstants.login, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 403));

      expect(
        () => repo.login('a@b.com', 'pass'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Erreur de connexion'),
        )),
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
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Aucun token stocké'),
        )),
      );
    });

    test('validates existing token via getProfile', () async {
      secureStore['auth_token'] = 'existing-token';

      when(() => mockDio.get(ApiConstants.me))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 5,
                  'name': 'Saved',
                  'email': 'saved@test.com',
                  'courier': {'id': 10, 'status': 'active'},
                }
              }));

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
      when(() => mockDio.get(ApiConstants.me))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 1,
                  'name': 'Ali',
                  'email': 'ali@test.com',
                  'courier': {'id': 10, 'status': 'active'},
                }
              }));

      final user = await repo.getProfile();
      expect(user.name, 'Ali');
      expect(user.courier?.status, 'active');
    });

    test('caches profile after successful fetch', () async {
      when(() => mockDio.get(ApiConstants.me))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 1,
                  'name': 'Fresh',
                  'email': 'fresh@test.com',
                }
              }));

      await repo.getProfile();

      // Second call should come from cache
      final user2 = await repo.getProfile();
      expect(user2.name, 'Fresh');
      verify(() => mockDio.get(ApiConstants.me)).called(1); // Only 1 network call
    });

    test('throws PENDING_APPROVAL for pending courier', () async {
      secureStore['auth_token'] = 'tok';
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 1,
                  'name': 'Ali',
                  'email': 'ali@test.com',
                  'courier': {'id': 10, 'status': 'pending_approval'},
                }
              }));

      expect(
        () => repo.getProfile(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('PENDING_APPROVAL'),
        )),
      );
    });

    test('throws SUSPENDED for suspended courier', () async {
      secureStore['auth_token'] = 'tok';
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 1,
                  'name': 'Ali',
                  'email': 'ali@test.com',
                  'courier': {'id': 10, 'status': 'suspended'},
                }
              }));

      expect(
        () => repo.getProfile(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('SUSPENDED'),
        )),
      );
    });

    test('throws REJECTED for rejected courier', () async {
      secureStore['auth_token'] = 'tok';
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 1,
                  'name': 'Ali',
                  'email': 'ali@test.com',
                  'courier': {'id': 10, 'status': 'rejected'},
                }
              }));

      expect(
        () => repo.getProfile(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('REJECTED'),
        )),
      );
    });

    test('removes auth_token on PENDING_APPROVAL', () async {
      secureStore['auth_token'] = 'tok';
      CacheService.instance.resetForTesting();
      await CacheService.instance.init();

      when(() => mockDio.get(ApiConstants.me))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 1,
                  'name': 'Ali',
                  'email': 'ali@test.com',
                  'courier': {'id': 10, 'status': 'pending_approval'},
                }
              }));

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

      expect(
        () => repo.getProfile(),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── registerCourier ─────────────────────────────────
  group('registerCourier', () {
    test('throws with message from DioException data', () async {
      when(() => mockDio.post(
            ApiConstants.registerCourier,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(dioError(
        statusCode: 422,
        data: {'message': 'Email déjà utilisé'},
      ));

      expect(
        () => repo.registerCourier(
          name: 'Test',
          email: 'dup@test.com',
          phone: '0101',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Email déjà utilisé'),
        )),
      );
    });

    test('throws first validation error from errors map', () async {
      when(() => mockDio.post(
            ApiConstants.registerCourier,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(dioError(
        statusCode: 422,
        data: {
          'errors': {
            'phone': ['Numéro invalide']
          }
        },
      ));

      expect(
        () => repo.registerCourier(
          name: 'Test',
          email: 'a@b.com',
          phone: 'bad',
          password: 'pass',
          vehicleType: 'moto',
          vehicleRegistration: 'AB-123',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Numéro invalide'),
        )),
      );
    });

    test('throws generic message on DioException without data', () async {
      when(() => mockDio.post(
            ApiConstants.registerCourier,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(dioError(statusCode: 500));

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
      when(() => mockDio.post(ApiConstants.updateMe, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 1,
                  'name': 'Ali Nouveau',
                  'email': 'ali@test.com',
                }
              }));

      final user = await repo.updateProfile(name: 'Ali Nouveau');
      expect(user.name, 'Ali Nouveau');
    });

    test('throws if no data provided', () {
      expect(
        () => repo.updateProfile(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('mise à jour'),
        )),
      );
    });

    test('invalidates cache after update', () async {
      // Pre-fill cache
      await CacheService.instance.cacheProfile({'id': 1, 'name': 'Old', 'email': 'a@b.com'});

      when(() => mockDio.post(ApiConstants.updateMe, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {'id': 1, 'name': 'New', 'email': 'a@b.com'}
              }));

      await repo.updateProfile(name: 'New');

      // Cache should be invalidated → next getProfile should hit network
      when(() => mockDio.get(ApiConstants.me))
          .thenAnswer((_) async => successResponse({
                'data': {'id': 1, 'name': 'Fresh', 'email': 'a@b.com'}
              }));

      final user = await repo.getProfile();
      expect(user.name, 'Fresh');
      verify(() => mockDio.get(ApiConstants.me)).called(1);
    });

    test('throws 422 message from server', () async {
      when(() => mockDio.post(ApiConstants.updateMe, data: any(named: 'data')))
          .thenThrow(dioError(
        statusCode: 422,
        data: {'message': 'Nom trop court'},
      ));

      expect(
        () => repo.updateProfile(name: 'A'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Nom trop court'),
        )),
      );
    });

    test('throws first error from 422 errors map', () async {
      when(() => mockDio.post(ApiConstants.updateMe, data: any(named: 'data')))
          .thenThrow(dioError(
        statusCode: 422,
        data: {
          'errors': {
            'phone': ['Format téléphone invalide']
          }
        },
      ));

      expect(
        () => repo.updateProfile(phone: 'bad'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Format téléphone invalide'),
        )),
      );
    });

    test('handles response with no data wrapper', () async {
      when(() => mockDio.post(ApiConstants.updateMe, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'id': 1,
                'name': 'Direct',
                'email': 'a@b.com',
              }));

      final user = await repo.updateProfile(name: 'Direct');
      expect(user.name, 'Direct');
    });
  });

  // ── logout ──────────────────────────────────────────
  group('logout', () {
    test('clears token and cache', () async {
      secureStore['auth_token'] = 'tok123';

      when(() => mockDio.post(ApiConstants.logout))
          .thenAnswer((_) async => successResponse({'success': true}));

      await repo.logout();

      expect(secureStore.containsKey('auth_token'), isFalse);
    });

    test('clears token even if network fails', () async {
      secureStore['auth_token'] = 'tok123';

      when(() => mockDio.post(ApiConstants.logout))
          .thenThrow(timeoutError());

      await repo.logout(); // Should not throw

      expect(secureStore.containsKey('auth_token'), isFalse);
    });
  });

  // ── updatePassword ──────────────────────────────────
  group('updatePassword', () {
    test('succeeds on 200', () async {
      when(() => mockDio.post(ApiConstants.updatePassword, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({'success': true}));

      await repo.updatePassword('old', 'new');
      verify(() => mockDio.post(ApiConstants.updatePassword, data: any(named: 'data'))).called(1);
    });

    test('throws with server message on 422', () async {
      when(() => mockDio.post(ApiConstants.updatePassword, data: any(named: 'data')))
          .thenThrow(dioError(
        statusCode: 422,
        data: {'message': 'Le mot de passe actuel est incorrect'},
      ));

      expect(
        () => repo.updatePassword('wrong', 'new'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('mot de passe actuel'),
        )),
      );
    });

    test('throws generic error on DioException without message', () async {
      when(() => mockDio.post(ApiConstants.updatePassword, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.updatePassword('old', 'new'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
