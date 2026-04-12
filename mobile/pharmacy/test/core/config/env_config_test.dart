import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drpharma_pharmacy/core/config/env_config.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // If .env not found, set test defaults
      dotenv.testLoad(
        fileInput: '''
APP_NAME=DR-PHARMA
APP_ENV=development
API_BASE_URL=http://127.0.0.1:8000
LOCAL_MACHINE_IP=192.168.1.100
API_TIMEOUT=15000
''',
      );
    }
  });

  group('EnvConfig', () {
    group('Environment Detection', () {
      test('isDevelopment should return a boolean', () {
        expect(EnvConfig.isDevelopment, isA<bool>());
      });

      test('isProduction should be opposite of isDevelopment', () {
        expect(EnvConfig.isProduction, equals(!EnvConfig.isDevelopment));
      });

      test('environment should return development or production string', () {
        final env = EnvConfig.environment;
        expect(env == 'development' || env == 'production', isTrue);
      });

      test('isDebugMode should match isDevelopment', () {
        expect(EnvConfig.isDebugMode, equals(EnvConfig.isDevelopment));
      });
    });

    group('URL Configuration', () {
      test('baseUrl should return a valid URL string', () {
        final url = EnvConfig.baseUrl;
        expect(url, isA<String>());
        expect(url.startsWith('http'), isTrue);
      });

      test('apiBaseUrl should append /api to baseUrl', () {
        final apiUrl = EnvConfig.apiBaseUrl;
        expect(apiUrl, equals('${EnvConfig.baseUrl}/api'));
      });

      test('storageBaseUrl should append /storage/ to baseUrl', () {
        final storageUrl = EnvConfig.storageBaseUrl;
        expect(storageUrl, equals('${EnvConfig.baseUrl}/storage/'));
      });

      test('setOverrideBaseUrl should override baseUrl', () {
        // arrange
        final originalUrl = EnvConfig.baseUrl;

        // act
        EnvConfig.setOverrideBaseUrl('http://custom.api.com');
        final overriddenUrl = EnvConfig.baseUrl;

        // cleanup
        EnvConfig.setOverrideBaseUrl(null);
        final restoredUrl = EnvConfig.baseUrl;

        // assert
        expect(overriddenUrl, equals('http://custom.api.com'));
        expect(restoredUrl, equals(originalUrl));
      });

      test('setOverrideBaseUrl with empty string should not override', () {
        // arrange
        final originalUrl = EnvConfig.baseUrl;

        // act
        EnvConfig.setOverrideBaseUrl('');
        final result = EnvConfig.baseUrl;

        // cleanup
        EnvConfig.setOverrideBaseUrl(null);

        // assert
        expect(result, equals(originalUrl));
      });
    });

    group('Timeout Configuration', () {
      test('apiTimeout should return a positive integer', () {
        expect(EnvConfig.apiTimeout, isA<int>());
        expect(EnvConfig.apiTimeout, greaterThan(0));
      });

      test('apiTimeout should be 15 seconds', () {
        expect(EnvConfig.apiTimeout, equals(15000));
      });
    });

    group('Initialization', () {
      test('init should not throw', () async {
        // act & assert
        await expectLater(EnvConfig.init(), completes);
      });

      test('isInitialized should be true after init', () async {
        // act
        await EnvConfig.init();

        // assert
        expect(EnvConfig.isInitialized, isTrue);
      });

      test('init with environment parameter should not throw', () async {
        // act & assert
        await expectLater(
          EnvConfig.init(environment: 'development'),
          completes,
        );
      });
    });

    group('Local Machine IP', () {
      test('localMachineIP should be a valid IP format', () {
        final ip = EnvConfig.localMachineIP;
        expect(ip, isA<String>());
        // Basic IP format check
        final parts = ip.split('.');
        expect(parts.length, equals(4));
      });
    });
  });
}
