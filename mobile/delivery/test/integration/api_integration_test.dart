import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests to verify API communication with Delivery (Courier) app.
/// These tests require the API server to be running on http://127.0.0.1:8000.
///
/// If the server is not reachable, all tests are skipped automatically.
void main() {
  late Dio dio;
  const baseUrl = 'http://127.0.0.1:8000/api';
  bool serverAvailable = false;

  setUpAll(() async {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => true,
    ));

    // Check if the API server is reachable via raw socket (fast, no HTTP overhead)
    try {
      final socket = await Socket.connect('127.0.0.1', 8000, timeout: const Duration(seconds: 3));
      socket.destroy();
      serverAvailable = true;
    } catch (_) {
      serverAvailable = false;
    }
  });

  tearDownAll(() {
    dio.close();
  });

  /// Helper: skips the test when the server is offline.
  void skipIfNoServer() {
    if (!serverAvailable) {
      markTestSkipped('API server not reachable at $baseUrl');
      return;
    }
  }

  group('API Integration Tests - Delivery App', () {
    group('Public Endpoints', () {
      test('GET /products returns valid response', () async {
        skipIfNoServer(); if (!serverAvailable) return;
        final response = await dio.get('/products');
        expect(response.statusCode, 200);
        expect(response.data['success'], true);
      });
    });

    group('Authentication Endpoints', () {
      test('POST /auth/login returns error for invalid credentials', () async {
        skipIfNoServer(); if (!serverAvailable) return;
        final response = await dio.post('/auth/login', data: {
          'email': 'nonexistent@courier.com',
          'password': 'WrongPassword123!',
        });
        expect(response.data['success'], false);
      });

      test('POST /auth/register/courier requires all fields', () async {
        skipIfNoServer(); if (!serverAvailable) return;
        final response = await dio.post('/auth/register/courier', data: {});
        // 422 for validation error, 429 for rate limiting
        expect([422, 429].contains(response.statusCode), true);
      });

      test('GET /auth/me requires authentication', () async {
        skipIfNoServer(); if (!serverAvailable) return;
        final response = await dio.get('/auth/me');
        expect(response.statusCode, 401);
        expect(response.data['success'], false);
      });
    });

    group('Courier Protected Endpoints (without auth)', () {
      test('GET /courier/deliveries requires authentication', () async {
        skipIfNoServer(); if (!serverAvailable) return;
        final response = await dio.get('/courier/deliveries');
        expect(response.statusCode, 401);
        expect(response.data['success'], false);
      });

      test('GET /courier/challenges requires authentication', () async {
        skipIfNoServer(); if (!serverAvailable) return;
        final response = await dio.get('/courier/challenges');
        expect(response.statusCode, 401);
        expect(response.data['success'], false);
      });

      test('GET /courier/bonuses requires authentication', () async {
        skipIfNoServer(); if (!serverAvailable) return;
        final response = await dio.get('/courier/bonuses');
        expect(response.statusCode, 401);
        expect(response.data['success'], false);
      });
    });

    group('Full Authentication Flow', () {
      test('Register Courier -> Login -> Access Protected Routes -> Logout', () async {
        skipIfNoServer(); if (!serverAvailable) return;
        final uniqueId = DateTime.now().millisecondsSinceEpoch;
        final shortId = uniqueId.toString().substring(uniqueId.toString().length - 6);
        final testEmail = 'couriertest$shortId@drpharma.ci';
        final testPhone = '+22505$shortId';

        // Step 1: Register a new courier
        final registerResponse = await dio.post('/auth/register/courier', data: {
          'name': 'Test Courier $shortId',
          'email': testEmail,
          'phone': testPhone,
          'password': 'TestPassword123!',
          'password_confirmation': 'TestPassword123!',
          'vehicle_type': 'motorcycle',
          'license_number': 'LIC$shortId',
          'id_card_number': 'ID$shortId',
          'device_name': 'integration_test',
        });

        // If registration fails due to duplicate or rate limiting, skip the rest
        if (registerResponse.statusCode == 422 || registerResponse.statusCode == 429) {
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
          expect(profileResponse.data['data']['email'], testEmail);

          // Step 3: Access courier deliveries (may return 403 if not approved)
          final deliveriesResponse = await authDio.get('/courier/deliveries');
          expect([200, 403].contains(deliveriesResponse.statusCode), true);

          // Step 4: Access challenges
          final challengesResponse = await authDio.get('/courier/challenges');
          expect([200, 403].contains(challengesResponse.statusCode), true);

          // Step 5: Logout
          final logoutResponse = await authDio.post('/auth/logout');
          expect(logoutResponse.statusCode, 200);

          // Step 6: Verify token is invalidated
          final invalidatedResponse = await authDio.get('/auth/me');
          expect(invalidatedResponse.statusCode, 401);
        } finally {
          authDio.close();
        }
      });
    });
  });
}
