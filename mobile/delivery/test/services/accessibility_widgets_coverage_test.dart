import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/core/services/accessibility_service.dart';
import 'package:courier/core/services/navigation_service.dart';

// 1x1 transparent PNG
final _testImageBytes = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x62,
  0x00,
  0x00,
  0x00,
  0x02,
  0x00,
  0x01,
  0xE5,
  0x27,
  0xDE,
  0xFC,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccessibilityNotifier - persistence methods', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setHighContrast saves to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(accessibilityProvider.notifier);
      // Wait for async _loadSettings() to complete
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.setHighContrast(true);
      expect(container.read(accessibilityProvider).highContrast, true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('accessibility_high_contrast'), true);
    });

    test('setLargeText updates textScaleFactor to 1.3', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(accessibilityProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.setLargeText(true);
      final state = container.read(accessibilityProvider);
      expect(state.largeText, true);
      expect(state.textScaleFactor, 1.3);
    });

    test('setLargeText false resets textScaleFactor to 1.0', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(accessibilityProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.setLargeText(true);
      await notifier.setLargeText(false);
      final state = container.read(accessibilityProvider);
      expect(state.largeText, false);
      expect(state.textScaleFactor, 1.0);
    });

    test('setReduceMotion saves to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(accessibilityProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.setReduceMotion(true);
      expect(container.read(accessibilityProvider).reduceMotion, true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('accessibility_reduce_motion'), true);
    });

    test('setTextScaleFactor clamps between 0.8 and 2.0', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(accessibilityProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.setTextScaleFactor(0.5);
      expect(container.read(accessibilityProvider).textScaleFactor, 0.8);

      await notifier.setTextScaleFactor(3.0);
      expect(container.read(accessibilityProvider).textScaleFactor, 2.0);

      await notifier.setTextScaleFactor(1.5);
      expect(container.read(accessibilityProvider).textScaleFactor, 1.5);
    });

    test('setBoldText saves to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(accessibilityProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.setBoldText(true);
      expect(container.read(accessibilityProvider).boldText, true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('accessibility_bold_text'), true);
    });

    test('updateScreenReaderStatus updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(accessibilityProvider.notifier);
      notifier.updateScreenReaderStatus(true);
      expect(container.read(accessibilityProvider).screenReaderEnabled, true);
    });

    test('loadSettings restores from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'accessibility_high_contrast': true,
        'accessibility_large_text': true,
        'accessibility_reduce_motion': true,
        'accessibility_text_scale': 1.5,
        'accessibility_bold_text': true,
      });

      final container = ProviderContainer();
      // Trigger provider initialization
      container.read(accessibilityProvider);
      // Wait for async _loadSettings to complete
      await Future.delayed(const Duration(milliseconds: 500));
      final state = container.read(accessibilityProvider);
      expect(state.highContrast, true);
      expect(state.largeText, true);
      expect(state.reduceMotion, true);
      expect(state.textScaleFactor, 1.5);
      expect(state.boldText, true);
      container.dispose();
    });
  });

  group('AccessibleImage', () {
    testWidgets('renders image with semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleImage(
              image: MemoryImage(_testImageBytes),
              semanticLabel: 'Logo application',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.bySemanticsLabel('Logo application'), findsWidgets);
    });

    testWidgets('renders with excludeFromSemantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleImage(
              image: MemoryImage(_testImageBytes),
              semanticLabel: 'Decorative',
              excludeFromSemantics: true,
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders with custom fit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleImage(
              image: MemoryImage(_testImageBytes),
              semanticLabel: 'Test',
              fit: BoxFit.contain,
              width: 50,
              height: 50,
            ),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
    });
  });

  group('AccessibleStatus', () {
    testWidgets('renders status with color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleStatus(status: 'En ligne', color: Colors.green),
          ),
        ),
      );
      expect(find.text('En ligne'), findsOneWidget);
    });

    testWidgets('renders status with icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleStatus(
              status: 'Actif',
              color: Colors.blue,
              icon: Icons.check_circle,
            ),
          ),
        ),
      );
      expect(find.text('Actif'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders status without icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleStatus(status: 'Hors ligne', color: Colors.grey),
          ),
        ),
      );
      expect(find.text('Hors ligne'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('AccessibleSlider', () {
    testWidgets('renders slider with label and value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleSlider(
              value: 0.5,
              label: 'Volume',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('0.5'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('renders with divisions and custom range', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleSlider(
              value: 1.5,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              label: 'Taille du texte',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Taille du texte'), findsOneWidget);
      expect(find.text('1.5'), findsOneWidget);
    });

    testWidgets('renders with semanticFormatter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleSlider(
              value: 1.5,
              min: 0.8,
              max: 2.0,
              label: 'Échelle',
              semanticFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Échelle'), findsOneWidget);
      expect(find.text('150%'), findsOneWidget);
    });

    testWidgets('renders with null onChanged (disabled)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleSlider(value: 0.3, label: 'Disabled slider'),
          ),
        ),
      );
      expect(find.byType(Slider), findsOneWidget);
    });
  });

  group('AccessibleValue', () {
    testWidgets('renders value without unit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleValue(value: '42', label: 'Livraisons'),
          ),
        ),
      );
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Livraisons'), findsOneWidget);
    });

    testWidgets('renders value with unit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleValue(value: '15.5', label: 'Distance', unit: 'km'),
          ),
        ),
      );
      expect(find.text('15.5 km'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
    });
  });

  group('NavigationInstruction', () {
    test('distanceText shows meters for < 1000m', () {
      final instruction = NavigationInstruction(
        instruction: 'Tourner à gauche',
        maneuver: 'turn-left',
        distanceMeters: 500,
        durationSeconds: 60,
        startLat: 5.0,
        startLng: -4.0,
      );
      expect(instruction.distanceText, '500 m');
    });

    test('distanceText shows km for >= 1000m', () {
      final instruction = NavigationInstruction(
        instruction: 'Continuer',
        maneuver: 'straight',
        distanceMeters: 2500,
        durationSeconds: 180,
        startLat: 5.0,
        startLng: -4.0,
      );
      expect(instruction.distanceText, '2.5 km');
    });

    test('durationText shows maintenant for < 1 min', () {
      final instruction = NavigationInstruction(
        instruction: 'Arrivée',
        maneuver: 'arrive',
        distanceMeters: 10,
        durationSeconds: 20,
        startLat: 5.0,
        startLng: -4.0,
      );
      expect(instruction.durationText, 'maintenant');
    });

    test('durationText shows 1 min for 1 minute', () {
      final instruction = NavigationInstruction(
        instruction: 'Tourner',
        maneuver: 'turn-right',
        distanceMeters: 200,
        durationSeconds: 60,
        startLat: 5.0,
        startLng: -4.0,
      );
      expect(instruction.durationText, '1 min');
    });

    test('durationText shows N min for multiple minutes', () {
      final instruction = NavigationInstruction(
        instruction: 'Continuer',
        maneuver: 'straight',
        distanceMeters: 5000,
        durationSeconds: 600,
        startLat: 5.0,
        startLng: -4.0,
      );
      expect(instruction.durationText, '10 min');
    });

    test('maneuverIcon returns correct icons for all maneuvers', () {
      final cases = {
        'turn-left': Icons.turn_left,
        'turn-slight-left': Icons.turn_left,
        'turn-sharp-left': Icons.turn_left,
        'turn-right': Icons.turn_right,
        'turn-slight-right': Icons.turn_right,
        'turn-sharp-right': Icons.turn_right,
        'uturn-left': Icons.u_turn_right,
        'uturn-right': Icons.u_turn_right,
        'roundabout-left': Icons.roundabout_left,
        'roundabout-right': Icons.roundabout_left,
        'merge': Icons.merge,
        'fork-left': Icons.fork_right,
        'fork-right': Icons.fork_right,
        'ramp-left': Icons.ramp_right,
        'ramp-right': Icons.ramp_right,
        'ferry': Icons.directions_boat,
        'straight': Icons.straight,
        'unknown': Icons.straight,
      };
      for (final entry in cases.entries) {
        final instruction = NavigationInstruction(
          instruction: 'Test',
          maneuver: entry.key,
          distanceMeters: 100,
          durationSeconds: 60,
          startLat: 5.0,
          startLng: -4.0,
        );
        expect(
          instruction.maneuverIcon,
          entry.value,
          reason: 'maneuver ${entry.key} should return ${entry.value}',
        );
      }
    });
  });
}
