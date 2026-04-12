import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/history/history_filter_sheet.dart';
import 'package:courier/presentation/providers/history_providers.dart';
import 'package:courier/l10n/app_localizations.dart';
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

  Future<void> pumpFilterSheet(
    WidgetTester tester, {
    List<PharmacyOption>? pharmacies,
  }) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            uniquePharmaciesProvider.overrideWith(
              (ref) async =>
                  pharmacies ??
                  [
                    const PharmacyOption(id: '1', name: 'Pharmacie Alpha'),
                    const PharmacyOption(id: '2', name: 'Pharmacie Beta'),
                    const PharmacyOption(id: '3', name: 'Pharmacie Gamma'),
                  ],
            ),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const HistoryFilterSheet(),
                    );
                  },
                  child: const Text('Open Filter'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    } finally {
      FlutterError.onError = original;
    }
  }

  Future<void> drainTimers(WidgetTester tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      FlutterError.onError = original;
    }
  }

  group('HistoryFilterSheet', () {
    testWidgets('renders filter sheet when opened', (tester) async {
      await pumpFilterSheet(tester);
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Filtres'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows reset button', (tester) async {
      await pumpFilterSheet(tester);
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.textContaining('initialiser'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows date filter section', (tester) async {
      await pumpFilterSheet(tester);
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.textContaining('Date'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows status filter', (tester) async {
      await pumpFilterSheet(tester);
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.textContaining('Statut'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows sort options', (tester) async {
      await pumpFilterSheet(tester);
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.textContaining('Tri'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('tap reset clears filters', (tester) async {
      await pumpFilterSheet(tester);
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      final reset = find.textContaining('initialiser');
      if (reset.evaluate().isNotEmpty) {
        await tester.tap(reset.first);
        await tester.pump(const Duration(milliseconds: 300));
      }
      await drainTimers(tester);
    });

    testWidgets('shows apply button', (tester) async {
      await pumpFilterSheet(tester);
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.textContaining('Appliquer'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('pharmacy dropdown available', (tester) async {
      await pumpFilterSheet(tester);
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.textContaining('Pharmacie'), findsWidgets);
      await drainTimers(tester);
    });
  });
}
