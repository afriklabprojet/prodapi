import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/secure_token_service.dart';

void main() {
  late SecureTokenService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureTokenService.enableTestMode();
    service = SecureTokenService.instance;
  });

  tearDown(() {
    SecureTokenService.disableTestMode();
  });

  group('SecureTokenService', () {
    test('getToken returns null initially', () async {
      final token = await service.getToken();
      expect(token, isNull);
    });

    test('setToken stores token', () async {
      await service.setToken('test-token-123');
      final token = await service.getToken();
      expect(token, 'test-token-123');
    });

    test(
      'cachedToken returns null in test mode and token is retrievable',
      () async {
        await service.setToken('cached-token');
        expect(service.cachedToken, isNull);
        expect(await service.getToken(), 'cached-token');
      },
    );

    test('removeToken clears token', () async {
      await service.setToken('to-remove');
      await service.removeToken();
      final token = await service.getToken();
      expect(token, isNull);
    });

    test('hasToken returns false initially', () async {
      expect(await service.hasToken(), false);
    });

    test('hasToken returns true after setToken', () async {
      await service.setToken('some-token');
      expect(await service.hasToken(), true);
    });

    test('getRefreshToken returns null initially', () async {
      final token = await service.getRefreshToken();
      expect(token, isNull);
    });

    test('setRefreshToken stores refresh token', () async {
      await service.setRefreshToken('refresh-123');
      final token = await service.getRefreshToken();
      expect(token, 'refresh-123');
    });

    test('removeRefreshToken clears refresh token', () async {
      await service.setRefreshToken('refresh-to-remove');
      await service.removeRefreshToken();
      final token = await service.getRefreshToken();
      expect(token, isNull);
    });

    test('enableTestMode with initial data', () {
      SecureTokenService.disableTestMode();
      SecureTokenService.enableTestMode({
        'auth_token': 'pre-set-token',
        'refresh_token': 'pre-set-refresh',
      });
      final svc = SecureTokenService.instance;
      expect(svc.getToken(), completion('pre-set-token'));
      expect(svc.getRefreshToken(), completion('pre-set-refresh'));
    });

    test('hasTokenSync checks SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'has_auth_token': true});
      final prefs = await SharedPreferences.getInstance();
      expect(SecureTokenService.hasTokenSync(prefs), true);
    });
  });
}
