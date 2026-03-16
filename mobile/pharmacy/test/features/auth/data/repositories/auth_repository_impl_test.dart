import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_pharmacy/core/errors/exceptions.dart';
import 'package:drpharma_pharmacy/core/errors/failure.dart';
import 'package:drpharma_pharmacy/core/network/api_client.dart';
import 'package:drpharma_pharmacy/core/network/network_info.dart';
import 'package:drpharma_pharmacy/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:drpharma_pharmacy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:drpharma_pharmacy/features/auth/data/models/auth_response_model.dart';
import 'package:drpharma_pharmacy/features/auth/data/models/user_model.dart';
import 'package:drpharma_pharmacy/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/auth_response_entity.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/user_entity.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockApiClient mockApiClient;

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(const UserModel(
      id: 0,
      name: '',
      email: '',
      phone: '',
    ));
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockApiClient = MockApiClient();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
      apiClient: mockApiClient,
    );
  });

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

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tToken = 'test_token_123';

  group('login', () {
    test('should check if the device is online', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => tAuthResponseModel);
      when(() => mockLocalDataSource.cacheToken(any()))
          .thenAnswer((_) async => {});
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async => {});
      when(() => mockApiClient.setToken(any())).thenReturn(null);

      // act
      await repository.login(email: tEmail, password: tPassword);

      // assert
      verify(() => mockNetworkInfo.isConnected);
    });

    group('device is online', () {
      setUp(() {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });

      test('should return AuthResponseEntity when login is successful',
          () async {
        // arrange
        when(() => mockRemoteDataSource.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => tAuthResponseModel);
        when(() => mockLocalDataSource.cacheToken(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.cacheUser(any()))
            .thenAnswer((_) async => {});
        when(() => mockApiClient.setToken(any())).thenReturn(null);

        // act
        final result =
            await repository.login(email: tEmail, password: tPassword);

        // assert
        verify(() => mockRemoteDataSource.login(
              email: tEmail,
              password: tPassword,
            ));
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right'),
          (authResponse) {
            expect(authResponse, isA<AuthResponseEntity>());
            expect(authResponse.token, tAuthResponseModel.token);
          },
        );
      });

      test('should cache token and user after successful login', () async {
        // arrange
        when(() => mockRemoteDataSource.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => tAuthResponseModel);
        when(() => mockLocalDataSource.cacheToken(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.cacheUser(any()))
            .thenAnswer((_) async => {});
        when(() => mockApiClient.setToken(any())).thenReturn(null);

        // act
        await repository.login(email: tEmail, password: tPassword);

        // assert
        verify(() => mockLocalDataSource.cacheToken(tAuthResponseModel.token));
        verify(() => mockLocalDataSource.cacheUser(tAuthResponseModel.user));
        verify(() => mockApiClient.setToken(tAuthResponseModel.token));
      });

      test('should return ServerFailure when ServerException is thrown',
          () async {
        // arrange
        when(() => mockRemoteDataSource.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(ServerException(message: 'Server error'));

        // act
        final result =
            await repository.login(email: tEmail, password: tPassword);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect((failure as ServerFailure).message, 'Server error');
          },
          (_) => fail('Expected Left'),
        );
      });

      test(
          'should return UnauthorizedFailure when UnauthorizedException is thrown',
          () async {
        // arrange
        when(() => mockRemoteDataSource.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(UnauthorizedException(message: 'Invalid credentials'));

        // act
        final result =
            await repository.login(email: tEmail, password: tPassword);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<UnauthorizedFailure>());
            expect(
                (failure as UnauthorizedFailure).message, 'Invalid credentials');
          },
          (_) => fail('Expected Left'),
        );
      });

      test('should return ForbiddenFailure when ForbiddenException is thrown',
          () async {
        // arrange
        when(() => mockRemoteDataSource.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(ForbiddenException(
                message: 'Account not approved',
                errorCode: 'PHARMACY_NOT_APPROVED'));

        // act
        final result =
            await repository.login(email: tEmail, password: tPassword);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ForbiddenFailure>());
            expect((failure as ForbiddenFailure).message, 'Account not approved');
            expect(failure.errorCode, 'PHARMACY_NOT_APPROVED');
          },
          (_) => fail('Expected Left'),
        );
      });

      test(
          'should return ValidationFailure when ValidationException is thrown',
          () async {
        // arrange
        when(() => mockRemoteDataSource.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(
            ValidationException(errors: {'email': ['Invalid email format']}));

        // act
        final result =
            await repository.login(email: tEmail, password: tPassword);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors['email'],
                ['Invalid email format']);
          },
          (_) => fail('Expected Left'),
        );
      });
    });

    group('device is offline', () {
      test('should return NetworkFailure when device is offline', () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // act
        final result =
            await repository.login(email: tEmail, password: tPassword);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
          },
          (_) => fail('Expected Left'),
        );
      });
    });
  });

  group('logout', () {
    group('device is online', () {
      setUp(() {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });

      test('should logout successfully when online', () async {
        // arrange
        when(() => mockLocalDataSource.getToken())
            .thenAnswer((_) async => tToken);
        when(() => mockRemoteDataSource.logout(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.clearAuthData())
            .thenAnswer((_) async => {});
        when(() => mockApiClient.clearToken()).thenReturn(null);

        // act
        final result = await repository.logout();

        // assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.logout(tToken));
        verify(() => mockLocalDataSource.clearAuthData());
        verify(() => mockApiClient.clearToken());
      });

      test('should still clear local data even if remote logout fails',
          () async {
        // arrange
        when(() => mockLocalDataSource.getToken())
            .thenAnswer((_) async => tToken);
        when(() => mockRemoteDataSource.logout(any()))
            .thenThrow(ServerException(message: 'Server error'));
        when(() => mockLocalDataSource.clearAuthData())
            .thenAnswer((_) async => {});
        when(() => mockApiClient.clearToken()).thenReturn(null);

        // act
        final result = await repository.logout();

        // assert
        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.clearAuthData());
        verify(() => mockApiClient.clearToken());
      });
    });

    group('device is offline', () {
      test('should clear local data when offline', () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.clearAuthData())
            .thenAnswer((_) async => {});
        when(() => mockApiClient.clearToken()).thenReturn(null);

        // act
        final result = await repository.logout();

        // assert
        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.clearAuthData());
        verify(() => mockApiClient.clearToken());
        verifyNever(() => mockRemoteDataSource.logout(any()));
      });
    });
  });

  group('getCurrentUser', () {
    test('should return cached user when available', () async {
      // arrange
      when(() => mockLocalDataSource.getToken())
          .thenAnswer((_) async => tToken);
      when(() => mockLocalDataSource.getUser())
          .thenAnswer((_) async => tUserModel);
      when(() => mockApiClient.setToken(any())).thenReturn(null);

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (user) {
          expect(user, isA<UserEntity>());
          expect(user.email, tUserModel.email);
        },
      );
    });

    test('should fetch user from remote when no local user but has token',
        () async {
      // arrange
      when(() => mockLocalDataSource.getToken())
          .thenAnswer((_) async => tToken);
      when(() => mockLocalDataSource.getUser()).thenAnswer((_) async => null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getCurrentUser(any()))
          .thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async => {});
      when(() => mockApiClient.setToken(any())).thenReturn(null);

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.getCurrentUser(tToken));
      verify(() => mockLocalDataSource.cacheUser(tUserModel));
    });

    test('should return CacheFailure when no token and no user', () async {
      // arrange
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => null);
      when(() => mockLocalDataSource.getUser()).thenAnswer((_) async => null);

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
        },
        (_) => fail('Expected Left'),
      );
    });
  });

  group('checkAuthStatus', () {
    test('should return false when no token', () async {
      // arrange
      when(() => mockLocalDataSource.hasToken())
          .thenAnswer((_) async => false);

      // act
      final result = await repository.checkAuthStatus();

      // assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (isAuthenticated) {
          expect(isAuthenticated, false);
        },
      );
    });

    test('should return true when has valid token and offline', () async {
      // arrange
      when(() => mockLocalDataSource.hasToken()).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => 'valid_token');
      when(() => mockApiClient.setToken(any())).thenReturn(null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.checkAuthStatus();

      // assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (isAuthenticated) {
          expect(isAuthenticated, true);
        },
      );
    });

    test('should verify token with server when online', () async {
      // arrange
      when(() => mockLocalDataSource.hasToken()).thenAnswer((_) async => true);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getToken())
          .thenAnswer((_) async => tToken);
      when(() => mockRemoteDataSource.getCurrentUser(any()))
          .thenAnswer((_) async => tUserModel);

      // act
      final result = await repository.checkAuthStatus();

      // assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (isAuthenticated) {
          expect(isAuthenticated, true);
        },
      );
      verify(() => mockRemoteDataSource.getCurrentUser(tToken));
    });

    test('should clear auth and return false when token is invalid', () async {
      // arrange
      when(() => mockLocalDataSource.hasToken()).thenAnswer((_) async => true);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getToken())
          .thenAnswer((_) async => tToken);
      when(() => mockRemoteDataSource.getCurrentUser(any()))
          .thenThrow(UnauthorizedException(message: 'Invalid token'));
      when(() => mockLocalDataSource.clearAuthData())
          .thenAnswer((_) async => {});

      // act
      final result = await repository.checkAuthStatus();

      // assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (isAuthenticated) {
          expect(isAuthenticated, false);
        },
      );
      verify(() => mockLocalDataSource.clearAuthData());
    });
  });
}
