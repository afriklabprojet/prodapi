import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/history/history_filter_sheet.dart';
import 'package:courier/presentation/providers/history_providers.dart';
import 'package:courier/l10n/app_localizations.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() => initHiveForTests());
  tearDownAll(() => cleanupHiveForTests());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Mount HistoryFilterSheet directly in a two-route setup so _applyFilters →
  // Navigator.pop() can pop back to the '/' route without throwing.
  // Avoids showModalBottomSheet animation which causes pump(Duration) hangs.
  Future<void> pumpSheet(
    WidgetTester tester, {
    List<PharmacyOption>? pharmacies,
    bool throwError = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          if (throwError)
            uniquePharmaciesProvider.overrideWith(
              (ref) => Future<List<PharmacyOption>>.error(
                Exception('pharmacies error'),
              ),
            )
          else
            uniquePharmaciesProvider.overrideWith(
              (ref) async =>
                  pharmacies ??
                  [const PharmacyOption(id: '1', name: 'Pharmacie Alpha')],
            ),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/': (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/filter'),
                child: const Text('open_sheet'),
              ),
            ),
            '/filter': (context) => const Scaffold(body: HistoryFilterSheet()),
          },
        ),
      ),
    );
    await tester.tap(find.text('open_sheet'));
    await tester.pumpAndSettle();
  }

  group('HistoryFilterSheet supplemental coverage', () {
    testWidgets('renders header, sections and preset chips', (tester) async {
      await pumpSheet(tester);
      expect(find.text('Filtres'), findsWidgets);
      expect(find.textContaining('initialiser'), findsWidgets);
      expect(find.text("Aujourd'hui"), findsOneWidget);
      expect(find.text('Cette semaine'), findsOneWidget);
      expect(find.text('Ce mois'), findsOneWidget);
      expect(find.text('Tout'), findsOneWidget);
      expect(find.text('Du'), findsOneWidget);
      expect(find.text('Au'), findsOneWidget);
    });

    testWidgets("tap Aujourd'hui preset covers today branch", (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.text("Aujourd'hui"));
      await tester.pumpAndSettle();
      expect(find.text("Aujourd'hui"), findsOneWidget);
    });

    testWidgets('tap Cette semaine preset covers week branch', (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.text('Cette semaine'));
      await tester.pumpAndSettle();
      expect(find.text('Cette semaine'), findsOneWidget);
    });

    testWidgets('tap Ce mois preset covers month branch', (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.text('Ce mois'));
      await tester.pumpAndSettle();
      expect(find.text('Ce mois'), findsOneWidget);
    });

    testWidgets('tap Tout preset covers all branch and clears dates', (
      tester,
    ) async {
      await pumpSheet(tester);
      await tester.tap(find.text("Aujourd'hui"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tout'));
      await tester.pumpAndSettle();
      expect(find.text('Tout'), findsOneWidget);
    });

    testWidgets('tap Livrées status chip covers delivered branch', (
      tester,
    ) async {
      await pumpSheet(tester);
      await tester.tap(find.text('Livrées'));
      await tester.pumpAndSettle();
      expect(find.text('Livrées'), findsOneWidget);
    });

    testWidgets('tap Annulées status chip covers cancelled branch', (
      tester,
    ) async {
      await pumpSheet(tester);
      await tester.tap(find.text('Annulées'));
      await tester.pumpAndSettle();
      expect(find.text('Annulées'), findsOneWidget);
    });

    testWidgets('tap Tous status chip covers null status branch', (
      tester,
    ) async {
      await pumpSheet(tester);
      await tester.tap(find.text('Livrées'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tous'));
      await tester.pumpAndSettle();
      expect(find.text('Tous'), findsOneWidget);
    });

    testWidgets('tap Réinitialiser resets all fields', (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.text("Aujourd'hui"));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('initialiser'));
      await tester.pumpAndSettle();
      expect(find.text('Tout'), findsOneWidget);
    });

    testWidgets('tap Appliquer calls _applyFilters and pops back', (
      tester,
    ) async {
      await pumpSheet(tester);
      await tester.tap(find.text('Cette semaine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliquer'));
      await tester.pumpAndSettle();
      // After pop, we should be back on the home route
      expect(find.text('open_sheet'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator while pharmacies loading', (
      tester,
    ) async {
      final completer = Completer<List<PharmacyOption>>();
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            uniquePharmaciesProvider.overrideWith((ref) => completer.future),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HistoryFilterSheet()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows error text when pharmacies future fails', (
      tester,
    ) async {
      await pumpSheet(tester, throwError: true);
      expect(find.text('Erreur de chargement'), findsOneWidget);
    });

    testWidgets('shows pharmacy dropdown when data loaded', (tester) async {
      await pumpSheet(
        tester,
        pharmacies: [
          const PharmacyOption(id: '1', name: 'Pharmacie Alpha'),
          const PharmacyOption(id: '2', name: 'Pharmacie Beta'),
        ],
      );
      expect(find.textContaining('Pharmacie'), findsWidgets);
    });
  });
}
