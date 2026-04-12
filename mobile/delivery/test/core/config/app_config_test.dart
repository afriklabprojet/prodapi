import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    group('Network configuration', () {
      test('connectionTimeout is 10 seconds', () {
        expect(AppConfig.connectionTimeout, const Duration(seconds: 10));
      });

      test('receiveTimeout is 15 seconds', () {
        expect(AppConfig.receiveTimeout, const Duration(seconds: 15));
      });

      test('connectivityCheckUrl is google 204', () {
        expect(AppConfig.connectivityCheckUrl, contains('google.com'));
        expect(AppConfig.connectivityCheckUrl, contains('204'));
      });
    });

    group('Pagination', () {
      test('defaultPageSize is 20', () {
        expect(AppConfig.defaultPageSize, 20);
      });

      test('maxPageSize is 100', () {
        expect(AppConfig.maxPageSize, 100);
      });
    });

    group('Cache', () {
      test('cacheExpiration is 5 minutes', () {
        expect(AppConfig.cacheExpiration, const Duration(minutes: 5));
      });
    });

    group('Map / Geolocation', () {
      test('mapDefaultZoom is 14.5', () {
        expect(AppConfig.mapDefaultZoom, 14.5);
      });

      test('mapMinZoom is 10.0', () {
        expect(AppConfig.mapMinZoom, 10.0);
      });

      test('mapMaxZoom is 19.0', () {
        expect(AppConfig.mapMaxZoom, 19.0);
      });

      test('mapDeliveryZoom is 16.0', () {
        expect(AppConfig.mapDeliveryZoom, 16.0);
      });

      test('defaultLatitude is Abidjan', () {
        expect(AppConfig.defaultLatitude, 5.3600);
      });

      test('defaultLongitude is Abidjan', () {
        expect(AppConfig.defaultLongitude, -4.0083);
      });
    });

    group('Geofencing', () {
      test('geofencePharmacyRadius is 100m', () {
        expect(AppConfig.geofencePharmacyRadius, 100.0);
      });

      test('geofenceClientRadius is 50m', () {
        expect(AppConfig.geofenceClientRadius, 50.0);
      });

      test('locationMinDistance is 10m', () {
        expect(AppConfig.locationMinDistance, 10.0);
      });

      test('locationUpdateInterval is 30s', () {
        expect(AppConfig.locationUpdateInterval, 30);
      });

      test('locationUpdateIntervalActive is 10s', () {
        expect(AppConfig.locationUpdateIntervalActive, 10);
      });
    });

    group('Limits & Thresholds', () {
      test('maxSpeedKmh is 80', () {
        expect(AppConfig.maxSpeedKmh, 80.0);
      });

      test('maxDeliveryDistanceKm is 50', () {
        expect(AppConfig.maxDeliveryDistanceKm, 50.0);
      });

      test('maxBatchDeliveries is 5', () {
        expect(AppConfig.maxBatchDeliveries, 5);
      });

      test('paymentSessionTimeoutMinutes is 30', () {
        expect(AppConfig.paymentSessionTimeoutMinutes, 30);
      });
    });

    group('Animations', () {
      test('animationDurationMs is 300', () {
        expect(AppConfig.animationDurationMs, 300);
      });

      test('animationDurationLongMs is 600', () {
        expect(AppConfig.animationDurationLongMs, 600);
      });

      test('splashDurationMs is 2000', () {
        expect(AppConfig.splashDurationMs, 2000);
      });

      test('snackbarDurationSec is 4', () {
        expect(AppConfig.snackbarDurationSec, 4);
      });
    });

    group('Files & Media', () {
      test('maxImageSizeBytes is 5MB', () {
        expect(AppConfig.maxImageSizeBytes, 5 * 1024 * 1024);
      });

      test('imageCompressionQuality is 80', () {
        expect(AppConfig.imageCompressionQuality, 80);
      });

      test('maxImageWidth is 1024', () {
        expect(AppConfig.maxImageWidth, 1024);
      });

      test('maxImageHeight is 1024', () {
        expect(AppConfig.maxImageHeight, 1024);
      });
    });

    group('Document Scanner', () {
      test('documentMaxWidth is 2048', () {
        expect(AppConfig.documentMaxWidth, 2048);
      });

      test('documentImageQuality is 95', () {
        expect(AppConfig.documentImageQuality, 95);
      });

      test('documentA4AspectRatio is ~1.414', () {
        expect(AppConfig.documentA4AspectRatio, 1.414);
      });
    });

    group('Deep Links & App Identifiers', () {
      test('deepLinkScheme is drpharma-courier', () {
        expect(AppConfig.deepLinkScheme, 'drpharma-courier');
      });

      test('deepLinkPaymentHost is payment', () {
        expect(AppConfig.deepLinkPaymentHost, 'payment');
      });

      test('iosBundleId is com.drpharma.courier', () {
        expect(AppConfig.iosBundleId, 'com.drpharma.courier');
      });

      test('androidPackage is com.drpharma.courier', () {
        expect(AppConfig.androidPackage, 'com.drpharma.courier');
      });
    });

    group('Payment', () {
      test('paymentMaxRetries is 3', () {
        expect(AppConfig.paymentMaxRetries, 3);
      });

      test('paymentMaxWaitMinutes is 5', () {
        expect(AppConfig.paymentMaxWaitMinutes, 5);
      });

      test('paymentPollingIntervals is non-empty', () {
        expect(AppConfig.paymentPollingIntervals, isNotEmpty);
        expect(AppConfig.paymentPollingIntervals.first, 3);
      });

      test('paymentMaxPollingInterval is 30', () {
        expect(AppConfig.paymentMaxPollingInterval, 30);
      });
    });

    group('Liveness', () {
      test('livenessRetryDelays has 3 entries', () {
        expect(AppConfig.livenessRetryDelays.length, 3);
        expect(AppConfig.livenessRetryDelays, [2, 4, 8]);
      });

      test('livenessMaxSessionRetries is 3', () {
        expect(AppConfig.livenessMaxSessionRetries, 3);
      });

      test('livenessConnectTimeout is 15s', () {
        expect(AppConfig.livenessConnectTimeout, const Duration(seconds: 15));
      });

      test('livenessReceiveTimeout is 30s', () {
        expect(AppConfig.livenessReceiveTimeout, const Duration(seconds: 30));
      });
    });

    group('Feature Flags', () {
      test('enableSoundNotifications is true', () {
        expect(AppConfig.enableSoundNotifications, true);
      });

      test('enableBatchMode is true', () {
        expect(AppConfig.enableBatchMode, true);
      });

      test('enableChallenges is true', () {
        expect(AppConfig.enableChallenges, true);
      });
    });

    group('Contact & Support', () {
      test('supportEmail contains email format', () {
        expect(AppConfig.supportEmail, contains('@'));
      });

      test('whatsAppUrl is valid', () {
        expect(AppConfig.whatsAppUrl, startsWith('https://wa.me/'));
      });

      test('phoneUrl starts with tel:', () {
        expect(AppConfig.phoneUrl, startsWith('tel:'));
      });
    });

    group('Legal URLs', () {
      test('privacyUrl is a URL', () {
        expect(AppConfig.privacyUrl, startsWith('https://'));
        expect(AppConfig.privacyUrl, contains('privacy'));
      });

      test('termsUrl is a URL', () {
        expect(AppConfig.termsUrl, startsWith('https://'));
        expect(AppConfig.termsUrl, contains('terms'));
      });
    });
  });
}
