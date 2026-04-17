import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_pharmacy/core/network/api_client.dart';
import 'package:drpharma_pharmacy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:drpharma_pharmacy/features/auth/data/models/auth_response_model.dart';
import 'package:drpharma_pharmacy/features/auth/data/models/user_model.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = AuthRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  setUpAll(() {
    registerFallbackValue(Options());
  });

  group('AuthRemoteDataSourceImpl', () {
    group('login', () {
      const tEmail = 'Test@Example.Com';
      const tPassword = 'password123';

      final tUserJson = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '+225 0123456789',
      };

      final tAuthResponseJson = {
        'user': tUserJson,
        'token': 'test_token_123',
      };

      test('should call apiClient.post with correct parameters', () async {
        // arrange
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: {'data': tAuthResponseJson},
        ));

        // act
        await dataSource.login(email: tEmail, password: tPassword);

        // assert
        verify(() => mockApiClient.post(
          '/auth/login',
          data: {
            'email': 'test@example.com', // Should be lowercase
            'password': tPassword,
            'device_name': 'pharmacy-app',
            'role': 'pharmacy',
          },
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).called(1);
      });

      test('should normalize email to lowercase', () async {
        // arrange
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: {'data': tAuthResponseJson},
        ));

        // act
        await dataSource.login(
          email: '  TEST@EXAMPLE.COM  ', // Uppercase with spaces
          password: tPassword,
        );

        // assert
        verify(() => mockApiClient.post(
          '/auth/login',
          data: {
            'email': 'test@example.com', // Lowercase and trimmed
            'password': tPassword,
            'device_name': 'pharmacy-app',
            'role': 'pharmacy',
          },
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).called(1);
      });

      test('should return AuthResponseModel on successful login', () async {
        // arrange
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: {'data': tAuthResponseJson},
        ));

        // act
        final result = await dataSource.login(email: tEmail, password: tPassword);

        // assert
        expect(result, isA<AuthResponseModel>());
        expect(result.token, equals('test_token_123'));
      });
    });

    group('register', () {
      const tName = 'John Doe';
      const tPharmacyName = 'Pharmacie Test';
      const tEmail = 'Test@Example.Com';
      const tPhone = '+225 0123456789';
      const tPassword = 'password123';
      const tLicenseNumber = 'LIC123456';
      const tCity = 'Abidjan';
      const tAddress = '123 Rue Test';

      final tUserJson = {
        'id': 1,
        'name': tName,
        'email': 'test@example.com',
        'phone': tPhone,
      };

      final tAuthResponseJson = {
        'user': tUserJson,
        'token': 'new_token_123',
      };

      test('should call apiClient.post with correct registration data', () async {
        // arrange
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/register/pharmacy'),
          statusCode: 201,
          data: {'data': tAuthResponseJson},
        ));

        // act
        await dataSource.register(
          name: tName,
          pName: tPharmacyName,
          email: tEmail,
          phone: tPhone,
          password: tPassword,
          licenseNumber: tLicenseNumber,
          city: tCity,
          address: tAddress,
          latitude: 5.3600,
          longitude: -4.0083,
        );

        // assert
        verify(() => mockApiClient.post(
          '/auth/register/pharmacy',
          data: {
            'name': tName,
            'pharmacy_name': tPharmacyName,
            'pharmacy_license': tLicenseNumber,
            'pharmacy_address': tAddress,
            'city': tCity,
            'email': 'test@example.com', // Lowercase
            'phone': tPhone,
            'password': tPassword,
            'password_confirmation': tPassword,
            'role': 'pharmacy',
            'latitude': 5.3600,
            'longitude': -4.0083,
          },
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).called(1);
      });

      test('should return AuthResponseModel on successful registration', () async {
        // arrange
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/register/pharmacy'),
          statusCode: 201,
          data: {'data': tAuthResponseJson},
        ));

        // act
        final result = await dataSource.register(
          name: tName,
          pName: tPharmacyName,
          email: tEmail,
          phone: tPhone,
          password: tPassword,
          licenseNumber: tLicenseNumber,
          city: tCity,
          address: tAddress,
          latitude: 5.3600,
          longitude: -4.0083,
        );

        // assert
        expect(result, isA<AuthResponseModel>());
        expect(result.token, equals('new_token_123'));
      });
    });

    group('logout', () {
      const tToken = 'test_token_123';

      test('should call apiClient.post with logout endpoint', () async {
        // arrange
        when(() => mockApiClient.authorizedOptions(any()))
            .thenReturn(Options(headers: {'Authorization': 'Bearer $tToken'}));
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/logout'),
          statusCode: 200,
          data: {'message': 'Logged out successfully'},
        ));

        // act
        await dataSource.logout(tToken);

        // assert
        verify(() => mockApiClient.post(
          '/auth/logout',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).called(1);
        verify(() => mockApiClient.authorizedOptions(tToken)).called(1);
      });
    });

    group('getCurrentUser', () {
      const tToken = 'test_token_123';
      final tUserJson = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '+225 0123456789',
      };

      test('should call apiClient.get with correct endpoint', () async {
        // arrange
        when(() => mockApiClient.authorizedOptions(any()))
            .thenReturn(Options(headers: {'Authorization': 'Bearer $tToken'}));
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 200,
          data: {'data': tUserJson},
        ));

        // act
        await dataSource.getCurrentUser(tToken);

        // assert
        verify(() => mockApiClient.get(
          '/auth/me',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).called(1);
        verify(() => mockApiClient.authorizedOptions(tToken)).called(1);
      });

      test('should return UserModel on success', () async {
        // arrange
        when(() => mockApiClient.authorizedOptions(any()))
            .thenReturn(Options(headers: {'Authorization': 'Bearer $tToken'}));
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 200,
          data: {'data': tUserJson},
        ));

        // act
        final result = await dataSource.getCurrentUser(tToken);

        // assert
        expect(result, isA<UserModel>());
        expect(result.id, equals(1));
        expect(result.name, equals('Test User'));
        expect(result.email, equals('test@example.com'));
      });
    });
  });
}
