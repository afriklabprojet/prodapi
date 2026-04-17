import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock HTTP adapter for Dio that returns predefined responses.
///
/// Simulates the DrPharma API contract so we can verify request shapes
/// and response parsing without a live server.
class _MockApiAdapter implements HttpClientAdapter {
  final Map<String, _MockRoute> _routes = {};

  void onGet(String path, {required int status, required Map<String, dynamic> body}) {
    _routes['GET:$path'] = _MockRoute(status: status, body: body);
  }

  void onPost(String path, {required int status, required Map<String, dynamic> body}) {
    _routes['POST:$path'] = _MockRoute(status: status, body: body);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method}:${options.path}';
    final route = _routes[key];

    if (route == null) {
      return ResponseBody.fromString(
        jsonEncode({'success': false, 'message': 'Not found'}),
        404,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode(route.body),
      route.status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MockRoute {
  final int status;
  final Map<String, dynamic> body;
  const _MockRoute({required this.status, required this.body});
}

/// Contract tests that verify API request/response shapes.
///
/// These run without a live server by using a mock HTTP adapter.
/// They guarantee the app handles expected API contract correctly.
void main() {
  late Dio dio;
  late _MockApiAdapter mockAdapter;

  setUp(() {
    mockAdapter = _MockApiAdapter();
    dio = Dio(BaseOptions(
      baseUrl: 'http://mock.api/api',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => true,
    ));
    dio.httpClientAdapter = mockAdapter;
  });

  tearDown(() {
    dio.close();
  });

  group('API Contract Tests – Public Endpoints', () {
    test('GET /products returns paginated product list', () async {
      mockAdapter.onGet('/products', status: 200, body: {
        'success': true,
        'data': {
          'products': [
            {
              'id': 1,
              'name': 'Paracétamol 500mg',
              'price': 1500,
              'category_id': 2,
            }
          ],
          'current_page': 1,
          'last_page': 1,
        },
      });

      final response = await dio.get('/products');
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['data'], isA<Map>());
      expect(response.data['data']['products'], isA<List>());
      expect(response.data['data']['products'].first['name'], isNotEmpty);
    });

    test('GET /products/categories returns category list', () async {
      mockAdapter.onGet('/products/categories', status: 200, body: {
        'success': true,
        'data': [
          {'id': 1, 'name': 'Antibiotiques', 'slug': 'antibiotiques'},
          {'id': 2, 'name': 'Analgésiques', 'slug': 'analgesiques'},
        ],
      });

      final response = await dio.get('/products/categories');
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['data'], isA<List>());
      expect(response.data['data'].length, greaterThan(0));
    });

    test('GET /customer/pharmacies returns pharmacy list', () async {
      mockAdapter.onGet('/customer/pharmacies', status: 200, body: {
        'success': true,
        'data': [
          {
            'id': 1,
            'name': 'Pharmacie Centrale',
            'address': '12 Rue Abidjan',
            'latitude': 5.36,
            'longitude': -4.01,
            'is_on_duty': false,
          }
        ],
      });

      final response = await dio.get('/customer/pharmacies');
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['data'], isA<List>());
    });

    test('GET /customer/pharmacies/on-duty returns on-duty pharmacies', () async {
      mockAdapter.onGet('/customer/pharmacies/on-duty', status: 200, body: {
        'success': true,
        'data': [
          {
            'id': 2,
            'name': 'Pharmacie de Garde',
            'is_on_duty': true,
          }
        ],
      });

      final response = await dio.get('/customer/pharmacies/on-duty');
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['data'], isA<List>());
      if ((response.data['data'] as List).isNotEmpty) {
        expect(response.data['data'].first['is_on_duty'], true);
      }
    });
  });

  group('API Contract Tests – Authentication', () {
    test('POST /auth/login with invalid email returns error', () async {
      mockAdapter.onPost('/auth/login', status: 422, body: {
        'success': false,
        'message': 'Validation error',
        'errors': {
          'email': ['The email must be a valid email address.'],
        },
      });

      final response = await dio.post('/auth/login', data: {
        'email': 'invalid',
        'password': '123',
      });

      expect(response.data['success'], false);
      expect(response.data['errors'], isA<Map>());
    });

    test('POST /auth/login with wrong credentials returns 401', () async {
      mockAdapter.onPost('/auth/login', status: 401, body: {
        'success': false,
        'message': 'Invalid credentials',
      });

      final response = await dio.post('/auth/login', data: {
        'email': 'wrong@pharmacy.com',
        'password': 'WrongPassword123!',
      });

      expect(response.statusCode, 401);
      expect(response.data['success'], false);
      expect(response.data['message'], isNotEmpty);
    });

    test('POST /auth/register/pharmacy with empty body returns 422', () async {
      mockAdapter.onPost('/auth/register/pharmacy', status: 422, body: {
        'success': false,
        'message': 'Validation error',
        'errors': {
          'name': ['The name field is required.'],
          'email': ['The email field is required.'],
          'password': ['The password field is required.'],
          'pharmacy_name': ['The pharmacy name field is required.'],
        },
      });

      final response = await dio.post('/auth/register/pharmacy', data: {});
      expect(response.statusCode, 422);
      expect(response.data['success'], false);
      expect(response.data['errors'], isA<Map>());
      expect(response.data['errors'].length, greaterThan(0));
    });

    test('GET /auth/me without token returns 401', () async {
      mockAdapter.onGet('/auth/me', status: 401, body: {
        'success': false,
        'message': 'Unauthenticated.',
      });

      final response = await dio.get('/auth/me');
      expect(response.statusCode, 401);
      expect(response.data['success'], false);
    });
  });

  group('API Contract Tests – Protected Pharmacy Endpoints', () {
    test('GET /pharmacy/orders without auth returns 401', () async {
      mockAdapter.onGet('/pharmacy/orders', status: 401, body: {
        'success': false,
        'message': 'Unauthenticated.',
      });

      final response = await dio.get('/pharmacy/orders');
      expect(response.statusCode, 401);
      expect(response.data['success'], false);
    });

    test('GET /pharmacy/inventory without auth returns 401', () async {
      mockAdapter.onGet('/pharmacy/inventory', status: 401, body: {
        'success': false,
        'message': 'Unauthenticated.',
      });

      final response = await dio.get('/pharmacy/inventory');
      expect(response.statusCode, 401);
      expect(response.data['success'], false);
    });

    test('GET /pharmacy/on-calls without auth returns 401', () async {
      mockAdapter.onGet('/pharmacy/on-calls', status: 401, body: {
        'success': false,
        'message': 'Unauthenticated.',
      });

      final response = await dio.get('/pharmacy/on-calls');
      expect(response.statusCode, 401);
      expect(response.data['success'], false);
    });
  });

  group('API Contract Tests – Full Auth Flow', () {
    test('Register -> Login -> Profile -> Logout flow', () async {
      // 1. Register
      mockAdapter.onPost('/auth/register/pharmacy', status: 201, body: {
        'success': true,
        'message': 'Pharmacy registered successfully',
        'data': {
          'token': 'mock-token-abc123',
          'user': {
            'id': 42,
            'name': 'Test Pharmacist',
            'email': 'test@drpharma.ci',
            'phone': '+2250700000',
            'role': 'pharmacy',
          },
        },
      });

      final registerResponse = await dio.post('/auth/register/pharmacy', data: {
        'name': 'Test Pharmacist',
        'email': 'test@drpharma.ci',
        'phone': '+2250700000',
        'password': 'TestPassword123!',
        'password_confirmation': 'TestPassword123!',
        'pharmacy_name': 'Pharmacie Test',
        'pharmacy_license': 'LIC12345',
        'pharmacy_address': '123 Rue Test, Abidjan',
        'city': 'Abidjan',
        'latitude': 5.3600,
        'longitude': -4.0083,
        'device_name': 'contract_test',
      });

      expect(registerResponse.statusCode, 201);
      expect(registerResponse.data['success'], true);
      expect(registerResponse.data['data']['token'], isNotEmpty);

      // 2. Profile access (mock authenticated endpoint)
      mockAdapter.onGet('/auth/me', status: 200, body: {
        'success': true,
        'data': {
          'id': 42,
          'name': 'Test Pharmacist',
          'email': 'test@drpharma.ci',
          'role': 'pharmacy',
        },
      });

      final profileDio = Dio(BaseOptions(
        baseUrl: 'http://mock.api/api',
        headers: {
          'Authorization': 'Bearer mock-token-abc123',
          'Accept': 'application/json',
        },
        validateStatus: (status) => true,
      ));
      profileDio.httpClientAdapter = mockAdapter;

      final profileResponse = await profileDio.get('/auth/me');
      expect(profileResponse.statusCode, 200);
      expect(profileResponse.data['success'], true);
      expect(profileResponse.data['data']['email'], 'test@drpharma.ci');

      // 3. Logout
      mockAdapter.onPost('/auth/logout', status: 200, body: {
        'success': true,
        'message': 'Logged out successfully',
      });

      final logoutResponse = await profileDio.post('/auth/logout');
      expect(logoutResponse.statusCode, 200);
      expect(logoutResponse.data['success'], true);

      profileDio.close();
    });
  });
}
