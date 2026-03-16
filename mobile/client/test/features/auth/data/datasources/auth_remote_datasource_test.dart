import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/network/api_client.dart';
import 'package:drpharma_client/core/constants/api_constants.dart';
import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:drpharma_client/features/auth/data/models/auth_response_model.dart';
import 'package:drpharma_client/features/auth/data/models/user_model.dart';

import 'auth_remote_datasource_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = AuthRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  // Test data fixtures
  final tUserModel = UserModel(
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
    phone: '+221771234567',
    role: 'customer',
    avatar: null,
    emailVerifiedAt: '2024-01-01T00:00:00Z',
    phoneVerifiedAt: '2024-01-01T00:00:00Z',
    createdAt: '2024-01-01T00:00:00Z',
  );

  final tAuthResponse = {
    'data': {
      'user': {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '+221771234567',
        'role': 'customer',
        'avatar': null,
        'email_verified_at': '2024-01-01T00:00:00Z',
        'phone_verified_at': '2024-01-01T00:00:00Z',
        'created_at': '2024-01-01T00:00:00Z',
      },
      'token': 'test_token_123',
    }
  };

  group('login', () {
    const tEmail = 'Test@Example.com';
    const tPassword = 'password123';

    test('should normalize email to lowercase and call API', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: tAuthResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.login),
          ));

      // Act
      final result = await dataSource.login(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(result.token, 'test_token_123');
      expect(result.user.email, 'test@example.com');
      
      // Verify normalized email was sent
      verify(mockApiClient.post(
        ApiConstants.login,
        data: argThat(
          predicate<Map<String, dynamic>>((data) =>
              data['email'] == 'test@example.com' &&
              data['password'] == tPassword &&
              data['role'] == 'customer'),
          named: 'data',
        ),
        options: anyNamed('options'),
      )).called(1);
    });

    test('should return AuthResponseModel on successful login', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: tAuthResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.login),
          ));

      // Act
      final result = await dataSource.login(
        email: 'test@example.com',
        password: tPassword,
      );

      // Assert
      expect(result, isA<AuthResponseModel>());
      expect(result.token, 'test_token_123');
      expect(result.user.name, 'Test User');
      expect(result.user.id, 1);
    });

    test('should throw exception when API call fails', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenThrow(ServerException(message: 'Server error', statusCode: 500));

      // Act & Assert
      expect(
        () => dataSource.login(email: 'test@example.com', password: tPassword),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw UnauthorizedException on 401', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenThrow(UnauthorizedException(message: 'Invalid credentials'));

      // Act & Assert
      expect(
        () => dataSource.login(email: 'test@example.com', password: 'wrong'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('register', () {
    const tName = 'Test User';
    const tEmail = 'NEW@EXAMPLE.COM';
    const tPhone = '+221771234567';
    const tPassword = 'password123';

    test('should normalize email to lowercase during registration', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: tAuthResponse,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.register),
          ));

      // Act
      await dataSource.register(
        name: tName,
        email: tEmail,
        phone: tPhone,
        password: tPassword,
      );

      // Assert
      verify(mockApiClient.post(
        ApiConstants.register,
        data: argThat(
          predicate<Map<String, dynamic>>((data) =>
              data['email'] == 'new@example.com' &&
              data['password_confirmation'] == tPassword),
          named: 'data',
        ),
        options: anyNamed('options'),
      )).called(1);
    });

    test('should include address when provided', () async {
      // Arrange
      const tAddress = 'Dakar, Senegal';
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: tAuthResponse,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.register),
          ));

      // Act
      await dataSource.register(
        name: tName,
        email: tEmail,
        phone: tPhone,
        password: tPassword,
        address: tAddress,
      );

      // Assert
      verify(mockApiClient.post(
        ApiConstants.register,
        data: argThat(
          predicate<Map<String, dynamic>>((data) =>
              data['address'] == tAddress),
          named: 'data',
        ),
        options: anyNamed('options'),
      )).called(1);
    });

    test('should not include address when null', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: tAuthResponse,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.register),
          ));

      // Act
      await dataSource.register(
        name: tName,
        email: tEmail,
        phone: tPhone,
        password: tPassword,
      );

      // Assert
      verify(mockApiClient.post(
        ApiConstants.register,
        data: argThat(
          predicate<Map<String, dynamic>>((data) =>
              !data.containsKey('address')),
          named: 'data',
        ),
        options: anyNamed('options'),
      )).called(1);
    });

    test('should throw ValidationException on 422', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenThrow(ValidationException(errors: {
        'email': ['Email already taken'],
      }));

      // Act & Assert
      expect(
        () => dataSource.register(
          name: tName,
          email: tEmail,
          phone: tPhone,
          password: tPassword,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('logout', () {
    const tToken = 'test_token_123';

    test('should call API with authorization header', () async {
      // Arrange
      when(mockApiClient.authorizedOptions(any))
          .thenReturn(Options(headers: {'Authorization': 'Bearer $tToken'}));
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {'message': 'Logged out'},
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.logout),
          ));

      // Act
      await dataSource.logout(tToken);

      // Assert
      verify(mockApiClient.authorizedOptions(tToken)).called(1);
      verify(mockApiClient.post(
        ApiConstants.logout,
        options: anyNamed('options'),
      )).called(1);
    });
  });

  group('getCurrentUser', () {
    const tToken = 'test_token_123';

    test('should return UserModel on success', () async {
      // Arrange
      when(mockApiClient.authorizedOptions(any))
          .thenReturn(Options(headers: {'Authorization': 'Bearer $tToken'}));
      when(mockApiClient.get(
        any,
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {'data': tUserModel.toJson()},
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.me),
          ));

      // Act
      final result = await dataSource.getCurrentUser(tToken);

      // Assert
      expect(result, isA<UserModel>());
      expect(result.id, 1);
      expect(result.email, 'test@example.com');
      verify(mockApiClient.authorizedOptions(tToken)).called(1);
    });

    test('should throw UnauthorizedException when token is invalid', () async {
      // Arrange
      when(mockApiClient.authorizedOptions(any))
          .thenReturn(Options(headers: {'Authorization': 'Bearer invalid'}));
      when(mockApiClient.get(
        any,
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenThrow(UnauthorizedException(message: 'Invalid token'));

      // Act & Assert
      expect(
        () => dataSource.getCurrentUser('invalid_token'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('verifyOtp', () {
    const tIdentifier = '+221771234567';
    const tOtp = '123456';

    test('should return AuthResponseModel on successful verification', () async {
      // Arrange
      final otpResponse = {
        'user': tUserModel.toJson(),
        'token': 'verified_token_123',
      };
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: otpResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.verifyOtp),
          ));

      // Act
      final result = await dataSource.verifyOtp(
        identifier: tIdentifier,
        otp: tOtp,
      );

      // Assert
      expect(result, isA<AuthResponseModel>());
      expect(result.token, 'verified_token_123');
      verify(mockApiClient.post(
        ApiConstants.verifyOtp,
        data: {'identifier': tIdentifier, 'otp': tOtp},
        options: anyNamed('options'),
      )).called(1);
    });
  });

  group('resendOtp', () {
    const tIdentifier = '+221771234567';

    test('should return message and channel from API', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {
              'message': 'OTP sent successfully',
              'channel': 'sms',
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.resendOtp),
          ));

      // Act
      final result = await dataSource.resendOtp(identifier: tIdentifier);

      // Assert
      expect(result['message'], 'OTP sent successfully');
      expect(result['channel'], 'sms');
    });

    test('should use default values when API response is missing fields', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: <String, dynamic>{},
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.resendOtp),
          ));

      // Act
      final result = await dataSource.resendOtp(identifier: tIdentifier);

      // Assert
      expect(result['message'], 'Code envoyé');
      expect(result['channel'], 'sms');
    });
  });

  group('forgotPassword', () {
    const tEmail = 'TEST@EXAMPLE.COM';

    test('should normalize email to lowercase', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {'message': 'Reset email sent'},
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.forgotPassword),
          ));

      // Act
      await dataSource.forgotPassword(email: tEmail);

      // Assert
      verify(mockApiClient.post(
        ApiConstants.forgotPassword,
        data: {'email': 'test@example.com'},
        options: anyNamed('options'),
      )).called(1);
    });
  });

  group('updatePassword', () {
    const tCurrentPassword = 'old_password';
    const tNewPassword = 'new_password';

    test('should send both passwords with confirmation', () async {
      // Arrange
      when(mockApiClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {'message': 'Password updated'},
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.updatePassword),
          ));

      // Act
      await dataSource.updatePassword(
        currentPassword: tCurrentPassword,
        newPassword: tNewPassword,
      );

      // Assert
      verify(mockApiClient.post(
        ApiConstants.updatePassword,
        data: {
          'current_password': tCurrentPassword,
          'new_password': tNewPassword,
          'new_password_confirmation': tNewPassword,
        },
        options: anyNamed('options'),
      )).called(1);
    });
  });
}
