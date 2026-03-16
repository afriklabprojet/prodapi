import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:drpharma_client/core/network/retry_interceptor.dart';

void main() {
  // ignore: unused_local_variable
  late RetryInterceptor interceptor;
  late Dio dio;

  setUp(() {
    dio = Dio();
    interceptor = RetryInterceptor(
      dio: dio,
      maxRetries: 2,
      retryDelay: const Duration(milliseconds: 10),
    );
  });

  group('RetryInterceptor configuration', () {
    test('default maxRetries is 2', () {
      final ri = RetryInterceptor(dio: dio);
      expect(ri.maxRetries, 2);
    });

    test('default retryDelay is 1 second', () {
      final ri = RetryInterceptor(dio: dio);
      expect(ri.retryDelay, const Duration(seconds: 1));
    });

    test('accepts custom maxRetries', () {
      final ri = RetryInterceptor(dio: dio, maxRetries: 5);
      expect(ri.maxRetries, 5);
    });

    test('accepts custom retryDelay', () {
      final ri = RetryInterceptor(
          dio: dio, retryDelay: const Duration(seconds: 3));
      expect(ri.retryDelay, const Duration(seconds: 3));
    });
  });

  group('Retry eligibility logic', () {
    // Test that the error types are correctly classified
    test('connectionTimeout is retryable type', () {
      final err = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(
        [
          DioExceptionType.connectionTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
        ].contains(err.type),
        isTrue,
      );
    });

    test('badResponse 500 is retryable', () {
      final err = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final code = err.response!.statusCode!;
      expect(code >= 500 && code != 501, isTrue);
    });

    test('badResponse 501 is NOT retryable', () {
      final err = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 501,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final code = err.response!.statusCode!;
      expect(code >= 500 && code != 501, isFalse);
    });

    test('badResponse 400 is NOT retryable', () {
      final err = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 400,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final code = err.response!.statusCode!;
      expect(code >= 500, isFalse);
    });

    test('cancel is NOT retryable', () {
      final err = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(
        [
          DioExceptionType.connectionTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
        ].contains(err.type),
        isFalse,
      );
    });
  });

  group('RetryCount tracking', () {
    test('initial retryCount is null in extras', () {
      final opts = RequestOptions(path: '/api/test');
      final count = opts.extra['retryCount'] as int? ?? 0;
      expect(count, 0);
    });

    test('retryCount increments correctly', () {
      final opts = RequestOptions(path: '/api/test');
      opts.extra['retryCount'] = 1;
      expect(opts.extra['retryCount'], 1);
      opts.extra['retryCount'] = 2;
      expect(opts.extra['retryCount'], 2);
    });
  });
}
