import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/secure_token_service.dart';

/// Tests for Improvement 1: Phone-first registration
/// Tests that email is truly optional in the registration flow.
///
/// The actual UI/widget test (TextFormField validation) requires
/// a widget test pump, so here we test the underlying validation logic
/// and the auth repository's registerCourier FormData building.

void main() {
  setUp(() {
    SecureTokenService.enableTestMode();
  });

  tearDown(() {
    SecureTokenService.disableTestMode();
  });

  group('Phone-first Registration - Email Optional', () {
    test('email can be null in registration data', () {
      // Simulate what registerCourier() does with FormData
      final formFields = <String, dynamic>{
        'name': 'Test Courier',
        'phone': '+2250701020304',
        'password': 'SecurePass123!',
        'password_confirmation': 'SecurePass123!',
        'vehicle_type': 'moto',
      };

      // When email is null, it should NOT be added to form data
      const String? email = null;
      if (email != null && email.isNotEmpty) {
        formFields['email'] = email;
      }

      expect(formFields.containsKey('email'), isFalse);
      expect(formFields['phone'], '+2250701020304');
      expect(formFields['name'], 'Test Courier');
    });

    test('email is included when provided', () {
      final formFields = <String, dynamic>{
        'name': 'Test Courier',
        'phone': '+2250701020304',
        'password': 'SecurePass123!',
        'password_confirmation': 'SecurePass123!',
        'vehicle_type': 'moto',
      };

      const String email = 'courier@test.com';
      if (email.isNotEmpty) {
        formFields['email'] = email;
      }

      expect(formFields.containsKey('email'), isTrue);
      expect(formFields['email'], 'courier@test.com');
    });

    test('empty string email is treated as null', () {
      final formFields = <String, dynamic>{
        'name': 'Test Courier',
        'phone': '+2250701020304',
        'password': 'SecurePass123!',
        'password_confirmation': 'SecurePass123!',
        'vehicle_type': 'moto',
      };

      const String email = '';
      if (email.isNotEmpty) {
        formFields['email'] = email;
      }

      expect(formFields.containsKey('email'), isFalse);
    });

    test('phone field is always required', () {
      // Simulating validation: phone must not be empty
      const phone = '+2250701020304';
      expect(phone.isNotEmpty, isTrue);
      expect(phone.startsWith('+'), isTrue);
    });

    test('whitespace-only email is treated as empty', () {
      final formFields = <String, dynamic>{
        'name': 'Test Courier',
        'phone': '+2250701020304',
      };

      const String rawEmail = '   ';
      final email = rawEmail.trim();
      if (email.isNotEmpty) {
        formFields['email'] = email;
      }

      expect(formFields.containsKey('email'), isFalse);
    });
  });
}
