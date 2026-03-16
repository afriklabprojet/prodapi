import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/core/services/cache_service.dart';

// ── Mock classes ──────────────────────────────────────

class MockDio extends Mock implements Dio {}

// ── Response factories ────────────────────────────────

/// Construit une [Response] Dio de succès.
Response<dynamic> successResponse(dynamic data, {int statusCode = 200}) {
  return Response(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: ''),
  );
}

/// Construit une [DioException] avec un status code et body.
DioException dioError({
  required int statusCode,
  dynamic data,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  return DioException(
    requestOptions: RequestOptions(path: ''),
    response: Response(
      statusCode: statusCode,
      data: data,
      requestOptions: RequestOptions(path: ''),
    ),
    type: type,
  );
}

/// Construit une [DioException] de timeout réseau.
DioException timeoutError() {
  return DioException(
    requestOptions: RequestOptions(path: ''),
    type: DioExceptionType.connectionTimeout,
  );
}

// ── Setup helpers ─────────────────────────────────────

/// Initialise CacheService in test mode (in-memory store, no platform calls).
Future<void> setupTestDependencies() async {
  CacheService.instance.resetForTesting();
  await CacheService.instance.init();
}
