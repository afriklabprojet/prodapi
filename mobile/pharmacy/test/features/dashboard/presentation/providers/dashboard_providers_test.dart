import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/dashboard/presentation/providers/dashboard_ui_provider.dart';
import 'package:drpharma_pharmacy/features/dashboard/presentation/providers/dashboard_tab_provider.dart';

void main() {
  group('selectedInfoTabProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('defaults to 0 (Finances)', () {
      expect(container.read(selectedInfoTabProvider), 0);
    });

    test('can switch to Orders tab (1)', () {
      container.read(selectedInfoTabProvider.notifier).state = 1;
      expect(container.read(selectedInfoTabProvider), 1);
    });

    test('can switch to Prescriptions tab (2)', () {
      container.read(selectedInfoTabProvider.notifier).state = 2;
      expect(container.read(selectedInfoTabProvider), 2);
    });

    test('can switch back to Finances (0)', () {
      container.read(selectedInfoTabProvider.notifier).state = 2;
      container.read(selectedInfoTabProvider.notifier).state = 0;
      expect(container.read(selectedInfoTabProvider), 0);
    });

    test('notifies listeners on change', () {
      final listener = Listener<int>();
      container.listen(
        selectedInfoTabProvider,
        listener.call,
        fireImmediately: true,
      );

      expect(listener.values, [0]);

      container.read(selectedInfoTabProvider.notifier).state = 1;
      expect(listener.values, [0, 1]);

      container.read(selectedInfoTabProvider.notifier).state = 2;
      expect(listener.values, [0, 1, 2]);
    });
  });

  group('dashboardTabProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('defaults to -1 (sentinel/idle)', () {
      expect(container.read(dashboardTabProvider), -1);
    });

    test('can be set to navigate to wallet tab (3)', () {
      container.read(dashboardTabProvider.notifier).state = 3;
      expect(container.read(dashboardTabProvider), 3);
    });

    test('can be reset to idle (-1)', () {
      container.read(dashboardTabProvider.notifier).state = 3;
      container.read(dashboardTabProvider.notifier).state = -1;
      expect(container.read(dashboardTabProvider), -1);
    });
  });
}

/// Simple listener that collects emitted values for assertions.
class Listener<T> {
  final List<T> values = [];

  void call(T? previous, T next) {
    values.add(next);
  }
}
