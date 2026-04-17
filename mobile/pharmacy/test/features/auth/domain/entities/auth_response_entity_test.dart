import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/auth_response_entity.dart';
import '../../../../test_helpers.dart';

void main() {
  group('AuthResponseEntity', () {
    test('should create entity with required parameters', () {
      final user = TestDataFactory.createUser();
      final authResponse = AuthResponseEntity(
        user: user,
        token: 'test-jwt-token',
      );

      expect(authResponse.user, equals(user));
      expect(authResponse.token, 'test-jwt-token');
    });

    test('should hold user data correctly', () {
      final user = TestDataFactory.createUser(
        id: 1,
        name: 'Test Pharmacist',
        email: 'pharmacist@test.com',
      );
      final authResponse = AuthResponseEntity(
        user: user,
        token: 'token123',
      );

      expect(authResponse.user.id, 1);
      expect(authResponse.user.name, 'Test Pharmacist');
      expect(authResponse.user.email, 'pharmacist@test.com');
    });

    test('should hold different tokens', () {
      final user = TestDataFactory.createUser();
      
      final response1 = AuthResponseEntity(user: user, token: 'token-1');
      final response2 = AuthResponseEntity(user: user, token: 'token-2');

      expect(response1.token, 'token-1');
      expect(response2.token, 'token-2');
      expect(response1.token, isNot(response2.token));
    });

    test('should work with bearer token format', () {
      final user = TestDataFactory.createUser();
      final authResponse = AuthResponseEntity(
        user: user,
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U',
      );

      expect(authResponse.token, startsWith('eyJ'));
      expect(authResponse.token.split('.').length, 3);
    });

    test('should hold empty token', () {
      final user = TestDataFactory.createUser();
      final authResponse = AuthResponseEntity(
        user: user,
        token: '',
      );

      expect(authResponse.token, isEmpty);
    });

    test('should work with user having pharmacies', () {
      final pharmacy = TestDataFactory.createPharmacy(
        id: 1,
        name: 'Pharmacie Centrale',
      );
      final user = TestDataFactory.createUser(
        pharmacies: [pharmacy],
      );
      final authResponse = AuthResponseEntity(
        user: user,
        token: 'token',
      );

      expect(authResponse.user.pharmacies, hasLength(1));
      expect(authResponse.user.pharmacies.first.name, 'Pharmacie Centrale');
    });
  });
}
