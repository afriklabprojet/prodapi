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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('debug step 1: just pump widget', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          uniquePharmaciesProvider.overrideWith(
            (ref) async => [const PharmacyOption(id: '1', name: 'Alpha')],
          ),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HistoryFilterSheet.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Open'), findsOneWidget);
    // step 1 done - just verify widget pumps
  });

  testWidgets('debug step 2: direct HistoryFilterSheet (no modal)', (
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
          uniquePharmaciesProvider.overrideWith(
            (ref) async => [const PharmacyOption(id: '1', name: 'Alpha')],
          ),
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
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Filtres'), findsOneWidget);
  });
}
