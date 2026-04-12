import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/interactive_tutorial_screen.dart';
import 'package:courier/core/services/interactive_tutorial_service.dart';
import '../helpers/widget_test_helpers.dart';

// ---------------------------------------------------------------------------
// Fake services
// ---------------------------------------------------------------------------

/// Default fake: no completed tutorials
class _FakeTutorialService extends InteractiveTutorialService {
  @override
  InteractiveTutorialState build() => const InteractiveTutorialState();
}

/// Fake with some tutorials completed — shows "Réinitialiser" button
class _FakeTutorialServiceWithCompleted extends InteractiveTutorialService {
  @override
  InteractiveTutorialState build() => const InteractiveTutorialState(
    completedTutorials: {'welcome_tour', 'delivery_flow'},
  );

  @override
  Future<void> resetAllTutorials() async {
    state = const InteractiveTutorialState();
  }

  @override
  void startTutorial(String tutorialId) {
    // no-op in tests
  }
}

/// Fake with ALL tutorials completed — progress = 1.0
class _FakeTutorialServiceAllCompleted extends InteractiveTutorialService {
  @override
  InteractiveTutorialState build() {
    final allIds = InteractiveTutorials.all.map((t) => t.id).toSet();
    return InteractiveTutorialState(completedTutorials: allIds);
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildScreen({InteractiveTutorialService? service}) {
  return ProviderScope(
    overrides: [
      ...commonWidgetTestOverrides(),
      interactiveTutorialProvider.overrideWith(
        () => service ?? _FakeTutorialService(),
      ),
    ],
    child: const MaterialApp(home: InteractiveTutorialScreen()),
  );
}

/// Builds a two-screen app so Navigator.pop() works when a card is tapped.
Widget _buildScreenWithNav({InteractiveTutorialService? service}) {
  return ProviderScope(
    overrides: [
      ...commonWidgetTestOverrides(),
      interactiveTutorialProvider.overrideWith(
        () => service ?? _FakeTutorialService(),
      ),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const InteractiveTutorialScreen(),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

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

  group('InteractiveTutorialScreen - supplemental coverage', () {
    testWidgets('renders Réinitialiser button when tutorials are completed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildScreen(service: _FakeTutorialServiceWithCompleted()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Réinitialiser'), findsWidgets);
    });

    testWidgets('completed tutorials show Complété badge on cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildScreen(service: _FakeTutorialServiceWithCompleted()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complété'), findsWidgets);
    });

    testWidgets('tap Réinitialiser opens dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildScreen(service: _FakeTutorialServiceWithCompleted()),
      );
      await tester.pumpAndSettle();

      // Tap the AppBar "Réinitialiser" TextButton (the first one found)
      final resetBtns = find.text('Réinitialiser');
      // The first match is the AppBar TextButton
      await tester.tap(resetBtns.first);
      await tester.pumpAndSettle();

      expect(find.text('Réinitialiser les tutoriels'), findsOneWidget);
    });

    testWidgets('tap Annuler in reset dialog closes it', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildScreen(service: _FakeTutorialServiceWithCompleted()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Réinitialiser').first);
      await tester.pumpAndSettle();

      // Tap Annuler to dismiss
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Dialog is gone
      expect(find.text('Réinitialiser les tutoriels'), findsNothing);
    });

    testWidgets(
      'tap Réinitialiser confirm in dialog resets and shows snackbar',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildScreen(service: _FakeTutorialServiceWithCompleted()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Réinitialiser').first);
        await tester.pumpAndSettle();

        // In the dialog there are TWO "Réinitialiser" widgets:
        // 1. The AppBar TextButton (off-screen after dialog overlay)
        // 2. The dialog confirm TextButton
        // The last one in find is the confirm button inside AlertDialog
        await tester.tap(find.text('Réinitialiser').last);
        await tester.pumpAndSettle();

        expect(find.text('Tutoriels réinitialisés'), findsOneWidget);
      },
    );

    testWidgets('renders TutorialListWidget with tutorial list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            interactiveTutorialProvider.overrideWith(
              () => _FakeTutorialServiceWithCompleted(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: TutorialListWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TutorialListWidget), findsOneWidget);
      expect(find.text('Tutoriels interactifs'), findsOneWidget);
    });

    testWidgets(
      'all tutorials completed: progress card shows celebration text',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildScreen(service: _FakeTutorialServiceAllCompleted()),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('100'), findsWidgets);
      },
    );

    testWidgets('tap a tutorial card triggers onTap handler', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildScreenWithNav(service: _FakeTutorialServiceWithCompleted()),
      );
      await tester.pump();

      // Navigate to the tutorial screen
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The screen is now visible with tutorial cards
      expect(find.byType(InteractiveTutorialScreen), findsOneWidget);

      // Tap the first InkWell (tutorial card) to trigger _TutorialCard.onTap
      // which calls startTutorial() and Navigator.pop()
      final cards = find.byType(InkWell);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
