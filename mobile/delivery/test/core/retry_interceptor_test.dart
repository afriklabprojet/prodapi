import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:courier/core/network/retry_interceptor.dart';

/// Helper: call onError inside a guarded zone to catch async errors from the handler,
/// return whether dio.fetch was called (= retry was attempted).
Future<bool> didRetry(RetryInterceptor interceptor, DioException err) async {
  int fetchCallCount = 0;
  interceptor.dio.httpClientAdapter = _CountingAdapter(() => fetchCallCount++);

  final completer = Completer<bool>();

  runZonedGuarded(
    () async {
      try {
        final handler = ErrorInterceptorHandler();
        await interceptor.onError(err, handler);
      } catch (_) {}
      if (!completer.isCompleted) completer.complete(fetchCallCount > 0);
    },
    (error, stack) {
      // Swallow async errors from ErrorInterceptorHandler internals
      if (!completer.isCompleted) completer.complete(fetchCallCount > 0);
    },
  );

  return completer.future;
}

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio();
  });

  DioException makeError(
    DioExceptionType type, {
    int? statusCode,
    int retryCount = 0,
    Map<String, List<String>>? headers,
  }) {
    final opts = RequestOptions(path: '/test');
    if (retryCount > 0) opts.extra['retryCount'] = retryCount;
    return DioException(
      type: type,
      requestOptions: opts,
      response: statusCode != null
          ? Response(
              statusCode: statusCode,
              requestOptions: opts,
              headers: headers != null ? Headers.fromMap(headers) : null,
            )
          : null,
    );
  }

  RetryInterceptor makeInterceptor({int maxRetries = 2}) {
    return RetryInterceptor(
      dio: dio,
      maxRetries: maxRetries,
      initialDelay: const Duration(milliseconds: 1),
      useJitter: false,
    );
  }

  group('RetryInterceptor constructor defaults', () {
    test('maxRetries defaults to 2', () {
      final ri = RetryInterceptor(dio: dio);
      expect(ri.maxRetries, 2);
    });

    test('initialDelay defaults to 1 second', () {
      final ri = RetryInterceptor(dio: dio);
      expect(ri.initialDelay, const Duration(seconds: 1));
    });

    test('maxDelay defaults to 10 seconds', () {
      final ri = RetryInterceptor(dio: dio);
      expect(ri.maxDelay, const Duration(seconds: 10));
    });

    test('backoffMultiplier defaults to 2.0', () {
      final ri = RetryInterceptor(dio: dio);
      expect(ri.backoffMultiplier, 2.0);
    });

    test('useJitter defaults to true', () {
      final ri = RetryInterceptor(dio: dio);
      expect(ri.useJitter, true);
    });

    test('custom values are stored', () {
      final ri = RetryInterceptor(
        dio: dio,
        maxRetries: 5,
        initialDelay: const Duration(milliseconds: 500),
        maxDelay: const Duration(seconds: 60),
        backoffMultiplier: 3.0,
        useJitter: false,
      );
      expect(ri.maxRetries, 5);
      expect(ri.initialDelay, const Duration(milliseconds: 500));
      expect(ri.maxDelay, const Duration(seconds: 60));
      expect(ri.backoffMultiplier, 3.0);
      expect(ri.useJitter, false);
    });
  });

  group('RetryInterceptor onError - shouldRetry', () {
    test('connectionError triggers retry', () async {
      final i = makeInterceptor(maxRetries: 1);
      expect(
        await didRetry(i, makeError(DioExceptionType.connectionError)),
        isTrue,
      );
    });

    test('connectionTimeout does NOT retry', () async {
      final i = makeInterceptor();
      expect(
        await didRetry(i, makeError(DioExceptionType.connectionTimeout)),
        isFalse,
      );
    });

    test('sendTimeout does NOT retry', () async {
      final i = makeInterceptor();
      expect(
        await didRetry(i, makeError(DioExceptionType.sendTimeout)),
        isFalse,
      );
    });

    test('receiveTimeout does NOT retry', () async {
      final i = makeInterceptor();
      expect(
        await didRetry(i, makeError(DioExceptionType.receiveTimeout)),
        isFalse,
      );
    });

    test('500 triggers retry', () async {
      final i = makeInterceptor(maxRetries: 1);
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.badResponse, statusCode: 500),
        ),
        isTrue,
      );
    });

    test('502 triggers retry', () async {
      final i = makeInterceptor(maxRetries: 1);
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.badResponse, statusCode: 502),
        ),
        isTrue,
      );
    });

    test('503 triggers retry', () async {
      final i = makeInterceptor(maxRetries: 1);
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.badResponse, statusCode: 503),
        ),
        isTrue,
      );
    });

    test('504 triggers retry', () async {
      final i = makeInterceptor(maxRetries: 1);
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.badResponse, statusCode: 504),
        ),
        isTrue,
      );
    });

    test('408 triggers retry', () async {
      final i = makeInterceptor(maxRetries: 1);
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.badResponse, statusCode: 408),
        ),
        isTrue,
      );
    });

    test('429 triggers retry', () async {
      final i = makeInterceptor(maxRetries: 1);
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.badResponse, statusCode: 429),
        ),
        isTrue,
      );
    });

    test('400 does NOT retry', () async {
      final i = makeInterceptor();
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.badResponse, statusCode: 400),
        ),
        isFalse,
      );
    });

    test('401 does NOT retry', () async {
      final i = makeInterceptor();
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.badResponse, statusCode: 401),
        ),
        isFalse,
      );
    });

    test('404 does NOT retry', () async {
      final i = makeInterceptor();
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.badResponse, statusCode: 404),
        ),
        isFalse,
      );
    });

    test('501 does NOT retry', () async {
      final i = makeInterceptor();
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.badResponse, statusCode: 501),
        ),
        isFalse,
      );
    });

    test('unknown type with null statusCode does NOT retry', () async {
      final i = makeInterceptor();
      expect(await didRetry(i, makeError(DioExceptionType.unknown)), isFalse);
    });
  });

  group('RetryInterceptor - maxRetries exceeded', () {
    test('does NOT retry when retryCount >= maxRetries', () async {
      final i = makeInterceptor(maxRetries: 2);
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.connectionError, retryCount: 2),
        ),
        isFalse,
      );
    });

    test('does NOT retry when retryCount > maxRetries', () async {
      final i = makeInterceptor(maxRetries: 1);
      expect(
        await didRetry(
          i,
          makeError(DioExceptionType.connectionError, retryCount: 5),
        ),
        isFalse,
      );
    });
  });

  group('RetryInterceptor retryCount tracking', () {
    test('initial retryCount is null in extras', () {
      final opts = RequestOptions(path: '/test');
      expect(opts.extra['retryCount'], isNull);
    });

    test('retryCount can be set and read', () {
      final opts = RequestOptions(path: '/test');
      opts.extra['retryCount'] = 1;
      expect(opts.extra['retryCount'], 1);
    });

    test('retryCount increments on retry attempt', () async {
      final i = makeInterceptor(maxRetries: 1);
      final opts = RequestOptions(path: '/test');
      final err = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: opts,
      );
      await didRetry(i, err);
      expect(opts.extra['retryCount'], 1);
    });
  });

  group('HttpDate', () {
    test('parses ISO 8601 date', () {
      final date = HttpDate.parse('2025-01-15T12:00:00Z');
      expect(date.year, 2025);
      expect(date.month, 1);
      expect(date.day, 15);
    });

    test('throws on invalid date', () {
      expect(() => HttpDate.parse('not-a-date'), throwsFormatException);
    });
  });

  group('RetryInterceptor - Retry-After header', () {
    test('429 with Retry-After seconds triggers retry', () async {
      final i = makeInterceptor(maxRetries: 1);
      final opts = RequestOptions(path: '/test');
      final err = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: opts,
        response: Response(
          statusCode: 429,
          requestOptions: opts,
          headers: Headers.fromMap({
            'retry-after': ['1'],
          }),
        ),
      );
      expect(await didRetry(i, err), isTrue);
    });
  });
}

class _CountingAdapter implements HttpClientAdapter {
  final void Function() onFetch;
  _CountingAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onFetch();
    throw DioException(
      type: DioExceptionType.connectionError,
      requestOptions: options,
    );
  }

  @override
  void close({bool force = false}) {}
}
