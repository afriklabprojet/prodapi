import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/features/auth/domain/entities/auth_response_entity.dart';
import 'package:drpharma_client/features/auth/domain/entities/user_entity.dart';

void main() {
  group('AuthResponseEntity', () {
    final testDate = DateTime(2024, 1, 1);

    UserEntity createUser({
      int id = 1,
      String name = 'Jean Dupont',
      String email = 'jean.dupont@email.com',
      String phone = '+241 01 23 45 67',
    }) {
      return UserEntity(
        id: id,
        name: name,
        email: email,
        phone: phone,
        createdAt: testDate,
      );
    }

    group('creation', () {
      test('should create with user and token', () {
        final user = createUser();
        const token = 'jwt_token_12345';

        final response = AuthResponseEntity(user: user, token: token);

        expect(response.user, equals(user));
        expect(response.token, equals(token));
      });

      test('should store complex token', () {
        final user = createUser();
        const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

        final response = AuthResponseEntity(user: user, token: token);

        expect(response.token, equals(token));
      });

      test('should store empty token', () {
        final user = createUser();
        const token = '';

        final response = AuthResponseEntity(user: user, token: token);

        expect(response.token, isEmpty);
      });
    });

    group('user access', () {
      test('should provide access to user properties', () {
        final user = createUser(
          id: 99,
          name: 'Test User',
          email: 'test@email.com',
          phone: '+241 99 88 77 66',
        );
        const token = 'token123';

        final response = AuthResponseEntity(user: user, token: token);

        expect(response.user.id, equals(99));
        expect(response.user.name, equals('Test User'));
        expect(response.user.email, equals('test@email.com'));
        expect(response.user.phone, equals('+241 99 88 77 66'));
      });

      test('should access user verification status', () {
        final verifiedUser = UserEntity(
          id: 1,
          name: 'Verified User',
          email: 'verified@email.com',
          phone: '+241 11 22 33 44',
          emailVerifiedAt: DateTime(2024, 1, 1),
          phoneVerifiedAt: DateTime(2024, 1, 2),
          createdAt: testDate,
        );
        const token = 'token';

        final response = AuthResponseEntity(user: verifiedUser, token: token);

        expect(response.user.isEmailVerified, isTrue);
        expect(response.user.isPhoneVerified, isTrue);
      });
    });

    group('equality', () {
      test('two responses with same props should be equal', () {
        final user = createUser();
        const token = 'same_token';

        final response1 = AuthResponseEntity(user: user, token: token);
        final response2 = AuthResponseEntity(user: user, token: token);

        expect(response1, equals(response2));
      });

      test('two responses with different users should not be equal', () {
        final user1 = createUser(id: 1, name: 'User 1');
        final user2 = createUser(id: 2, name: 'User 2');
        const token = 'same_token';

        final response1 = AuthResponseEntity(user: user1, token: token);
        final response2 = AuthResponseEntity(user: user2, token: token);

        expect(response1, isNot(equals(response2)));
      });

      test('two responses with different tokens should not be equal', () {
        final user = createUser();
        const token1 = 'token_1';
        const token2 = 'token_2';

        final response1 = AuthResponseEntity(user: user, token: token1);
        final response2 = AuthResponseEntity(user: user, token: token2);

        expect(response1, isNot(equals(response2)));
      });

      test('two responses with same user but different id should not be equal', () {
        final user1 = createUser(id: 1);
        final user2 = createUser(id: 2);
        const token = 'token';

        final response1 = AuthResponseEntity(user: user1, token: token);
        final response2 = AuthResponseEntity(user: user2, token: token);

        expect(response1, isNot(equals(response2)));
      });
    });

    group('props', () {
      test('should include user and token in props', () {
        final user = createUser();
        const token = 'test_token';

        final response = AuthResponseEntity(user: user, token: token);

        expect(response.props.length, equals(3));
        expect(response.props[0], equals(user));
        expect(response.props[1], equals(token));
        expect(response.props[2], isNull); // firebaseToken defaults to null
      });
    });

    group('hashCode', () {
      test('same responses should have same hashCode', () {
        final user = createUser();
        const token = 'token';

        final response1 = AuthResponseEntity(user: user, token: token);
        final response2 = AuthResponseEntity(user: user, token: token);

        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('different responses should have different hashCodes', () {
        final user = createUser();
        const token1 = 'token1';
        const token2 = 'token2';

        final response1 = AuthResponseEntity(user: user, token: token1);
        final response2 = AuthResponseEntity(user: user, token: token2);

        expect(response1.hashCode, isNot(equals(response2.hashCode)));
      });
    });

    group('token types', () {
      test('should handle bearer token', () {
        final user = createUser();
        const token = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

        final response = AuthResponseEntity(user: user, token: token);

        expect(response.token, startsWith('Bearer '));
      });

      test('should handle simple token', () {
        final user = createUser();
        const token = 'simple_auth_token_123456';

        final response = AuthResponseEntity(user: user, token: token);

        expect(response.token, equals(token));
      });

      test('should handle token with special characters', () {
        final user = createUser();
        const token = 'token+with/special=chars==';

        final response = AuthResponseEntity(user: user, token: token);

        expect(response.token, equals(token));
      });
    });
  });
}
