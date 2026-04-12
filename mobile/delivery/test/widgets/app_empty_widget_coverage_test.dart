import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/common/app_empty_widget.dart';
import '../helpers/widget_test_helpers.dart';

Widget buildWidget(Widget child) {
  return ProviderScope(
    overrides: commonWidgetTestOverrides(),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUpAll(() => initHiveForTests());
  tearDownAll(() => cleanupHiveForTests());

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppEmptyWidget factory constructors', () {
    testWidgets('AppEmptyWidget.deliveries shows title and refresh button', (
      tester,
    ) async {
      bool refreshCalled = false;
      await tester.pumpWidget(
        buildWidget(
          AppEmptyWidget.deliveries(onRefresh: () => refreshCalled = true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('calme'), findsOneWidget);
      expect(find.text('Actualiser'), findsOneWidget);

      await tester.tap(find.text('Actualiser'));
      expect(refreshCalled, isTrue);
    });

    testWidgets('AppEmptyWidget.deliveries without onRefresh hides button', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.deliveries()));
      await tester.pumpAndSettle();

      expect(find.textContaining('calme'), findsOneWidget);
      expect(find.text('Actualiser'), findsNothing);
    });

    testWidgets('AppEmptyWidget.activeDeliveries shows correct text', (
      tester,
    ) async {
      bool goOnlineCalled = false;
      await tester.pumpWidget(
        buildWidget(
          AppEmptyWidget.activeDeliveries(
            onGoOnline: () => goOnlineCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pas de course en cours'), findsOneWidget);
      expect(find.text('Passer en ligne'), findsOneWidget);

      await tester.tap(find.text('Passer en ligne'));
      expect(goOnlineCalled, isTrue);
    });

    testWidgets('AppEmptyWidget.history shows title', (tester) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.history()));
      await tester.pumpAndSettle();

      expect(find.text('Ton historique est vide'), findsOneWidget);
    });

    testWidgets('AppEmptyWidget.earnings shows title', (tester) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.earnings()));
      await tester.pumpAndSettle();

      expect(find.textContaining('gain'), findsOneWidget);
    });

    testWidgets('AppEmptyWidget.chat shows title', (tester) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.chat()));
      await tester.pumpAndSettle();

      expect(find.text('Pas de message'), findsOneWidget);
    });

    testWidgets('AppEmptyWidget.challenges shows title and badge button', (
      tester,
    ) async {
      bool badgeCalled = false;
      await tester.pumpWidget(
        buildWidget(
          AppEmptyWidget.challenges(onViewBadges: () => badgeCalled = true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('défi'), findsAtLeastNWidgets(1));
      expect(find.text('Voir mes badges'), findsOneWidget);

      await tester.tap(find.text('Voir mes badges'));
      expect(badgeCalled, isTrue);
    });

    testWidgets('AppEmptyWidget.support shows title and contact button', (
      tester,
    ) async {
      bool contactCalled = false;
      await tester.pumpWidget(
        buildWidget(
          AppEmptyWidget.support(onContact: () => contactCalled = true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ticket'), findsOneWidget);
      expect(find.text('Contacter le support'), findsOneWidget);

      await tester.tap(find.text('Contacter le support'));
      expect(contactCalled, isTrue);
    });

    testWidgets('AppEmptyWidget.batch shows title', (tester) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.batch()));
      await tester.pumpAndSettle();

      expect(find.textContaining('group'), findsAtLeastNWidgets(1));
    });

    testWidgets('AppEmptyWidget.notifications shows title', (tester) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.notifications()));
      await tester.pumpAndSettle();

      expect(find.textContaining('lu'), findsOneWidget);
    });

    testWidgets('AppEmptyWidget.search with query shows query in message', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(AppEmptyWidget.search(query: 'aspirine')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('aspirine'), findsOneWidget);
    });

    testWidgets('AppEmptyWidget.search without query shows generic message', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.search()));
      await tester.pumpAndSettle();

      expect(find.textContaining('résultat'), findsOneWidget);
    });

    testWidgets('AppEmptyWidget animate=false renders without animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          const AppEmptyWidget(message: 'Test message', animate: false),
        ),
      );
      await tester.pump();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('AppEmptyWidget with subtitle shows subtitle', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const AppEmptyWidget(
            message: 'Titre vide',
            subtitle: 'Description du sous-titre',
            animate: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Titre vide'), findsOneWidget);
      expect(find.text('Description du sous-titre'), findsOneWidget);
    });
  });
}
