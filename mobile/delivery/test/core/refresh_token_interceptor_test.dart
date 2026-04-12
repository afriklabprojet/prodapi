import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/core/network/dio_interceptor.dart';
import 'package:courier/core/services/secure_token_service.dart';

/// Tests for Improvement 4: Refresh Token mechanism
/// Tests the AuthInterceptor's 401 handling + token refresh flow.

class MockDio extends Mock implements Dio {}

void main() {
  late Dio mockDio;
  late AuthInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    SecureTokenService.enableTestMode({
      'auth_token': 'old-token',
      'refresh_token': 'valid-refresh-token',
    });
    mockDio = MockDio();
    interceptor = AuthInterceptor(dio: mockDio);
  });

  tearDown(() {
    SecureTokenService.disableTestMode();
  });

  group('AuthInterceptor - onRequest', () {
    test('attaches bearer token from SecureTokenService', () async {
      final options = RequestOptions(path: '/api/deliveries');
      final handler = _MockRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer old-token');
      expect(options.headers['Accept'], 'application/json');
      expect(handler.nextCalled, isTrue);
    });

    test('sends request without auth header when no token exists', () async {
      SecureTokenService.enableTestMode(); // empty store
      final options = RequestOptions(path: '/api/deliveries');
      final handler = _MockRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], isNull);
      expect(options.headers['Accept'], 'application/json');
    });
  });

  group('AuthInterceptor - 401 handling', () {
    test('attempts token refresh on 401 and retries request', () async {
      final requestOptions = RequestOptions(path: '/api/deliveries');
      final error401 = DioException(
        requestOptions: requestOptions,
        response: Response(statusCode: 401, requestOptions: requestOptions),
        type: DioExceptionType.badResponse,
      );

      // Mock the refresh call
      when(
        () => mockDio.post(
          '/auth/refresh',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': {
              'token': 'new-access-token',
              'refresh_token': 'new-refresh-token',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/refresh'),
        ),
      );

      // Mock the retry
      when(() => mockDio.fetch(any())).thenAnswer(
        (_) async => Response(
          data: {'deliveries': []},
          statusCode: 200,
          requestOptions: requestOptions,
        ),
      );

      final handler = _MockErrorHandler();
      await interceptor.onError(error401, handler);

      // Verify token was refreshed
      final newToken = await SecureTokenService.instance.getToken();
      expect(newToken, 'new-access-token');

      final newRefresh = await SecureTokenService.instance.getRefreshToken();
      expect(newRefresh, 'new-refresh-token');

      // Verify the request was retried and resolved
      expect(handler.resolved, isTrue);
    });

    test('does not attempt refresh for excluded paths (/auth/login)', () async {
      final requestOptions = RequestOptions(path: '/auth/login');
      final error401 = DioException(
        requestOptions: requestOptions,
        response: Response(statusCode: 401, requestOptions: requestOptions),
        type: DioExceptionType.badResponse,
      );

      final handler = _MockErrorHandler();
      await interceptor.onError(error401, handler);

      // Should NOT have tried to refresh
      verifyNever(
        () => mockDio.post(
          '/auth/refresh',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
      expect(handler.resolved, isFalse);
    });

    test('does not attempt refresh for /auth/refresh path', () async {
      final requestOptions = RequestOptions(path: '/auth/refresh');
      final error401 = DioException(
        requestOptions: requestOptions,
        response: Response(statusCode: 401, requestOptions: requestOptions),
        type: DioExceptionType.badResponse,
      );

      final handler = _MockErrorHandler();
      await interceptor.onError(error401, handler);

      verifyNever(
        () => mockDio.post(
          '/auth/refresh',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });

    test('expires session when no refresh token available', () async {
      SecureTokenService.enableTestMode({'auth_token': 'old-token'});

      final requestOptions = RequestOptions(path: '/api/deliveries');
      final error401 = DioException(
        requestOptions: requestOptions,
        response: Response(statusCode: 401, requestOptions: requestOptions),
        type: DioExceptionType.badResponse,
      );

      final handler = _MockErrorHandler();
      await interceptor.onError(error401, handler);

      // No refresh token → should not try to call refresh endpoint
      verifyNever(
        () => mockDio.post(
          '/auth/refresh',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });

    test('expires session when refresh endpoint returns error', () async {
      final requestOptions = RequestOptions(path: '/api/deliveries');
      final error401 = DioException(
        requestOptions: requestOptions,
        response: Response(statusCode: 401, requestOptions: requestOptions),
        type: DioExceptionType.badResponse,
      );

      when(
        () => mockDio.post(
          '/auth/refresh',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/auth/refresh'),
          ),
        ),
      );

      final handler = _MockErrorHandler();
      await interceptor.onError(error401, handler);

      // Should not have resolved (refresh failed)
      expect(handler.resolved, isFalse);
    });

    test('does not trigger refresh for non-401 errors', () async {
      final requestOptions = RequestOptions(path: '/api/deliveries');
      final error500 = DioException(
        requestOptions: requestOptions,
        response: Response(statusCode: 500, requestOptions: requestOptions),
        type: DioExceptionType.badResponse,
      );

      final handler = _MockErrorHandler();
      await interceptor.onError(error500, handler);

      verifyNever(
        () => mockDio.post(
          '/auth/refresh',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });
  });

  group('SecureTokenService - Refresh Token', () {
    test('stores and retrieves refresh token', () async {
      SecureTokenService.enableTestMode();

      await SecureTokenService.instance.setRefreshToken('my-refresh');
      final token = await SecureTokenService.instance.getRefreshToken();
      expect(token, 'my-refresh');
    });

    test('removes refresh token', () async {
      SecureTokenService.enableTestMode({'refresh_token': 'to-remove'});

      await SecureTokenService.instance.removeRefreshToken();
      final token = await SecureTokenService.instance.getRefreshToken();
      expect(token, isNull);
    });

    test('returns null when no refresh token set', () async {
      SecureTokenService.enableTestMode();

      final token = await SecureTokenService.instance.getRefreshToken();
      expect(token, isNull);
    });
  });
}

// ── Test helpers ──

class _MockRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
  }
}

class _MockErrorHandler extends ErrorInterceptorHandler {
  bool resolved = false;
  bool rejected = false;

  @override
  void resolve(Response response) {
    resolved = true;
  }

  @override
  void reject(DioException err) {
    rejected = true;
  }

  @override
  void next(DioException err) {
    // passthrough — not resolved
  }
}
