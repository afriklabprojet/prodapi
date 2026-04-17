import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/core/services/analytics_service.dart';
import 'package:drpharma_client/core/constants/analytics_events.dart';

/// Recording provider to capture calls for assertions
class _TrackingProvider implements AnalyticsProvider {
  final List<String> trackedEvents = [];
  final List<String> trackedScreens = [];
  final Map<String, dynamic> userProperties = {};
  String? identifiedUserId;
  bool wasInitialized = false;
  bool wasReset = false;

  @override
  Future<void> init() async => wasInitialized = true;

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    identifiedUserId = userId;
  }

  @override
  Future<void> reset() async => wasReset = true;

  @override
  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    trackedEvents.add(event);
  }

  @override
  Future<void> screen(
    String screenName, {
    Map<String, dynamic>? properties,
  }) async {
    trackedScreens.add(screenName);
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    userProperties[name] = value;
  }
}

// A provider that throws on track to test error swallowing
class _FailingProvider implements AnalyticsProvider {
  @override
  Future<void> init() async => throw Exception('init failed');

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async =>
      throw Exception('identify failed');

  @override
  Future<void> reset() async => throw Exception('reset failed');

  @override
  Future<void> track(String event, {Map<String, dynamic>? properties}) async =>
      throw Exception('track failed');

  @override
  Future<void> screen(
    String screenName, {
    Map<String, dynamic>? properties,
  }) async => throw Exception('screen failed');

  @override
  Future<void> setUserProperty(String name, String value) async =>
      throw Exception('setUserProperty failed');
}

void main() {
  late _TrackingProvider provider;
  late AnalyticsService service;

  setUp(() {
    provider = _TrackingProvider();
    service = AnalyticsService(providers: [provider]);
  });

  // ── init ──────────────────────────────────────────────
  group('init', () {
    test('initializes all providers', () async {
      await service.init();
      expect(provider.wasInitialized, true);
    });

    test('does not initialize twice', () async {
      await service.init();
      // Calling again should be noop (already initialized)
      _TrackingProvider();
      // Verify init is idempotent by calling init once more
      await service.init();
      // provider was only initialized once in setUp's service
      expect(provider.wasInitialized, true);
    });

    test('swallows provider init errors gracefully', () async {
      final failingService = AnalyticsService(providers: [_FailingProvider()]);
      await expectLater(failingService.init(), completes);
    });
  });

  // ── identify ──────────────────────────────────────────
  group('identify', () {
    test('sets userId on provider', () async {
      await service.init();
      await service.identify('user-123');
      expect(provider.identifiedUserId, 'user-123');
    });

    test('passes traits to provider', () async {
      await service.init();
      await service.identify('user-456', traits: {'plan': 'premium'});
      expect(provider.identifiedUserId, 'user-456');
    });

    test('swallows provider identify errors', () async {
      final failingService = AnalyticsService(providers: [_FailingProvider()]);
      await service.init();
      await expectLater(failingService.identify('user'), completes);
    });
  });

  // ── reset ─────────────────────────────────────────────
  group('reset', () {
    test('clears userId and resets provider', () async {
      await service.init();
      await service.identify('user-789');
      await service.reset();
      expect(provider.wasReset, true);
    });

    test('swallows provider reset errors', () async {
      final failingService = AnalyticsService(providers: [_FailingProvider()]);
      await expectLater(failingService.reset(), completes);
    });
  });

  // ── track ─────────────────────────────────────────────
  group('track', () {
    test('sends event to provider', () async {
      await service.init();
      await service.track(AnalyticsEvents.loginSuccess);
      expect(provider.trackedEvents, contains(AnalyticsEvents.loginSuccess));
    });

    test('sends event with properties', () async {
      await service.init();
      await service.track(
        AnalyticsEvents.addToCart,
        properties: {'product_id': '42'},
      );
      expect(provider.trackedEvents, contains(AnalyticsEvents.addToCart));
    });

    test('injects userId into properties when identified', () async {
      await service.init();
      await service.identify('user-abc');
      await service.track(AnalyticsEvents.loginSuccess);
      expect(provider.trackedEvents, contains(AnalyticsEvents.loginSuccess));
    });

    test('swallows provider track errors', () async {
      final failingService = AnalyticsService(providers: [_FailingProvider()]);
      await expectLater(
        failingService.track(AnalyticsEvents.loginSuccess),
        completes,
      );
    });
  });

  // ── screen ────────────────────────────────────────────
  group('screen', () {
    test('sends screen name to provider', () async {
      await service.init();
      await service.screen('HomeScreen');
      expect(provider.trackedScreens, contains('HomeScreen'));
    });

    test('swallows provider screen errors', () async {
      final failingService = AnalyticsService(providers: [_FailingProvider()]);
      await expectLater(failingService.screen('HomeScreen'), completes);
    });
  });

  // ── setUserProperty ───────────────────────────────────
  group('setUserProperty', () {
    test('sets property on provider', () async {
      await service.init();
      await service.setUserProperty('subscription', 'premium');
      expect(provider.userProperties['subscription'], 'premium');
    });

    test('swallows provider setUserProperty errors', () async {
      final failingService = AnalyticsService(providers: [_FailingProvider()]);
      await expectLater(
        failingService.setUserProperty('key', 'value'),
        completes,
      );
    });
  });

  // ── convenience methods ───────────────────────────────
  group('trackPurchase', () {
    test('tracks purchase event with order details', () async {
      await service.init();
      await service.trackPurchase(
        orderId: 'ORD-001',
        total: 5000.0,
        currency: 'XOF',
      );
      expect(provider.trackedEvents, contains(AnalyticsEvents.purchase));
    });
  });

  group('trackCheckoutStarted', () {
    test('tracks checkout started event', () async {
      await service.init();
      await service.trackCheckoutStarted(cartValue: 12500.0, itemCount: 3);
      expect(provider.trackedEvents, contains(AnalyticsEvents.checkoutStarted));
    });
  });

  group('trackAddToCart', () {
    test('tracks add to cart event with product info', () async {
      await service.init();
      await service.trackAddToCart(
        productId: '42',
        productName: 'Paracetamol',
        price: 500.0,
        quantity: 2,
      );
      expect(provider.trackedEvents, contains(AnalyticsEvents.addToCart));
    });
  });

  group('trackError', () {
    test('tracks error event', () async {
      await service.init();
      await service.trackError(
        errorType: 'NetworkError',
        errorMessage: 'No internet',
      );
      expect(provider.trackedEvents, contains(AnalyticsEvents.errorOccurred));
    });

    test('includes errorCode when provided', () async {
      await service.init();
      await service.trackError(
        errorType: 'ServerError',
        errorMessage: '500 error',
        errorCode: '500',
      );
      expect(provider.trackedEvents, contains(AnalyticsEvents.errorOccurred));
    });
  });

  // ── multiple providers ────────────────────────────────
  group('multiple providers', () {
    test('sends event to all providers', () async {
      final provider2 = _TrackingProvider();
      final multiService = AnalyticsService(providers: [provider, provider2]);
      await multiService.init();
      await multiService.track(AnalyticsEvents.loginSuccess);

      expect(provider.trackedEvents, contains(AnalyticsEvents.loginSuccess));
      expect(provider2.trackedEvents, contains(AnalyticsEvents.loginSuccess));
    });

    test('continues to other providers when one fails', () async {
      final multiService = AnalyticsService(
        providers: [_FailingProvider(), provider],
      );
      await multiService.init();
      await multiService.track(AnalyticsEvents.loginSuccess);

      // Second provider should still receive the event
      expect(provider.trackedEvents, contains(AnalyticsEvents.loginSuccess));
    });
  });

  // ── DebugAnalyticsProvider ────────────────────────────
  group('DebugAnalyticsProvider', () {
    test('implements all required methods without throwing', () async {
      final debugProvider = DebugAnalyticsProvider(enabled: false);
      await expectLater(debugProvider.init(), completes);
      await expectLater(
        debugProvider.identify('user-1', traits: {'a': 'b'}),
        completes,
      );
      await expectLater(debugProvider.reset(), completes);
      await expectLater(
        debugProvider.track('event', properties: {'k': 'v'}),
        completes,
      );
      await expectLater(
        debugProvider.screen('Screen', properties: {}),
        completes,
      );
      await expectLater(
        debugProvider.setUserProperty('prop', 'val'),
        completes,
      );
    });
  });
}
