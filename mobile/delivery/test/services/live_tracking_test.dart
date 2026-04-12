import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/live_tracking_service.dart';
import 'package:courier/core/config/app_config.dart';

void main() {
  group('LiveTrackingService', () {
    test('trackingBaseUrl contains track path', () {
      final baseUrl = LiveTrackingService.trackingBaseUrl;
      expect(baseUrl.contains('/track'), true);
    });

    test('trackingBaseUrl uses AppConfig webBaseUrl', () {
      final expectedUrl = '${AppConfig.webBaseUrl}/track';
      expect(LiveTrackingService.trackingBaseUrl, expectedUrl);
    });
  });

  group('AppConfig webBaseUrl', () {
    test('returns non-empty URL', () {
      expect(AppConfig.webBaseUrl.isNotEmpty, true);
    });

    test('contains valid scheme', () {
      final url = AppConfig.webBaseUrl;
      expect(url.startsWith('http://') || url.startsWith('https://'), true);
    });
  });

  group('Providers', () {
    test('liveTrackingServiceProvider exists', () {
      expect(liveTrackingServiceProvider, isNotNull);
    });

    test('activeTrackingLinkProvider exists', () {
      expect(activeTrackingLinkProvider, isNotNull);
    });
  });

  group('LiveTrackingService - additional', () {
    test('trackingBaseUrl starts with http', () {
      expect(LiveTrackingService.trackingBaseUrl.startsWith('http'), isTrue);
    });

    test('trackingBaseUrl ends with /track', () {
      expect(LiveTrackingService.trackingBaseUrl.endsWith('/track'), isTrue);
    });

    test('AppConfig webBaseUrl does not end with slash', () {
      expect(AppConfig.webBaseUrl.endsWith('/'), isFalse);
    });

    test('trackingBaseUrl is consistent', () {
      // Called twice should give same result
      expect(
        LiveTrackingService.trackingBaseUrl,
        LiveTrackingService.trackingBaseUrl,
      );
    });
  });
}
