import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/app_startup_service.dart';

void main() {
  group('StartupResult', () {
    test('has 3 values', () {
      expect(StartupResult.values.length, 3);
    });

    test('contains all expected values', () {
      expect(StartupResult.values, contains(StartupResult.onboarding));
      expect(StartupResult.values, contains(StartupResult.unauthenticated));
      expect(StartupResult.values, contains(StartupResult.authenticated));
    });

    test('onboarding index is 0', () {
      expect(StartupResult.onboarding.index, 0);
    });

    test('unauthenticated index is 1', () {
      expect(StartupResult.unauthenticated.index, 1);
    });

    test('authenticated index is 2', () {
      expect(StartupResult.authenticated.index, 2);
    });

    test('values are distinct', () {
      expect(StartupResult.onboarding, isNot(StartupResult.unauthenticated));
      expect(StartupResult.onboarding, isNot(StartupResult.authenticated));
      expect(StartupResult.unauthenticated, isNot(StartupResult.authenticated));
    });
  });

  group('StartupResult - additional', () {
    test('toString returns expected format', () {
      expect(StartupResult.onboarding.toString(), 'StartupResult.onboarding');
      expect(
        StartupResult.unauthenticated.toString(),
        'StartupResult.unauthenticated',
      );
      expect(
        StartupResult.authenticated.toString(),
        'StartupResult.authenticated',
      );
    });

    test('name returns enum name', () {
      expect(StartupResult.onboarding.name, 'onboarding');
      expect(StartupResult.unauthenticated.name, 'unauthenticated');
      expect(StartupResult.authenticated.name, 'authenticated');
    });

    test('values list has correct order', () {
      expect(StartupResult.values[0], StartupResult.onboarding);
      expect(StartupResult.values[1], StartupResult.unauthenticated);
      expect(StartupResult.values[2], StartupResult.authenticated);
    });

    test('equality by identity', () {
      expect(
        identical(StartupResult.onboarding, StartupResult.onboarding),
        isTrue,
      );
    });
  });
}
