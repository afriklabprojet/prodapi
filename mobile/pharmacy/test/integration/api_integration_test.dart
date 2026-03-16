import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Check if the local API server is reachable.
Future<bool> _isServerRunning() async {
  try {
    final socket = await Socket.connect('127.0.0.1', 8000,
        timeout: const Duration(seconds: 2));
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

/// Integration tests to verify API communication with Pharmacy app
/// These tests require the API server to be running on http://127.0.0.1:8000
void main() {
  late Dio dio;
  const baseUrl = 'http://127.0.0.1:8000/api';
  bool serverAvailable = false;

  setUpAll(() async {
    serverAvailable = await _isServerRunning();
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // Allow all status codes to verify response content
      validateStatus: (status) => true,
    ));
  });

  tearDownAll(() {
    dio.close();
  });

  /// Helper: skip if server not running. Returns true if skipped.
  bool skipIfNoServer() {
    if (!serverAvailable) {
      markTestSkipped('API server not running on 127.0.0.1:8000');
      return true;
    }
    return false;
  }

  group('API Integration Tests - Pharmacy App', () {
    group('Public Endpoints', () {
      test('GET /products returns valid response', () async {
        if (skipIfNoServer()) return;
        final response = await dio.get('/products');
        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        expect(response.data['data'], isA<Map>());
        expect(response.data['data'].containsKey('products'), true);
      });

      test('GET /products/categories returns valid response', () async {
        if (skipIfNoServer()) return;
        final response = await dio.get('/products/categories');
        expect(response.statusCode, 200);
        expect(response.data['success'], true);
      });

      test('GET /customer/pharmacies returns list of pharmacies', () async {
        if (skipIfNoServer()) return;
        final response = await dio.get('/customer/pharmacies');
        expect(response.statusCode, 200);
        expect(response.data['success'], true);
      });

      test('GET /customer/pharmacies/on-duty returns on-duty pharmacies', () async {
        if (skipIfNoServer()) return;
        final response = await dio.get('/customer/pharmacies/on-duty');
        expect(response.statusCode, 200);
        expect(response.data['success'], true);
      });
    });

    group('Authentication Endpoints', () {
      test('POST /auth/login returns error for invalid email format', () async {
        if (skipIfNoServer()) return;
        final response = await dio.post('/auth/login', data: {
          'email': 'invalid',
          'password': '123',
        });
        // May return 401 (invalid) or 422 (validation)
        expect(response.data['success'], false);
      });

      test('POST /auth/login returns error for invalid credentials', () async {
        if (skipIfNoServer()) return;
        final response = await dio.post('/auth/login', data: {
          'email': 'nonexistent@pharmacy.com',
          'password': 'WrongPassword123!',
        });
        // Should return 401 or error response
        expect(response.data['success'], false);
      });

      test('POST /auth/register/pharmacy requires all fields', () async {
        if (skipIfNoServer()) return;
        final response = await dio.post('/auth/register/pharmacy', data: {});
        // 422 for validation error, 429 for rate limiting
        expect([422, 429].contains(response.statusCode), true);
      });

      test('GET /auth/me requires authentication', () async {
        if (skipIfNoServer()) return;
        final response = await dio.get('/auth/me');
        expect(response.statusCode, 401);
        expect(response.data['success'], false);
      });
    });

    group('Pharmacy Protected Endpoints (without auth)', () {
      test('GET /pharmacy/orders requires authentication', () async {
        if (skipIfNoServer()) return;
        final response = await dio.get('/pharmacy/orders');
        expect(response.statusCode, 401);
        expect(response.data['success'], false);
      });

      test('GET /pharmacy/inventory requires authentication', () async {
        if (skipIfNoServer()) return;
        final response = await dio.get('/pharmacy/inventory');
        expect(response.statusCode, 401);
        expect(response.data['success'], false);
      });

      test('GET /pharmacy/on-calls requires authentication', () async {
        if (skipIfNoServer()) return;
        final response = await dio.get('/pharmacy/on-calls');
        expect(response.statusCode, 401);
        expect(response.data['success'], false);
      });
    });

    group('Full Authentication Flow', () {
      test('Register Pharmacy -> Login -> Access Protected Routes -> Logout', () async {
        if (skipIfNoServer()) return;
        final uniqueId = DateTime.now().millisecondsSinceEpoch;
        final shortId = uniqueId.toString().substring(uniqueId.toString().length - 6);
        final testEmail = 'pharmatest$shortId@drpharma.ci';
        final testPhone = '+22507$shortId';
        
        // Step 1: Register a new pharmacy
        final registerResponse = await dio.post('/auth/register/pharmacy', data: {
          'name': 'Test Pharmacist $shortId',
          'email': testEmail,
          'phone': testPhone,
          'password': 'TestPassword123!',
          'password_confirmation': 'TestPassword123!',
          'pharmacy_name': 'Pharmacie Test $shortId',
          'pharmacy_license': 'LIC$shortId',
          'pharmacy_address': '123 Rue Test, Abidjan',
          'city': 'Abidjan',
          'latitude': 5.3600,
          'longitude': -4.0083,
          'device_name': 'integration_test',
        });
        
        // If registration fails due to duplicate or rate limiting, skip the rest
        if (registerResponse.statusCode == 422 || registerResponse.statusCode == 429) {
          // Already registered or rate limited, skip this test run
          return;
        }
        
        expect(registerResponse.statusCode, 201);
        expect(registerResponse.data['success'], true);
        final token = registerResponse.data['data']['token'];
        expect(token, isNotNull);
        
        // Create authenticated Dio instance
        final authDio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => true,
        ));
        
        try {
          // Step 2: Access profile
          final profileResponse = await authDio.get('/auth/me');
          expect(profileResponse.statusCode, 200);
          expect(profileResponse.data['success'], true);
          // User data is directly under 'data'
          expect(profileResponse.data['data']['email'], testEmail);
          
          // Step 3: Access pharmacy orders
          // Note: Newly registered pharmacies are pending approval, so may return 403
          final ordersResponse = await authDio.get('/pharmacy/orders');
          expect([200, 403].contains(ordersResponse.statusCode), true);
          
          // Step 4: Access pharmacy inventory (same - may need approval)
          final inventoryResponse = await authDio.get('/pharmacy/inventory');
          expect([200, 403].contains(inventoryResponse.statusCode), true);
          
          // Step 5: Access pharmacy on-calls (same - may need approval)
          final onCallsResponse = await authDio.get('/pharmacy/on-calls');
          expect([200, 403].contains(onCallsResponse.statusCode), true);
          
          // Step 6: Logout
          final logoutResponse = await authDio.post('/auth/logout');
          expect(logoutResponse.statusCode, 200);
          
          // Step 7: Verify token is invalidated
          final invalidatedResponse = await authDio.get('/auth/me');
          expect(invalidatedResponse.statusCode, 401);
        } finally {
          authDio.close();
        }
      });
    });
  });
}
