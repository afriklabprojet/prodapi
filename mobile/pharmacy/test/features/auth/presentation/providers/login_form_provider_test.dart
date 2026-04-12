import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_pharmacy/core/providers/core_providers.dart';
import 'package:drpharma_pharmacy/features/auth/presentation/providers/login_form_provider.dart';
import 'package:drpharma_pharmacy/features/auth/presentation/providers/state/login_form_state.dart';

void main() {
  group('LoginFormNotifier', () {
    test('initializes without uninitialized Riverpod state errors', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(() => container.read(loginFormProvider), returnsNormally);

      await Future<void>.delayed(Duration.zero);

      expect(container.read(loginFormProvider), isA<LoginFormState>());
    });

    test(
      'async initialization remains safe after container disposal',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );

        container.read(loginFormProvider);
        container.dispose();

        await Future<void>.delayed(Duration.zero);

        expect(true, isTrue);
      },
    );
  });
}
