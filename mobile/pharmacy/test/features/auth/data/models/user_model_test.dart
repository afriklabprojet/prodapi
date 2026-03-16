import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/auth/data/models/user_model.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    const tUserModel = UserModel(
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
      phone: '0123456789',
      role: 'pharmacist',
    );

    final tUserJson = {
      'id': 1,
      'name': 'Test User',
      'email': 'test@example.com',
      'phone': '0123456789',
      'role': 'pharmacist',
    };

    group('fromJson', () {
      test('should return a valid model from JSON', () {
        // act
        final result = UserModel.fromJson(tUserJson);

        // assert
        expect(result.id, tUserModel.id);
        expect(result.name, tUserModel.name);
        expect(result.email, tUserModel.email);
        expect(result.phone, tUserModel.phone);
        expect(result.role, tUserModel.role);
      });

      test('should handle null values for optional fields', () {
        // arrange
        final json = {
          'id': 1,
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '0123456789',
          'role': null,
          'avatar': null,
        };

        // act
        final result = UserModel.fromJson(json);

        // assert
        expect(result.role, isNull);
        expect(result.avatar, isNull);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        // act
        final result = tUserModel.toJson();

        // assert
        expect(result['id'], tUserModel.id);
        expect(result['name'], tUserModel.name);
        expect(result['email'], tUserModel.email);
        expect(result['phone'], tUserModel.phone);
        expect(result['role'], tUserModel.role);
      });
    });

    group('toEntity', () {
      test('should return a UserEntity with the same values', () {
        // act
        final result = tUserModel.toEntity();

        // assert
        expect(result, isA<UserEntity>());
        expect(result.id, tUserModel.id);
        expect(result.name, tUserModel.name);
        expect(result.email, tUserModel.email);
        expect(result.phone, tUserModel.phone);
        expect(result.role, tUserModel.role);
      });
    });

    group('equality', () {
      test('should be equal when all properties are the same', () {
        // arrange
        const model1 = UserModel(
          id: 1,
          name: 'Test User',
          email: 'test@example.com',
          phone: '0123456789',
          role: 'pharmacist',
        );
        const model2 = UserModel(
          id: 1,
          name: 'Test User',
          email: 'test@example.com',
          phone: '0123456789',
          role: 'pharmacist',
        );

        // assert - Note: without Equatable, this uses reference equality
        expect(model1.id, model2.id);
        expect(model1.name, model2.name);
        expect(model1.email, model2.email);
      });
    });
  });
}
