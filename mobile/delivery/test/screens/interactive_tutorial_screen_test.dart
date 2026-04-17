import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/interactive_tutorial_screen.dart';
import 'package:courier/core/services/interactive_tutorial_service.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        interactiveTutorialProvider.overrideWith(() => _FakeTutorialService()),
      ],
      child: const MaterialApp(home: InteractiveTutorialScreen()),
    );
  }

  group('InteractiveTutorialScreen', () {
    testWidgets('renders with scaffold', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('displays tutorial title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Tutoriels'), findsOneWidget);
    });

    testWidgets('has AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has SingleChildScrollView', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('has Text widgets', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('has Column widget', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('has Icon widgets', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('has Container widgets', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays available tutorials text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Tutoriels disponibles'), findsOneWidget);
    });
  });
}

class _FakeTutorialService extends InteractiveTutorialService {
  @override
  InteractiveTutorialState build() => const InteractiveTutorialState();
}
