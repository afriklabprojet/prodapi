import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/core/services/delivery_alert_service.dart';

void main() {
  group('DeliveryAlertActiveNotifier', () {
    test('initial state is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(deliveryAlertActiveProvider), false);
    });

    test('activate sets state to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(deliveryAlertActiveProvider.notifier).activate();
      expect(container.read(deliveryAlertActiveProvider), true);
    });

    test('deactivate sets state to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(deliveryAlertActiveProvider.notifier).activate();
      container.read(deliveryAlertActiveProvider.notifier).deactivate();
      expect(container.read(deliveryAlertActiveProvider), false);
    });

    test('multiple activations stay true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(deliveryAlertActiveProvider.notifier).activate();
      container.read(deliveryAlertActiveProvider.notifier).activate();
      expect(container.read(deliveryAlertActiveProvider), true);
    });

    test('activate then deactivate then activate returns true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(deliveryAlertActiveProvider.notifier).activate();
      container.read(deliveryAlertActiveProvider.notifier).deactivate();
      container.read(deliveryAlertActiveProvider.notifier).activate();
      expect(container.read(deliveryAlertActiveProvider), true);
    });
  });

  group('DeliveryAlertActiveNotifier - edge cases', () {
    test('deactivate when already inactive stays false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Deactivate without ever activating
      container.read(deliveryAlertActiveProvider.notifier).deactivate();
      expect(container.read(deliveryAlertActiveProvider), false);
    });

    test('rapid toggle maintains correct state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(deliveryAlertActiveProvider.notifier);

      // Rapid toggling
      notifier.activate();
      notifier.deactivate();
      notifier.activate();
      notifier.deactivate();
      notifier.activate();

      expect(container.read(deliveryAlertActiveProvider), true);
    });

    test('provider is preserved across multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(deliveryAlertActiveProvider.notifier).activate();

      // Multiple reads should return same state
      expect(container.read(deliveryAlertActiveProvider), true);
      expect(container.read(deliveryAlertActiveProvider), true);
      expect(container.read(deliveryAlertActiveProvider), true);
    });

    test('separate containers have independent state', () {
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();
      addTearDown(container1.dispose);
      addTearDown(container2.dispose);

      container1.read(deliveryAlertActiveProvider.notifier).activate();

      expect(container1.read(deliveryAlertActiveProvider), true);
      expect(container2.read(deliveryAlertActiveProvider), false);
    });

    test('notifier returns same instance across reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier1 = container.read(deliveryAlertActiveProvider.notifier);
      final notifier2 = container.read(deliveryAlertActiveProvider.notifier);

      expect(identical(notifier1, notifier2), true);
    });
  });

  // Note: DeliveryAlertService depends on AudioPlayer which requires
  // platform channels. Direct unit tests would require mocking audioplayers.
  // Widget tests or integration tests should cover the service functionality.
}
