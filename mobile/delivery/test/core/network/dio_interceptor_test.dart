import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/network/dio_interceptor.dart';
import 'package:courier/core/services/secure_token_service.dart';

/// Custom handler that captures the next() call without using the internal completer
class _TestRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
  }
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  @override
  void next(DioException err) {
    nextCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthInterceptor onRequest', () {
    late AuthInterceptor interceptor;

    setUp(() {
      interceptor = AuthInterceptor(dio: Dio());
      SecureTokenService.enableTestMode();
    });

    tearDown(() {
      SecureTokenService.disableTestMode();
    });

    test('adds Bearer token when auth_token exists', () async {
      SecureTokenService.enableTestMode({'auth_token': 'my-secret-token'});
      final options = RequestOptions(path: '/api/me');
      final handler = _TestRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer my-secret-token');
      expect(options.headers['Accept'], 'application/json');
    });

    test('does not add Authorization header when no token', () async {
      SecureTokenService.enableTestMode({});
      final options = RequestOptions(path: '/api/me');
      final handler = _TestRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], isNull);
      expect(options.headers['Accept'], 'application/json');
    });
  });

  group('AuthInterceptor onError', () {
    late AuthInterceptor interceptor;

    setUp(() {
      interceptor = AuthInterceptor(dio: Dio());
      SecureTokenService.enableTestMode();
    });

    tearDown(() {
      SecureTokenService.disableTestMode();
    });

    test('handles 401 on non-excluded path', () async {
      final options = RequestOptions(path: '/api/me');
      final err = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
        type: DioExceptionType.badResponse,
      );
      final handler = _TestErrorHandler();
      await interceptor.onError(err, handler);
      expect(handler.nextCalled, true);
    });

    test('handles 401 on excluded login path (no session expiry)', () {
      final options = RequestOptions(path: '/auth/login');
      final err = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
        type: DioExceptionType.badResponse,
      );
      final handler = _TestErrorHandler();
      interceptor.onError(err, handler);
      expect(handler.nextCalled, true);
    });

    test('handles 401 on excluded register path', () {
      final options = RequestOptions(path: '/auth/register/courier');
      final err = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
        type: DioExceptionType.badResponse,
      );
      final handler = _TestErrorHandler();
      interceptor.onError(err, handler);
      expect(handler.nextCalled, true);
    });

    test('handles 404 error', () {
      final options = RequestOptions(path: '/api/unknown', baseUrl: 'https://api.test.com');
      final err = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 404, data: {'message': 'Not found'}),
        type: DioExceptionType.badResponse,
      );
      final handler = _TestErrorHandler();
      interceptor.onError(err, handler);
      expect(handler.nextCalled, true);
    });

    test('handles 500 error', () {
      final options = RequestOptions(path: '/api/crash');
      final err = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 500, data: {'message': 'Server Error'}),
        type: DioExceptionType.badResponse,
      );
      final handler = _TestErrorHandler();
      interceptor.onError(err, handler);
      expect(handler.nextCalled, true);
    });

    test('handles connection error', () {
      final options = RequestOptions(path: '/api/me', baseUrl: 'https://api.test.com');
      final err = DioException(requestOptions: options, type: DioExceptionType.connectionError);
      final handler = _TestErrorHandler();
      interceptor.onError(err, handler);
      expect(handler.nextCalled, true);
    });

    test('handles 404 with null data', () {
      final options = RequestOptions(path: '/api/missing', baseUrl: 'https://api.test.com');
      final err = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 404),
        type: DioExceptionType.badResponse,
      );
      final handler = _TestErrorHandler();
      interceptor.onError(err, handler);
      expect(handler.nextCalled, true);
    });

    test('handles 500 with null data', () {
      final options = RequestOptions(path: '/api/crash');
      final err = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 500),
        type: DioExceptionType.badResponse,
      );
      final handler = _TestErrorHandler();
      interceptor.onError(err, handler);
      expect(handler.nextCalled, true);
    });
  });
}
