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
}
