import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/auth_session_service.dart';
import 'package:courier/core/services/secure_token_service.dart';

void main() {
  group('AuthSessionService', () {
    late AuthSessionService service;

    setUp(() {
      service = AuthSessionService.instance;
      SecureTokenService.enableTestMode({'auth_token': 'test-token'});
    });

    tearDown(() {
      SecureTokenService.disableTestMode();
    });

    test('is a singleton', () {
      expect(AuthSessionService.instance, same(service));
    });

    test('onSessionExpired emits expired state', () async {
      expectLater(
        service.sessionStream,
        emits(AuthSessionState.expired),
      );
      await service.onSessionExpired();
    });

    test('onSessionExpired removes auth token', () async {
      // Wait for any previous _isHandlingExpiration to reset
      await Future.delayed(const Duration(seconds: 3));

      SecureTokenService.enableTestMode({'auth_token': 'tok'});
      expect(await SecureTokenService.instance.getToken(), 'tok');

      await service.onSessionExpired();

      expect(await SecureTokenService.instance.getToken(), isNull);

      // Wait for the delayed reset
      await Future.delayed(const Duration(seconds: 3));
    });

    test('onLoggedOut emits loggedOut state', () async {
      expectLater(
        service.sessionStream,
        emits(AuthSessionState.loggedOut),
      );
      service.onLoggedOut();
    });

    test('onAuthenticated emits authenticated state', () async {
      expectLater(
        service.sessionStream,
        emits(AuthSessionState.authenticated),
      );
      service.onAuthenticated();
    });

    test('multiple rapid onSessionExpired calls only emit once', () async {
      // Wait for any previous handling to finish
      await Future.delayed(const Duration(seconds: 3));

      final events = <AuthSessionState>[];
      final sub = service.sessionStream.listen(events.add);

      // Call multiple times rapidly
      unawaited(service.onSessionExpired());
      unawaited(service.onSessionExpired());
      unawaited(service.onSessionExpired());

      await Future.delayed(const Duration(milliseconds: 500));
      sub.cancel();

      // Should only get 1 expired event thanks to _isHandlingExpiration guard
      expect(events.where((e) => e == AuthSessionState.expired).length, 1);

      // Wait for reset
      await Future.delayed(const Duration(seconds: 3));
    });
  });

  group('AuthSessionState', () {
    test('has all expected values', () {
      expect(AuthSessionState.values.length, 3);
      expect(AuthSessionState.values, contains(AuthSessionState.authenticated));
      expect(AuthSessionState.values, contains(AuthSessionState.expired));
      expect(AuthSessionState.values, contains(AuthSessionState.loggedOut));
    });
  });
}
