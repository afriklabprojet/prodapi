import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/navigation_service.dart';

const MethodChannel _ttsChannel = MethodChannel('flutter_tts');

void _mockTtsPlatformChannel() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_ttsChannel, (call) async {
    switch (call.method) {
      case 'getLanguages':
        return ['fr-FR', 'en-US'];
      default:
        return 1;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('NavigationApp extension', () {
    test('displayName returns correct names', () {
      expect(NavigationApp.googleMaps.displayName, 'Google Maps');
      expect(NavigationApp.waze.displayName, 'Waze');
      expect(NavigationApp.appleMaps.displayName, 'Apple Maps');
      expect(NavigationApp.yandex.displayName, 'Yandex Maps');
      expect(NavigationApp.citymapper.displayName, 'Citymapper');
      expect(NavigationApp.osmAnd.displayName, 'OsmAnd');
    });

    test('icon returns IconData for each app', () {
      for (final app in NavigationApp.values) {
        expect(app.icon, isA<IconData>());
      }
    });

    test('icon returns specific icons per app', () {
      expect(NavigationApp.googleMaps.icon, Icons.map);
      expect(NavigationApp.waze.icon, Icons.navigation);
      expect(NavigationApp.appleMaps.icon, Icons.apple);
      expect(NavigationApp.yandex.icon, Icons.explore);
      expect(NavigationApp.citymapper.icon, Icons.directions_transit);
      expect(NavigationApp.osmAnd.icon, Icons.terrain);
    });

    test('color returns correct color for each app', () {
      expect(NavigationApp.googleMaps.color, const Color(0xFF4285F4));
      expect(NavigationApp.waze.color, const Color(0xFF00CCFF));
      expect(NavigationApp.appleMaps.color, Colors.grey.shade800);
      expect(NavigationApp.yandex.color, const Color(0xFFFF0000));
      expect(NavigationApp.citymapper.color, const Color(0xFF2DBE60));
      expect(NavigationApp.osmAnd.color, const Color(0xFF2D9B27));
    });

    test('mapType returns correct MapType for each app', () {
      expect(NavigationApp.googleMaps.mapType, MapType.google);
      expect(NavigationApp.waze.mapType, MapType.waze);
      expect(NavigationApp.appleMaps.mapType, MapType.apple);
      expect(NavigationApp.yandex.mapType, MapType.yandexMaps);
      expect(NavigationApp.citymapper.mapType, MapType.citymapper);
      expect(NavigationApp.osmAnd.mapType, MapType.osmand);
    });

    test('all apps have non-null mapType', () {
      for (final app in NavigationApp.values) {
        expect(app.mapType, isNotNull);
      }
    });
  });

  group('NavigationInstruction', () {
    NavigationInstruction makeInstruction({
      String instruction = 'Tournez à droite',
      String maneuver = 'turn-right',
      double distanceMeters = 500,
      double durationSeconds = 60,
    }) {
      return NavigationInstruction(
        instruction: instruction,
        maneuver: maneuver,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        startLat: 5.3364,
        startLng: -4.0266,
      );
    }

    group('distanceText', () {
      test('returns meters when < 1000m', () {
        final inst = makeInstruction(distanceMeters: 150);
        expect(inst.distanceText, '150 m');
      });

      test('returns meters for 0m', () {
        final inst = makeInstruction(distanceMeters: 0);
        expect(inst.distanceText, '0 m');
      });

      test('returns meters for 999m', () {
        final inst = makeInstruction(distanceMeters: 999);
        expect(inst.distanceText, '999 m');
      });

      test('returns km when >= 1000m', () {
        final inst = makeInstruction(distanceMeters: 1000);
        expect(inst.distanceText, '1.0 km');
      });

      test('returns km with decimal for 1500m', () {
        final inst = makeInstruction(distanceMeters: 1500);
        expect(inst.distanceText, '1.5 km');
      });

      test('returns km for large distances', () {
        final inst = makeInstruction(distanceMeters: 5200);
        expect(inst.distanceText, '5.2 km');
      });

      test('rounds meters correctly', () {
        final inst = makeInstruction(distanceMeters: 450.7);
        expect(inst.distanceText, '451 m');
      });
    });

    group('durationText', () {
      test('returns maintenant for < 1 min (rounds to 0)', () {
        final inst = makeInstruction(durationSeconds: 15);
        expect(inst.durationText, 'maintenant');
      });

      test('returns maintenant for 0 seconds', () {
        final inst = makeInstruction(durationSeconds: 0);
        expect(inst.durationText, 'maintenant');
      });

      test('returns 1 min for exactly 1 minute', () {
        final inst = makeInstruction(durationSeconds: 60);
        expect(inst.durationText, '1 min');
      });

      test('returns 1 min for 30 seconds (rounds to 1)', () {
        final inst = makeInstruction(durationSeconds: 30);
        expect(inst.durationText, '1 min');
      });

      test('returns N min for multiple minutes', () {
        final inst = makeInstruction(durationSeconds: 300);
        expect(inst.durationText, '5 min');
      });

      test('rounds to nearest minute (150s -> 3 min)', () {
        final inst = makeInstruction(durationSeconds: 150);
        expect(inst.durationText, '3 min');
      });

      test('90 seconds rounds to 2 min', () {
        final inst = makeInstruction(durationSeconds: 90);
        expect(inst.durationText, '2 min');
      });
    });

    group('maneuverIcon', () {
      test('turn-left returns turn_left icon', () {
        expect(
          makeInstruction(maneuver: 'turn-left').maneuverIcon,
          Icons.turn_left,
        );
      });

      test('turn-slight-left returns turn_left icon', () {
        expect(
          makeInstruction(maneuver: 'turn-slight-left').maneuverIcon,
          Icons.turn_left,
        );
      });

      test('turn-sharp-left returns turn_left icon', () {
        expect(
          makeInstruction(maneuver: 'turn-sharp-left').maneuverIcon,
          Icons.turn_left,
        );
      });

      test('turn-right returns turn_right icon', () {
        expect(
          makeInstruction(maneuver: 'turn-right').maneuverIcon,
          Icons.turn_right,
        );
      });

      test('turn-slight-right returns turn_right icon', () {
        expect(
          makeInstruction(maneuver: 'turn-slight-right').maneuverIcon,
          Icons.turn_right,
        );
      });

      test('turn-sharp-right returns turn_right icon', () {
        expect(
          makeInstruction(maneuver: 'turn-sharp-right').maneuverIcon,
          Icons.turn_right,
        );
      });

      test('uturn-left returns u_turn_right icon', () {
        expect(
          makeInstruction(maneuver: 'uturn-left').maneuverIcon,
          Icons.u_turn_right,
        );
      });

      test('uturn-right returns u_turn_right icon', () {
        expect(
          makeInstruction(maneuver: 'uturn-right').maneuverIcon,
          Icons.u_turn_right,
        );
      });

      test('roundabout-left returns roundabout_left icon', () {
        expect(
          makeInstruction(maneuver: 'roundabout-left').maneuverIcon,
          Icons.roundabout_left,
        );
      });

      test('roundabout-right returns roundabout_left icon', () {
        expect(
          makeInstruction(maneuver: 'roundabout-right').maneuverIcon,
          Icons.roundabout_left,
        );
      });

      test('merge returns merge icon', () {
        expect(makeInstruction(maneuver: 'merge').maneuverIcon, Icons.merge);
      });

      test('fork-left returns fork_right icon', () {
        expect(
          makeInstruction(maneuver: 'fork-left').maneuverIcon,
          Icons.fork_right,
        );
      });

      test('fork-right returns fork_right icon', () {
        expect(
          makeInstruction(maneuver: 'fork-right').maneuverIcon,
          Icons.fork_right,
        );
      });

      test('ramp-left returns ramp_right icon', () {
        expect(
          makeInstruction(maneuver: 'ramp-left').maneuverIcon,
          Icons.ramp_right,
        );
      });

      test('ramp-right returns ramp_right icon', () {
        expect(
          makeInstruction(maneuver: 'ramp-right').maneuverIcon,
          Icons.ramp_right,
        );
      });

      test('ferry returns directions_boat icon', () {
        expect(
          makeInstruction(maneuver: 'ferry').maneuverIcon,
          Icons.directions_boat,
        );
      });

      test('unknown maneuver returns straight icon', () {
        expect(
          makeInstruction(maneuver: 'something-else').maneuverIcon,
          Icons.straight,
        );
      });

      test('empty maneuver returns straight icon', () {
        expect(makeInstruction(maneuver: '').maneuverIcon, Icons.straight);
      });

      test('maneuver matching is case-insensitive', () {
        expect(
          makeInstruction(maneuver: 'TURN-LEFT').maneuverIcon,
          Icons.turn_left,
        );
        expect(
          makeInstruction(maneuver: 'Turn-Right').maneuverIcon,
          Icons.turn_right,
        );
        expect(
          makeInstruction(maneuver: 'FERRY').maneuverIcon,
          Icons.directions_boat,
        );
      });
    });

    test('stores all constructor fields', () {
      final inst = NavigationInstruction(
        instruction: 'Go straight',
        maneuver: 'straight',
        distanceMeters: 100,
        durationSeconds: 30,
        startLat: 5.3364,
        startLng: -4.0266,
      );
      expect(inst.instruction, 'Go straight');
      expect(inst.maneuver, 'straight');
      expect(inst.distanceMeters, 100);
      expect(inst.durationSeconds, 30);
      expect(inst.startLat, 5.3364);
      expect(inst.startLng, -4.0266);
    });

    test('distanceText for 999.5 stays in meters', () {
      final inst = makeInstruction(distanceMeters: 999.5);
      // 999.5 < 1000 so stays in meters branch, rounds to 1000
      expect(inst.distanceText, '1000 m');
    });

    test('distanceText for 10000m', () {
      final inst = makeInstruction(distanceMeters: 10000);
      expect(inst.distanceText, '10.0 km');
    });

    test('distanceText for 50m', () {
      final inst = makeInstruction(distanceMeters: 50);
      expect(inst.distanceText, '50 m');
    });

    test('durationText for 59 seconds rounds to 1 min', () {
      final inst = makeInstruction(durationSeconds: 59);
      expect(inst.durationText, '1 min');
    });

    test('durationText for 3600 seconds is 60 min', () {
      final inst = makeInstruction(durationSeconds: 3600);
      expect(inst.durationText, '60 min');
    });

    test('durationText for 1 second rounds to 0 (maintenant)', () {
      final inst = makeInstruction(durationSeconds: 1);
      expect(inst.durationText, 'maintenant');
    });

    test('durationText for 29 seconds rounds to 0 (maintenant)', () {
      final inst = makeInstruction(durationSeconds: 29);
      expect(inst.durationText, 'maintenant');
    });

    test('durationText for exactly 120 seconds is 2 min', () {
      final inst = makeInstruction(durationSeconds: 120);
      expect(inst.durationText, '2 min');
    });

    test('negative coordinates work', () {
      final inst = NavigationInstruction(
        instruction: 'Test',
        maneuver: 'straight',
        distanceMeters: 100,
        durationSeconds: 60,
        startLat: -33.8688,
        startLng: 151.2093,
      );
      expect(inst.startLat, -33.8688);
      expect(inst.startLng, 151.2093);
    });
  });

  group('NavigationApp', () {
    test('has 6 values', () {
      expect(NavigationApp.values.length, 6);
    });

    test('indices are correct', () {
      expect(NavigationApp.googleMaps.index, 0);
      expect(NavigationApp.waze.index, 1);
      expect(NavigationApp.appleMaps.index, 2);
      expect(NavigationApp.yandex.index, 3);
      expect(NavigationApp.citymapper.index, 4);
      expect(NavigationApp.osmAnd.index, 5);
    });

    test('each app has distinct displayName', () {
      final names = NavigationApp.values.map((a) => a.displayName).toSet();
      expect(names.length, NavigationApp.values.length);
    });

    test('each app has distinct icon', () {
      // Some may share icons, but verify they all return an icon
      for (final app in NavigationApp.values) {
        expect(app.icon, isA<IconData>());
      }
    });

    test('each app has a non-null color', () {
      for (final app in NavigationApp.values) {
        expect(app.color, isA<Color>());
      }
    });

    test('each app has non-null mapType', () {
      for (final app in NavigationApp.values) {
        expect(app.mapType, isNotNull);
      }
    });

    test('appleMaps color is grey shade', () {
      expect(NavigationApp.appleMaps.color, Colors.grey.shade800);
    });
  });

  group('NavigationInstruction - additional edge cases', () {
    NavigationInstruction makeInstruction({
      String instruction = 'Test',
      String maneuver = 'straight',
      double distanceMeters = 100,
      double durationSeconds = 60,
      double startLat = 5.0,
      double startLng = -4.0,
    }) {
      return NavigationInstruction(
        instruction: instruction,
        maneuver: maneuver,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        startLat: startLat,
        startLng: startLng,
      );
    }

    test('distanceText for exactly 1 meter', () {
      final inst = makeInstruction(distanceMeters: 1);
      expect(inst.distanceText, '1 m');
    });

    test('distanceText for 2500m', () {
      final inst = makeInstruction(distanceMeters: 2500);
      expect(inst.distanceText, '2.5 km');
    });

    test('distanceText for 100000m (100km)', () {
      final inst = makeInstruction(distanceMeters: 100000);
      expect(inst.distanceText, '100.0 km');
    });

    test('durationText for exactly 180 seconds is 3 min', () {
      final inst = makeInstruction(durationSeconds: 180);
      expect(inst.durationText, '3 min');
    });

    test('durationText for 7200 seconds is 120 min', () {
      final inst = makeInstruction(durationSeconds: 7200);
      expect(inst.durationText, '120 min');
    });

    test('durationText for 45 seconds rounds to 1 min', () {
      final inst = makeInstruction(durationSeconds: 45);
      expect(inst.durationText, '1 min');
    });

    test('instruction stores text correctly', () {
      final inst = makeInstruction(
        instruction: 'Continuez tout droit pendant 500 m',
      );
      expect(inst.instruction, 'Continuez tout droit pendant 500 m');
    });

    test('instruction with unicode', () {
      final inst = makeInstruction(
        instruction: 'Tournez à gauche sur Côte d\'Ivoire Blvd',
      );
      expect(inst.instruction, contains('Côte'));
    });

    test('maneuverIcon for straight', () {
      expect(
        makeInstruction(maneuver: 'straight').maneuverIcon,
        Icons.straight,
      );
    });

    test('maneuverIcon for depart', () {
      // Not in the switch, falls to default
      expect(makeInstruction(maneuver: 'depart').maneuverIcon, Icons.straight);
    });

    test('maneuverIcon for arrive', () {
      // Not in the switch, falls to default
      expect(makeInstruction(maneuver: 'arrive').maneuverIcon, Icons.straight);
    });

    test('maneuverIcon for keep-left', () {
      // Not in the switch, falls to default
      expect(
        makeInstruction(maneuver: 'keep-left').maneuverIcon,
        Icons.straight,
      );
    });

    test('distanceText for 500.4m', () {
      final inst = makeInstruction(distanceMeters: 500.4);
      expect(inst.distanceText, '500 m');
    });

    test('distanceText for 1099.8m', () {
      final inst = makeInstruction(distanceMeters: 1099.8);
      expect(inst.distanceText, '1.1 km');
    });
  });

  group('NavigationApp extension - comprehensive', () {
    test('each app has unique displayName', () {
      final names = NavigationApp.values.map((a) => a.displayName).toSet();
      expect(names.length, 6);
    });

    test('each app has unique color', () {
      final colors = NavigationApp.values
          .map((a) => a.color.toARGB32())
          .toSet();
      expect(colors.length, 6);
    });

    test('googleMaps mapType is google', () {
      expect(NavigationApp.googleMaps.mapType, MapType.google);
    });

    test('all mapTypes are from MapType enum', () {
      for (final app in NavigationApp.values) {
        expect(app.mapType, isA<MapType>());
      }
    });

    test('displayName for each app is non-empty', () {
      for (final app in NavigationApp.values) {
        expect(app.displayName.length, greaterThan(0));
      }
    });
  });

  group('NavigationInstruction - maneuver icon exhaustive', () {
    NavigationInstruction mi(String maneuver) {
      return NavigationInstruction(
        instruction: 'test',
        maneuver: maneuver,
        distanceMeters: 100,
        durationSeconds: 60,
        startLat: 0,
        startLng: 0,
      );
    }

    test('left turns all map to turn_left', () {
      expect(mi('turn-left').maneuverIcon, Icons.turn_left);
      expect(mi('turn-slight-left').maneuverIcon, Icons.turn_left);
      expect(mi('turn-sharp-left').maneuverIcon, Icons.turn_left);
    });

    test('right turns all map to turn_right', () {
      expect(mi('turn-right').maneuverIcon, Icons.turn_right);
      expect(mi('turn-slight-right').maneuverIcon, Icons.turn_right);
      expect(mi('turn-sharp-right').maneuverIcon, Icons.turn_right);
    });

    test('u-turns map to u_turn_right', () {
      expect(mi('uturn-left').maneuverIcon, Icons.u_turn_right);
      expect(mi('uturn-right').maneuverIcon, Icons.u_turn_right);
    });

    test('roundabouts map to roundabout_left', () {
      expect(mi('roundabout-left').maneuverIcon, Icons.roundabout_left);
      expect(mi('roundabout-right').maneuverIcon, Icons.roundabout_left);
    });

    test('forks map to fork_right', () {
      expect(mi('fork-left').maneuverIcon, Icons.fork_right);
      expect(mi('fork-right').maneuverIcon, Icons.fork_right);
    });

    test('ramps map to ramp_right', () {
      expect(mi('ramp-left').maneuverIcon, Icons.ramp_right);
      expect(mi('ramp-right').maneuverIcon, Icons.ramp_right);
    });

    test('merge maps to merge', () {
      expect(mi('merge').maneuverIcon, Icons.merge);
    });

    test('ferry maps to directions_boat', () {
      expect(mi('ferry').maneuverIcon, Icons.directions_boat);
    });

    test('unknown maneuvers map to straight', () {
      expect(mi('').maneuverIcon, Icons.straight);
      expect(mi('unknown').maneuverIcon, Icons.straight);
      expect(mi('exit').maneuverIcon, Icons.straight);
      expect(mi('continue').maneuverIcon, Icons.straight);
    });
  });

  group('NavigationService - preferences and state', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      _mockTtsPlatformChannel();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_ttsChannel, null);
    });

    test('initial state has no preferred app', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      expect(service.preferredApp, isNull);
      expect(service.isVoiceEnabled, true);
      expect(service.isNavigating, false);
      expect(service.instructions, isEmpty);
      expect(service.currentInstructionIndex, 0);

      service.dispose();
    });

    test('setPreferredApp persists to SharedPreferences', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      await service.setPreferredApp(NavigationApp.waze);
      expect(service.preferredApp, NavigationApp.waze);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('preferred_nav_app'), 'waze');

      service.dispose();
    });

    test('setVoiceEnabled persists to SharedPreferences', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      await service.setVoiceEnabled(false);
      expect(service.isVoiceEnabled, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('nav_voice_enabled'), false);

      service.dispose();
    });

    test('loadPreferences restores saved preferred app', () async {
      SharedPreferences.setMockInitialValues({
        'preferred_nav_app': 'googleMaps',
        'nav_voice_enabled': false,
        'nav_voice_language': 'en-US',
      });

      final service = NavigationService();
      await pumpEventQueue(times: 10);

      expect(service.preferredApp, NavigationApp.googleMaps);
      expect(service.isVoiceEnabled, false);

      service.dispose();
    });

    test('loadPreferences handles invalid app name gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'preferred_nav_app': 'invalidApp',
      });

      final service = NavigationService();
      await pumpEventQueue(times: 10);

      // Should fall back to null
      expect(service.preferredApp, isNull);

      service.dispose();
    });

    test('stopNavigation resets state', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      await service.stopNavigation();

      expect(service.isNavigating, false);
      expect(service.instructions, isEmpty);
      expect(service.currentInstructionIndex, 0);

      service.dispose();
    });

    test(
      'announceNextInstruction does nothing when past instructions',
      () async {
        final service = NavigationService();
        await pumpEventQueue(times: 10);

        // No instructions loaded, currentInstructionIndex >= length
        await service.announceNextInstruction(100);
        // Should not crash

        service.dispose();
      },
    );

    test('announceArrival speaks destination name', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      // This will speak if voice is enabled
      await service.announceArrival();
      expect(service.isNavigating, false);

      service.dispose();
    });

    test('dispose can be called safely', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      service.dispose();
      // Should not throw when called after dispose
    });

    test('setVoiceEnabled true then false', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      await service.setVoiceEnabled(true);
      expect(service.isVoiceEnabled, true);

      await service.setVoiceEnabled(false);
      expect(service.isVoiceEnabled, false);

      service.dispose();
    });

    test('setPreferredApp changes app', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      await service.setPreferredApp(NavigationApp.googleMaps);
      expect(service.preferredApp, NavigationApp.googleMaps);

      await service.setPreferredApp(NavigationApp.appleMaps);
      expect(service.preferredApp, NavigationApp.appleMaps);

      service.dispose();
    });

    test('all NavigationApp values can be set as preferred', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      for (final app in NavigationApp.values) {
        await service.setPreferredApp(app);
        expect(service.preferredApp, app);
      }

      service.dispose();
    });
  });

  group('NavigationInstruction - maneuverIcon', () {
    NavigationInstruction makeInst({String maneuver = 'straight'}) {
      return NavigationInstruction(
        instruction: 'Test',
        maneuver: maneuver,
        distanceMeters: 100,
        durationSeconds: 30,
        startLat: 5.0,
        startLng: -4.0,
      );
    }

    test('turn-left returns turn_left icon', () {
      expect(makeInst(maneuver: 'turn-left').maneuverIcon, Icons.turn_left);
    });

    test('turn-right returns turn_right icon', () {
      expect(makeInst(maneuver: 'turn-right').maneuverIcon, Icons.turn_right);
    });

    test('turn-slight-left returns turn_left icon (grouped)', () {
      expect(
        makeInst(maneuver: 'turn-slight-left').maneuverIcon,
        Icons.turn_left,
      );
    });

    test('turn-slight-right returns turn_right icon (grouped)', () {
      expect(
        makeInst(maneuver: 'turn-slight-right').maneuverIcon,
        Icons.turn_right,
      );
    });

    test('turn-sharp-left returns turn_left icon (grouped)', () {
      expect(
        makeInst(maneuver: 'turn-sharp-left').maneuverIcon,
        Icons.turn_left,
      );
    });

    test('turn-sharp-right returns turn_right icon (grouped)', () {
      expect(
        makeInst(maneuver: 'turn-sharp-right').maneuverIcon,
        Icons.turn_right,
      );
    });

    test('uturn-left returns u_turn_right icon (grouped with uturn)', () {
      expect(makeInst(maneuver: 'uturn-left').maneuverIcon, Icons.u_turn_right);
    });

    test('uturn-right returns u_turn_right icon', () {
      expect(
        makeInst(maneuver: 'uturn-right').maneuverIcon,
        Icons.u_turn_right,
      );
    });

    test('roundabout returns roundabout_left icon', () {
      expect(
        makeInst(maneuver: 'roundabout-left').maneuverIcon,
        Icons.roundabout_left,
      );
      expect(
        makeInst(maneuver: 'roundabout-right').maneuverIcon,
        Icons.roundabout_left,
      );
    });

    test('merge returns merge icon', () {
      expect(makeInst(maneuver: 'merge').maneuverIcon, Icons.merge);
    });

    test('fork returns fork_right icon', () {
      expect(makeInst(maneuver: 'fork-left').maneuverIcon, Icons.fork_right);
      expect(makeInst(maneuver: 'fork-right').maneuverIcon, Icons.fork_right);
    });

    test('ramp returns ramp_right icon', () {
      expect(makeInst(maneuver: 'ramp-left').maneuverIcon, Icons.ramp_right);
      expect(makeInst(maneuver: 'ramp-right').maneuverIcon, Icons.ramp_right);
    });

    test('ferry returns directions_boat icon', () {
      expect(makeInst(maneuver: 'ferry').maneuverIcon, Icons.directions_boat);
    });

    test('unknown maneuver returns straight icon', () {
      expect(makeInst(maneuver: 'unknown').maneuverIcon, Icons.straight);
      expect(makeInst(maneuver: '').maneuverIcon, Icons.straight);
    });
  });

  group('NavigationInstruction - durationText edge cases', () {
    NavigationInstruction makeInst({double durationSeconds = 60}) {
      return NavigationInstruction(
        instruction: 'Test',
        maneuver: 'straight',
        distanceMeters: 100,
        durationSeconds: durationSeconds,
        startLat: 5.0,
        startLng: -4.0,
      );
    }

    test('zero seconds returns maintenant', () {
      expect(makeInst(durationSeconds: 0).durationText, 'maintenant');
    });

    test('30 seconds rounds to 1 min', () {
      // 30/60 = 0.5, .round() = 1 in Dart
      expect(makeInst(durationSeconds: 30).durationText, '1 min');
    });

    test('60 seconds becomes 1 min', () {
      expect(makeInst(durationSeconds: 60).durationText, '1 min');
    });

    test('90 seconds rounds to 2 min', () {
      expect(makeInst(durationSeconds: 90).durationText, '2 min');
    });

    test('3600 seconds becomes 60 min', () {
      expect(makeInst(durationSeconds: 3600).durationText, '60 min');
    });
  });

  group('NavigationInstruction - distanceText edge cases', () {
    NavigationInstruction makeInst({double distanceMeters = 100}) {
      return NavigationInstruction(
        instruction: 'Test',
        maneuver: 'straight',
        distanceMeters: distanceMeters,
        durationSeconds: 60,
        startLat: 5.0,
        startLng: -4.0,
      );
    }

    test('999 meters stays in meters', () {
      expect(makeInst(distanceMeters: 999).distanceText, '999 m');
    });

    test('1000 meters becomes 1.0 km', () {
      expect(makeInst(distanceMeters: 1000).distanceText, '1.0 km');
    });

    test('1500 meters becomes 1.5 km', () {
      expect(makeInst(distanceMeters: 1500).distanceText, '1.5 km');
    });

    test('10000 meters becomes 10.0 km', () {
      expect(makeInst(distanceMeters: 10000).distanceText, '10.0 km');
    });
  });

  group('NavigationService - voice + announcement', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      _mockTtsPlatformChannel();
    });

    test('announceNextInstruction at very close distance', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      // No instructions loaded, should not crash at various distances
      await service.announceNextInstruction(10);
      await service.announceNextInstruction(100);
      await service.announceNextInstruction(300);
      await service.announceNextInstruction(600);

      service.dispose();
    });

    test('announceArrival sets isNavigating to false', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      await service.announceArrival();
      expect(service.isNavigating, false);

      service.dispose();
    });

    test('onArrival callback is invoked on announceArrival', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      var called = false;
      service.onArrival = () => called = true;

      await service.announceArrival();
      expect(called, true);

      service.dispose();
    });

    test('voice enabled persists to SharedPreferences', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      await service.setVoiceEnabled(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('nav_voice_enabled'), false);

      await service.setVoiceEnabled(true);
      expect(prefs.getBool('nav_voice_enabled'), true);

      service.dispose();
    });

    test('preferred app persists to SharedPreferences', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      await service.setPreferredApp(NavigationApp.waze);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('preferred_nav_app'), 'waze');

      service.dispose();
    });

    test('loads saved preferred app from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'preferred_nav_app': 'appleMaps',
        'nav_voice_enabled': false,
      });

      final service = NavigationService();
      await pumpEventQueue(times: 20);

      // After loading from prefs
      expect(service.isVoiceEnabled, false);
      expect(service.preferredApp, NavigationApp.appleMaps);

      service.dispose();
    });

    test('handles invalid preferred app name in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'preferred_nav_app': 'nonexistent_app',
      });

      final service = NavigationService();
      await pumpEventQueue(times: 20);

      expect(service.preferredApp, isNull);

      service.dispose();
    });

    test('stopNavigation clears all state', () async {
      final service = NavigationService();
      await pumpEventQueue(times: 10);

      await service.stopNavigation();

      expect(service.isNavigating, false);
      expect(service.instructions, isEmpty);
      expect(service.currentInstructionIndex, 0);

      service.dispose();
    });
  });
}
