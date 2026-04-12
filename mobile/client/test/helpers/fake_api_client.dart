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
      data: {'data': <String, dynamic>{}, 'message': 'ok'},
    );
  }

  Response _emptyListResponse(String path) {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'data': <dynamic>[], 'message': 'ok'},
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

  Response _profileResponse(String path) {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'data': {
          'id': 1,
          'name': 'Utilisateur Test',
          'email': 'test@drpharma.app',
          'phone': '+2250700000000',
          'total_orders': 3,
          'completed_orders': 2,
          'total_spent': 12500,
          'created_at': '2026-01-01T00:00:00.000Z',
        },
        'message': 'ok',
      },
    );
  }

  Response _orderResponse(String path, int orderId) {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'data': {
          'id': orderId,
          'reference': 'CMD-$orderId',
          'status': 'pending',
          'payment_status': 'pending',
          'payment_mode': 'cash',
          'pharmacy_id': 1,
          'items': <dynamic>[],
          'items_count': 0,
          'subtotal': 0.0,
          'delivery_fee': 0.0,
          'total_amount': 0.0,
          'currency': 'XOF',
          'delivery_address': '',
          'created_at': '2024-01-01T00:00:00.000Z',
        },
        'message': 'ok',
      },
    );
  }

  Response _prescriptionResponse(String path, int prescriptionId) {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'data': {
          'id': prescriptionId,
          'status': 'pending',
          'notes': 'Test prescription notes',
          'images': <String>['https://example.com/prescription.jpg'],
          'rejection_reason': null,
          'quote_amount': null,
          'pharmacy_notes': null,
          'created_at': '2024-01-01T00:00:00.000Z',
          'validated_at': null,
          'order_id': null,
          'order_reference': null,
          'source': 'upload',
          'fulfillment_status': 'none',
          'dispensing_count': 0,
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

    // Profile endpoints need a minimal user payload for widget tests.
    if (path.contains('/auth/me') || path.contains('profile')) {
      return _profileResponse(path);
    }

    // Paths that typically return lists
    if (path.contains('products') ||
        path.contains('pharmacies') ||
        path.contains('orders') ||
        path.contains('addresses') ||
        path.contains('prescriptions')) {
      // Detail endpoints (e.g., /products/123, /orders/123) return an object
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      final lastSegment = segments.isNotEmpty ? segments.last : '';
      final id = int.tryParse(lastSegment);
      if (id != null) {
        // Return a proper order response to prevent Null != num errors
        if (path.contains('orders')) {
          return _orderResponse(path, id);
        }
        // Return a proper prescription response to prevent Null != int errors
        if (path.contains('prescriptions')) {
          return _prescriptionResponse(path, id);
        }
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
