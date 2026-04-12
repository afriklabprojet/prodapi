import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_pharmacy/core/network/auth_interceptor.dart';
import 'package:drpharma_pharmacy/features/auth/data/datasources/auth_local_datasource.dart';

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockDio extends Mock implements Dio {}

class FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOptions());
  });

  late MockAuthLocalDataSource mockDataSource;
  late Dio dio;
  late AuthInterceptor interceptor;
  late bool logoutCalled;
  late MockDio mockPlainDio;

  setUp(() {
    mockDataSource = MockAuthLocalDataSource();
    mockPlainDio = MockDio();
    logoutCalled = false;

    interceptor = AuthInterceptor(
      localDataSource: mockDataSource,
      baseUrl: 'http://localhost:8000/api',
      onUnauthorized: () => logoutCalled = true,
      testPlainDio: mockPlainDio,
    );

    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000/api'));
    dio.interceptors.add(interceptor);
    interceptor.attachDio(dio);
  });

  group('AuthInterceptor', () {
    test('injects Bearer token into requests', () async {
      when(
        () => mockDataSource.getToken(),
      ).thenAnswer((_) async => 'test-token-123');

      final options = RequestOptions(path: '/pharmacy/orders');
      final handler = _FakeRequestHandler();

      interceptor.onRequest(options, handler);

      // Wait for async token fetch
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        handler.lastOptions?.headers['Authorization'],
        'Bearer test-token-123',
      );
    });

    test('does not inject token when absent', () async {
      when(() => mockDataSource.getToken()).thenAnswer((_) async => null);

      final options = RequestOptions(path: '/pharmacy/orders');
      final handler = _FakeRequestHandler();

      interceptor.onRequest(options, handler);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(handler.lastOptions?.headers['Authorization'], isNull);
    });

    test('ignores 401 on public routes', () async {
      when(
        () => mockDataSource.getToken(),
      ).thenAnswer((_) async => 'test-token');

      final err = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 401,
        ),
      );

      final handler = _FakeErrorHandler();
      interceptor.onError(err, handler);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(logoutCalled, isFalse);
    });

    test(
      'triggers logout on 401 for protected routes when session invalid',
      () async {
        when(
          () => mockDataSource.getToken(),
        ).thenAnswer((_) async => 'expired-token');
        when(() => mockDataSource.clearAuthData()).thenAnswer((_) async {});

        // Mock the /auth/me validation request to return 401 (session invalid)
        when(
          () => mockPlainDio.get(any(), options: any(named: 'options')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/me'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/me'),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final err = DioException(
          requestOptions: RequestOptions(path: '/pharmacy/orders'),
          response: Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders'),
            statusCode: 401,
          ),
        );

        final handler = _FakeErrorHandler();
        interceptor.onError(err, handler);

        // Wait for refresh attempt + logout
        await Future.delayed(const Duration(milliseconds: 100));

        expect(logoutCalled, isTrue);
        verify(() => mockDataSource.clearAuthData()).called(1);
      },
    );
  });
}

/// Fake handler for testing request interception
class _FakeRequestHandler extends RequestInterceptorHandler {
  RequestOptions? lastOptions;

  @override
  void next(RequestOptions requestOptions) {
    lastOptions = requestOptions;
  }
}

/// Fake handler for testing error interception
class _FakeErrorHandler extends ErrorInterceptorHandler {
  DioException? lastError;
  Response? resolvedResponse;

  @override
  void next(DioException err) {
    lastError = err;
  }

  @override
  void resolve(Response response) {
    resolvedResponse = response;
  }
}
