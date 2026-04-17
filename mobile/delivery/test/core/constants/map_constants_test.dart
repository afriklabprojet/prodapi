import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/constants/map_constants.dart';
import 'package:courier/core/config/app_config.dart';

void main() {
  group('MapConstants', () {
    test('defaultLatitude matches AppConfig', () {
      expect(MapConstants.defaultLatitude, AppConfig.defaultLatitude);
    });

    test('defaultLongitude matches AppConfig', () {
      expect(MapConstants.defaultLongitude, AppConfig.defaultLongitude);
    });

    test('defaultLocation has correct coordinates', () {
      final location = MapConstants.defaultLocation;
      expect(location.latitude, AppConfig.defaultLatitude);
      expect(location.longitude, AppConfig.defaultLongitude);
    });

    test('defaultZoom matches AppConfig', () {
      expect(MapConstants.defaultZoom, AppConfig.mapDefaultZoom);
    });
  });
}
