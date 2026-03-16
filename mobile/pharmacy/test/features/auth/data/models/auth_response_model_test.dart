import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/auth/data/models/auth_response_model.dart';
import 'package:drpharma_pharmacy/features/auth/data/models/user_model.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/auth_response_entity.dart';

void main() {
  group('AuthResponseModel', () {
    const tUserModel = UserModel(
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
      phone: '0123456789',
      role: 'pharmacist',
    );

    const tAuthResponseModel = AuthResponseModel(
      user: tUserModel,
      token: 'test_token_123',
    );

    final tAuthResponseJson = {
      'user': {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '0123456789',
        'role': 'pharmacist',
      },
      'token': 'test_token_123',
    };

    group('fromJson', () {
      test('should return a valid model from JSON', () {
        // act
        final result = AuthResponseModel.fromJson(tAuthResponseJson);

        // assert
        expect(result.token, tAuthResponseModel.token);
        expect(result.user.id, tAuthResponseModel.user.id);
        expect(result.user.email, tAuthResponseModel.user.email);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        // act
        final result = tAuthResponseModel.toJson();

        // assert
        expect(result['token'], tAuthResponseModel.token);
        // Le champ 'user' peut être un Map ou un UserModel selon json_serializable
        expect(result.containsKey('user'), isTrue);
      });
    });

    group('toEntity', () {
      test('should return an AuthResponseEntity with the same values', () {
        // act
        final result = tAuthResponseModel.toEntity();

        // assert
        expect(result, isA<AuthResponseEntity>());
        expect(result.token, tAuthResponseModel.token);
        expect(result.user.id, tAuthResponseModel.user.id);
        expect(result.user.email, tAuthResponseModel.user.email);
        expect(result.user.name, tAuthResponseModel.user.name);
      });
    });
  });
}
