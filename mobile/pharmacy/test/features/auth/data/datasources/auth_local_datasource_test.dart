import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_pharmacy/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:drpharma_pharmacy/features/auth/data/models/user_model.dart';
import 'package:drpharma_pharmacy/core/constants/app_constants.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late AuthLocalDataSourceImpl dataSource;

  setUpAll(() {
    // Initialize SharedPreferences mock values
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    dataSource = AuthLocalDataSourceImpl(secureStorage: mockSecureStorage);
  });

  group('cacheToken', () {
    test('should cache token in secure storage', () async {
      const token = 'test-jwt-token';
      when(
        () => mockSecureStorage.write(key: AppConstants.tokenKey, value: token),
      ).thenAnswer((_) async {});

      await dataSource.cacheToken(token);

      verify(
        () => mockSecureStorage.write(key: AppConstants.tokenKey, value: token),
      ).called(1);
    });
  });

  group('getToken', () {
    test('should return cached token when present', () async {
      const token = 'cached-token';
      when(
        () => mockSecureStorage.read(key: AppConstants.tokenKey),
      ).thenAnswer((_) async => token);

      final result = await dataSource.getToken();

      expect(result, token);
      verify(
        () => mockSecureStorage.read(key: AppConstants.tokenKey),
      ).called(1);
    });

    test('should return null when no token cached', () async {
      when(
        () => mockSecureStorage.read(key: AppConstants.tokenKey),
      ).thenAnswer((_) async => null);

      final result = await dataSource.getToken();

      expect(result, isNull);
    });
  });

  group('cacheUser', () {
    test('should cache user in secure storage as JSON', () async {
      const user = UserModel(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        phone: '+225 01 02 03 04 05',
        role: 'pharmacist',
      );

      when(
        () => mockSecureStorage.write(
          key: AppConstants.userKey,
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await dataSource.cacheUser(user);

      verify(
        () => mockSecureStorage.write(
          key: AppConstants.userKey,
          value: any(
            named: 'value',
            that: contains('"email":"test@example.com"'),
          ),
        ),
      ).called(1);
    });
  });

  group('getUser', () {
    test('should return cached user when present', () async {
      final userJson = json.encode({
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '+225 01 02 03 04 05',
        'role': 'pharmacist',
      });

      when(
        () => mockSecureStorage.read(key: AppConstants.userKey),
      ).thenAnswer((_) async => userJson);

      final result = await dataSource.getUser();

      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.name, 'Test User');
      expect(result.email, 'test@example.com');
    });

    test('should return null when no user cached', () async {
      when(
        () => mockSecureStorage.read(key: AppConstants.userKey),
      ).thenAnswer((_) async => null);

      final result = await dataSource.getUser();

      expect(result, isNull);
    });
  });

  group('clearAuthData', () {
    test('should remove token and user from secure storage', () async {
      when(
        () => mockSecureStorage.delete(key: AppConstants.tokenKey),
      ).thenAnswer((_) async {});
      when(
        () => mockSecureStorage.delete(key: AppConstants.userKey),
      ).thenAnswer((_) async {});
      when(
        () => mockSecureStorage.delete(key: 'secure_remember_me_email'),
      ).thenAnswer((_) async {});

      await dataSource.clearAuthData();

      verify(
        () => mockSecureStorage.delete(key: AppConstants.tokenKey),
      ).called(1);
      verify(
        () => mockSecureStorage.delete(key: AppConstants.userKey),
      ).called(1);
    });
  });

  group('hasToken', () {
    test('should return true when token exists', () async {
      when(
        () => mockSecureStorage.read(key: AppConstants.tokenKey),
      ).thenAnswer((_) async => 'some-token');

      final result = await dataSource.hasToken();

      expect(result, isTrue);
    });

    test('should return false when token does not exist', () async {
      when(
        () => mockSecureStorage.read(key: AppConstants.tokenKey),
      ).thenAnswer((_) async => null);

      final result = await dataSource.hasToken();

      expect(result, isFalse);
    });
  });
}
