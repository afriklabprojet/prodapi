import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Intercepteur de retry automatique pour les erreurs réseau et 5xx
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRetryable = _shouldRetry(err);
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (isRetryable && retryCount < maxRetries) {
      if (kDebugMode) {
        debugPrint('🔄 [Retry ${retryCount + 1}/$maxRetries] ${err.requestOptions.path}');
      }

      await Future.delayed(retryDelay * (retryCount + 1));

      try {
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return super.onError(e, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on 5xx server errors (except 501)
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode != 501) {
      return true;
    }

    return false;
  }
}
