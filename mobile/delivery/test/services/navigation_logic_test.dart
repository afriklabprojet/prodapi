import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:courier/core/services/navigation_service.dart';

void main() {
  group('NavigationApp displayName', () {
    test('googleMaps returns Google Maps', () {
      expect(NavigationApp.googleMaps.displayName, 'Google Maps');
    });
    test('waze returns Waze', () {
      expect(NavigationApp.waze.displayName, 'Waze');
    });
    test('appleMaps returns Apple Maps', () {
      expect(NavigationApp.appleMaps.displayName, 'Apple Maps');
    });
    test('yandex returns Yandex Maps', () {
      expect(NavigationApp.yandex.displayName, 'Yandex Maps');
    });
    test('citymapper returns Citymapper', () {
      expect(NavigationApp.citymapper.displayName, 'Citymapper');
    });
    test('osmAnd returns OsmAnd', () {
      expect(NavigationApp.osmAnd.displayName, 'OsmAnd');
    });
  });

  group('NavigationApp icon', () {
    test('googleMaps icon is map', () {
      expect(NavigationApp.googleMaps.icon, Icons.map);
    });
    test('waze icon is navigation', () {
      expect(NavigationApp.waze.icon, Icons.navigation);
    });
    test('appleMaps icon is apple', () {
      expect(NavigationApp.appleMaps.icon, Icons.apple);
    });
    test('yandex icon is explore', () {
      expect(NavigationApp.yandex.icon, Icons.explore);
    });
    test('citymapper icon is directions_transit', () {
      expect(NavigationApp.citymapper.icon, Icons.directions_transit);
    });
    test('osmAnd icon is terrain', () {
      expect(NavigationApp.osmAnd.icon, Icons.terrain);
    });
  });

  group('NavigationApp color', () {
    test('googleMaps color', () {
      expect(NavigationApp.googleMaps.color, const Color(0xFF4285F4));
    });
    test('waze color', () {
      expect(NavigationApp.waze.color, const Color(0xFF00CCFF));
    });
    test('appleMaps color is grey shade800', () {
      expect(NavigationApp.appleMaps.color, Colors.grey.shade800);
    });
    test('yandex color is red', () {
      expect(NavigationApp.yandex.color, const Color(0xFFFF0000));
    });
    test('citymapper color', () {
      expect(NavigationApp.citymapper.color, const Color(0xFF2DBE60));
    });
    test('osmAnd color', () {
      expect(NavigationApp.osmAnd.color, const Color(0xFF2D9B27));
    });
  });

  group('NavigationApp mapType', () {
    test('googleMaps returns MapType.google', () {
      expect(NavigationApp.googleMaps.mapType, MapType.google);
    });
    test('waze returns MapType.waze', () {
      expect(NavigationApp.waze.mapType, MapType.waze);
    });
    test('appleMaps returns MapType.apple', () {
      expect(NavigationApp.appleMaps.mapType, MapType.apple);
    });
    test('yandex returns MapType.yandexMaps', () {
      expect(NavigationApp.yandex.mapType, MapType.yandexMaps);
    });
    test('citymapper returns MapType.citymapper', () {
      expect(NavigationApp.citymapper.mapType, MapType.citymapper);
    });
    test('osmAnd returns MapType.osmand', () {
      expect(NavigationApp.osmAnd.mapType, MapType.osmand);
    });
  });

  group('NavigationInstruction distanceText', () {
    NavigationInstruction makeInstruction({
      double distance = 0,
      double duration = 0,
      String maneuver = 'straight',
    }) {
      return NavigationInstruction(
        instruction: 'test',
        maneuver: maneuver,
        distanceMeters: distance,
        durationSeconds: duration,
        startLat: 0,
        startLng: 0,
      );
    }

    test('less than 1000m shows meters', () {
      expect(makeInstruction(distance: 500).distanceText, '500 m');
    });
    test('exactly 999m shows meters', () {
      expect(makeInstruction(distance: 999).distanceText, '999 m');
    });
    test('1000m shows km', () {
      expect(makeInstruction(distance: 1000).distanceText, '1.0 km');
    });
    test('1500m shows 1.5km', () {
      expect(makeInstruction(distance: 1500).distanceText, '1.5 km');
    });
    test('10000m shows 10.0km', () {
      expect(makeInstruction(distance: 10000).distanceText, '10.0 km');
    });
    test('50m shows 50 m', () {
      expect(makeInstruction(distance: 50).distanceText, '50 m');
    });
    test('0m shows 0 m', () {
      expect(makeInstruction(distance: 0).distanceText, '0 m');
    });
  });

  group('NavigationInstruction durationText', () {
    NavigationInstruction makeInstruction({double duration = 0}) {
      return NavigationInstruction(
        instruction: 'test',
        maneuver: 'straight',
        distanceMeters: 0,
        durationSeconds: duration,
        startLat: 0,
        startLng: 0,
      );
    }

    test('0 seconds shows maintenant', () {
      expect(makeInstruction(duration: 0).durationText, 'maintenant');
    });
    test('29 seconds shows maintenant', () {
      // 29/60 = 0.48, round() = 0, which is < 1
      expect(makeInstruction(duration: 29).durationText, 'maintenant');
    });
    test('30 seconds rounds to 1 min', () {
      // 30/60 = 0.5, round() = 1
      expect(makeInstruction(duration: 30).durationText, '1 min');
    });
    test('60 seconds shows 1 min', () {
      expect(makeInstruction(duration: 60).durationText, '1 min');
    });
    test('90 seconds shows 2 min', () {
      // 90/60 = 1.5, round() = 2
      expect(makeInstruction(duration: 90).durationText, '2 min');
    });
    test('120 seconds shows 2 min', () {
      expect(makeInstruction(duration: 120).durationText, '2 min');
    });
    test('300 seconds shows 5 min', () {
      expect(makeInstruction(duration: 300).durationText, '5 min');
    });
    test('3600 seconds shows 60 min', () {
      expect(makeInstruction(duration: 3600).durationText, '60 min');
    });
  });

  group('NavigationInstruction maneuverIcon', () {
    IconData getManeuverIcon(String maneuver) {
      return NavigationInstruction(
        instruction: 'test',
        maneuver: maneuver,
        distanceMeters: 0,
        durationSeconds: 0,
        startLat: 0,
        startLng: 0,
      ).maneuverIcon;
    }

    test('turn-left returns Icons.turn_left', () {
      expect(getManeuverIcon('turn-left'), Icons.turn_left);
    });
    test('turn-slight-left returns Icons.turn_left', () {
      expect(getManeuverIcon('turn-slight-left'), Icons.turn_left);
    });
    test('turn-sharp-left returns Icons.turn_left', () {
      expect(getManeuverIcon('turn-sharp-left'), Icons.turn_left);
    });
    test('turn-right returns Icons.turn_right', () {
      expect(getManeuverIcon('turn-right'), Icons.turn_right);
    });
    test('turn-slight-right returns Icons.turn_right', () {
      expect(getManeuverIcon('turn-slight-right'), Icons.turn_right);
    });
    test('turn-sharp-right returns Icons.turn_right', () {
      expect(getManeuverIcon('turn-sharp-right'), Icons.turn_right);
    });
    test('uturn-left returns Icons.u_turn_right', () {
      expect(getManeuverIcon('uturn-left'), Icons.u_turn_right);
    });
    test('uturn-right returns Icons.u_turn_right', () {
      expect(getManeuverIcon('uturn-right'), Icons.u_turn_right);
    });
    test('roundabout-left returns Icons.roundabout_left', () {
      expect(getManeuverIcon('roundabout-left'), Icons.roundabout_left);
    });
    test('roundabout-right returns Icons.roundabout_left', () {
      expect(getManeuverIcon('roundabout-right'), Icons.roundabout_left);
    });
    test('merge returns Icons.merge', () {
      expect(getManeuverIcon('merge'), Icons.merge);
    });
    test('fork-left returns Icons.fork_right', () {
      expect(getManeuverIcon('fork-left'), Icons.fork_right);
    });
    test('fork-right returns Icons.fork_right', () {
      expect(getManeuverIcon('fork-right'), Icons.fork_right);
    });
    test('ramp-left returns Icons.ramp_right', () {
      expect(getManeuverIcon('ramp-left'), Icons.ramp_right);
    });
    test('ramp-right returns Icons.ramp_right', () {
      expect(getManeuverIcon('ramp-right'), Icons.ramp_right);
    });
    test('ferry returns Icons.directions_boat', () {
      expect(getManeuverIcon('ferry'), Icons.directions_boat);
    });
    test('unknown returns Icons.straight', () {
      expect(getManeuverIcon('unknown'), Icons.straight);
    });
    test('empty string returns Icons.straight', () {
      expect(getManeuverIcon(''), Icons.straight);
    });
    test('case insensitive TURN-LEFT', () {
      expect(getManeuverIcon('TURN-LEFT'), Icons.turn_left);
    });
  });
}
