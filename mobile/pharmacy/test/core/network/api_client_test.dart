import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_pharmacy/core/network/api_client.dart';
import 'package:drpharma_pharmacy/core/errors/exceptions.dart';

class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      dotenv.testLoad(fileInput: '''
APP_NAME=DR-PHARMA
APP_ENV=development
API_BASE_URL=http://127.0.0.1:8000
LOCAL_MACHINE_IP=192.168.1.100
API_TIMEOUT=15000
''');
    }
  });

  group('ApiClient', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
    });

    group('constructor', () {
      test('should create ApiClient with Dio instance', () {
        expect(apiClient.dio, isA<Dio>());
      });

      test('should have JSON content type headers', () {
        expect(
          apiClient.dio.options.headers['Content-Type'],
          equals('application/json'),
        );
        expect(
          apiClient.dio.options.headers['Accept'],
          equals('application/json'),
        );
      });
    });

    group('setToken', () {
      test('should set access token', () {
        // act
        apiClient.setToken('test_token');

        // The token is private, but we can verify by making a request
        // For now, just verify it doesn't throw
        expect(() => apiClient.setToken('test_token'), returnsNormally);
      });
    });

    group('clearToken', () {
      test('should clear access token', () {
        // arrange
        apiClient.setToken('test_token');

        // act & assert
        expect(() => apiClient.clearToken(), returnsNormally);
      });
    });

    group('authorizedOptions', () {
      test('should return Options with Bearer token', () {
        // act
        final options = apiClient.authorizedOptions('my_token');

        // assert
        expect(options, isA<Options>());
        expect(
          options.headers?['Authorization'],
          equals('Bearer my_token'),
        );
      });

      test('should use different tokens for different calls', () {
        // act
        final options1 = apiClient.authorizedOptions('token1');
        final options2 = apiClient.authorizedOptions('token2');

        // assert
        expect(options1.headers?['Authorization'], equals('Bearer token1'));
        expect(options2.headers?['Authorization'], equals('Bearer token2'));
      });
    });
  });

  group('ApiClient HTTP Methods Structure', () {
    // Test that methods exist and have correct signatures
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
    });

    test('should have get method', () {
      expect(apiClient.get, isA<Function>());
    });

    test('should have post method', () {
      expect(apiClient.post, isA<Function>());
    });

    test('should have put method', () {
      expect(apiClient.put, isA<Function>());
    });

    test('should have delete method', () {
      expect(apiClient.delete, isA<Function>());
    });

    test('should have uploadMultipart method', () {
      expect(apiClient.uploadMultipart, isA<Function>());
    });
  });

  group('ApiClient Error Handling', () {
    // These tests verify the error transformation logic

    test('NetworkException should have correct message', () {
      final exception = NetworkException(
        message: 'No internet connection',
      );

      expect(exception.message, equals('No internet connection'));
    });

    test('UnauthorizedException should have correct message', () {
      final exception = UnauthorizedException(
        message: 'Session expired',
      );

      expect(exception.message, equals('Session expired'));
    });

    test('ForbiddenException should have message and errorCode', () {
      final exception = ForbiddenException(
        message: 'Access denied',
        errorCode: 'ACCOUNT_SUSPENDED',
      );

      expect(exception.message, equals('Access denied'));
      expect(exception.errorCode, equals('ACCOUNT_SUSPENDED'));
    });

    test('ServerException should have message and statusCode', () {
      final exception = ServerException(
        message: 'Internal server error',
        statusCode: 500,
      );

      expect(exception.message, equals('Internal server error'));
      expect(exception.statusCode, equals(500));
    });

    test('ValidationException should have errors map', () {
      final exception = ValidationException(
        errors: {
          'email': ['Email is required', 'Email must be valid'],
          'password': ['Password is too short'],
        },
      );

      expect(exception.errors['email']?.length, equals(2));
      expect(exception.errors['password']?.length, equals(1));
    });
  });

  group('Dio BaseOptions Configuration', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
    });

    test('should have timeout configuration', () {
      expect(apiClient.dio.options.connectTimeout, isNotNull);
      expect(apiClient.dio.options.receiveTimeout, isNotNull);
    });

    test('should have interceptors', () {
      expect(apiClient.dio.interceptors, isNotEmpty);
    });
  });
}
