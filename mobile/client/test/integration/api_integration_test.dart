@Skip('Integration test - requires running API server')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:drpharma_client/core/constants/api_constants.dart';

/// Integration tests that verify the mobile client can communicate
/// with the Laravel API server.
/// 
/// To run these tests, ensure the API server is running:
/// ```
/// cd api && php artisan serve
/// ```
/// Then run:
/// ```
/// flutter test test/integration/api_integration_test.dart
/// ```
void main() {
  late Dio dio;
  const baseUrl = 'http://127.0.0.1:8000/api';

  setUp(() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
  });

  tearDown(() {
    dio.close();
  });

  group('API Integration Tests', () {
    group('Public Endpoints', () {
      test('GET /products returns valid response', () async {
        final response = await dio.get(ApiConstants.products);
        
        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        expect(response.data['data'], isA<Map>());
        expect(response.data['data']['products'], isA<List>());
        expect(response.data['data']['pagination'], isA<Map>());
      });

      test('GET /products/categories returns valid response', () async {
        final response = await dio.get('/products/categories');
        
        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        expect(response.data['data'], isA<Map>());
        expect(response.data['data']['categories'], isA<List>());
      });

      test('GET /products/featured returns valid response', () async {
        final response = await dio.get('/products/featured');
        
        expect(response.statusCode, 200);
        expect(response.data['success'], true);
      });

      test('GET /products/search accepts query parameter', () async {
        final response = await dio.get(
          ApiConstants.searchProducts,
          queryParameters: {'q': 'paracetamol'},
        );
        
        expect(response.statusCode, 200);
        expect(response.data['success'], true);
      });
    });

    group('Authentication Endpoints', () {
      test('POST /auth/login validates credentials', () async {
        try {
          await dio.post(
            ApiConstants.login,
            data: {'email': 'invalid@test.com', 'password': 'wrong'},
          );
          fail('Should have thrown');
        } on DioException catch (e) {
          // 401 Unauthorized for invalid credentials
          expect(e.response?.statusCode, anyOf(401, 422));
          expect(e.response?.data['success'], false);
        }
      });

      test('POST /auth/register requires all fields', () async {
        try {
          await dio.post(ApiConstants.register, data: {});
          fail('Should have thrown');
        } on DioException catch (e) {
          expect(e.response?.statusCode, 422);
          // API returns validation errors without 'success' field
          expect(e.response?.data.containsKey('message'), true);
        }
      });

      test('GET /auth/me requires authentication', () async {
        try {
          await dio.get(ApiConstants.profile);
          fail('Should have thrown');
        } on DioException catch (e) {
          expect(e.response?.statusCode, 401);
          expect(e.response?.data['success'], false);
        }
      });
    });

    group('Full Authentication Flow', () {
      test('Register -> Login -> Access Profile -> Logout', () async {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final testEmail = 'integration_$timestamp@test.ci';
        
        // 1. Register
        final registerResponse = await dio.post(
          ApiConstants.register,
          data: {
            'name': 'Integration Test User',
            'email': testEmail,
            'password': 'TestPassword123!',
            'password_confirmation': 'TestPassword123!',
            'phone': '+2250701${timestamp.toString().substring(6)}',
            'role': 'customer',
          },
        );
        
        expect(registerResponse.statusCode, anyOf(200, 201));
        expect(registerResponse.data['success'], true);
        expect(registerResponse.data['data']['token'], isNotEmpty);
        
        final token = registerResponse.data['data']['token'];
        
        // 2. Access profile with token
        dio.options.headers['Authorization'] = 'Bearer $token';
        
        final profileResponse = await dio.get(ApiConstants.profile);
        
        expect(profileResponse.statusCode, 200);
        expect(profileResponse.data['success'], true);
        expect(profileResponse.data['data']['email'], testEmail);
        
        // 3. Get notifications (authenticated endpoint)
        final notificationsResponse = await dio.get(ApiConstants.notifications);
        
        expect(notificationsResponse.statusCode, 200);
        expect(notificationsResponse.data['success'], true);
        expect(notificationsResponse.data['data']['notifications'], isA<List>());
        expect(notificationsResponse.data['data']['unread_count'], isA<int>());
        
        // 4. Logout
        final logoutResponse = await dio.post(ApiConstants.logout);
        
        expect(logoutResponse.statusCode, 200);
        expect(logoutResponse.data['success'], true);
        
        // 5. Verify token is invalidated
        try {
          await dio.get(ApiConstants.profile);
          fail('Should have thrown after logout');
        } on DioException catch (e) {
          expect(e.response?.statusCode, 401);
        }
      });
    });
  });
}
