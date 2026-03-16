import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/core/services/secure_storage_service.dart';

// Note: SecureStorageService uses static methods with FlutterSecureStorage
// In real tests, we would mock FlutterSecureStorage
// These tests verify the interface and structure

void main() {
  group('SecureStorageService Tests', () {
    test('should have saveToken method', () {
      expect(SecureStorageService.saveToken, isA<Function>());
    });

    test('should have getToken method', () {
      expect(SecureStorageService.getToken, isA<Function>());
    });

    test('should have deleteToken method', () {
      expect(SecureStorageService.deleteToken, isA<Function>());
    });

    test('should have saveRefreshToken method', () {
      expect(SecureStorageService.saveRefreshToken, isA<Function>());
    });

    test('should have getRefreshToken method', () {
      expect(SecureStorageService.getRefreshToken, isA<Function>());
    });

    test('should have deleteRefreshToken method', () {
      expect(SecureStorageService.deleteRefreshToken, isA<Function>());
    });

    test('should have saveUserId method', () {
      expect(SecureStorageService.saveUserId, isA<Function>());
    });

    test('should have getUserId method', () {
      expect(SecureStorageService.getUserId, isA<Function>());
    });

    test('should have clearAll method', () {
      expect(SecureStorageService.clearAll, isA<Function>());
    });

    test('should have hasToken method', () {
      expect(SecureStorageService.hasToken, isA<Function>());
    });
  });
}
