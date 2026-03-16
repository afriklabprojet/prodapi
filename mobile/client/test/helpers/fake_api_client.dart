import 'package:dio/dio.dart';
import 'package:drpharma_client/core/network/api_client.dart';

/// A fake ApiClient that returns empty successful responses without making
/// any real HTTP calls. This prevents Dio from creating Timer objects in
/// Flutter's FakeAsync test zone, which would cause "timersPending" assertions.
///
/// Usage in tests:
/// ```dart
/// ProviderScope(
///   overrides: [
///     sharedPreferencesProvider.overrideWithValue(sharedPreferences),
///     apiClientProvider.overrideWithValue(FakeApiClient()),
///   ],
///   child: MaterialApp(home: const MyPage()),
/// )
/// ```
class FakeApiClient extends ApiClient {
  FakeApiClient() : super(enableCertificatePinning: false);

  Response _emptyResponse(String path) {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'data': <String, dynamic>{},
        'message': 'ok',
      },
    );
  }

  Response _emptyListResponse(String path) {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'data': <dynamic>[],
        'message': 'ok',
      },
    );
  }

  Response _notificationsResponse(String path) {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'data': {
          'notifications': <dynamic>[],
          'unread_count': 0,
          'pagination': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 20,
            'total': 0,
          },
        },
        'message': 'ok',
      },
    );
  }

  /// Returns an appropriate mock response based on the path pattern.
  Response _mockResponse(String path) {
    // Notifications have a specific nested structure
    if (path.contains('notifications')) {
      return _notificationsResponse(path);
    }

    // FAQ endpoints return an empty list (fallback defaults will be used)
    if (path.contains('faq')) {
      return _emptyListResponse(path);
    }

    // Paths that typically return lists
    if (path.contains('products') ||
        path.contains('pharmacies') ||
        path.contains('orders') ||
        path.contains('addresses') ||
        path.contains('prescriptions')) {
      // Detail endpoints (e.g., /products/123) return an object
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      final lastSegment = segments.isNotEmpty ? segments.last : '';
      if (int.tryParse(lastSegment) != null) {
        return _emptyResponse(path);
      }
      return _emptyListResponse(path);
    }
    return _emptyResponse(path);
  }

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _mockResponse(path);
  }

  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _emptyResponse(path);
  }

  @override
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _emptyResponse(path);
  }

  @override
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _emptyResponse(path);
  }

  @override
  Future<Response> uploadMultipart(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    return _emptyResponse(path);
  }
}
