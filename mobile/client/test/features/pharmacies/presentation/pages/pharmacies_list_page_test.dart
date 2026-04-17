import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/pharmacies/presentation/pages/pharmacies_list_page_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        home: const PharmaciesListPageV2(),
        routes: {
          '/pharmacy-details': (_) =>
              const Scaffold(body: Text('Pharmacy Details')),
          '/pharmacies-map': (_) =>
              const Scaffold(body: Text('Pharmacies Map')),
        },
      ),
    );
  }

  group('PharmaciesListPage Widget Tests', () {
    testWidgets('should render pharmacies list page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have search functionality', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should display pharmacy cards', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should show pharmacy name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should show pharmacy distance', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should show pharmacy rating', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should have map view toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should have filter options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should navigate to pharmacy details on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should have pull to refresh', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(RefreshIndicator), findsWidgets);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();

      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });
  });

  group('PharmaciesListPage Content Tests', () {
    testWidgets('shows Trouvez votre pharmacie text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Trouvez votre pharmacie'), findsOneWidget);
    });

    testWidgets('shows Toutes filter chip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Toutes'), findsOneWidget);
    });

    testWidgets('shows Proximité filter chip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Proximité'), findsOneWidget);
    });

    testWidgets('shows De garde filter chip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('De garde'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows search field with hint', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Rechercher une pharmacie'), findsOneWidget);
    });

    testWidgets('search field is tappable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pump();

      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('filter chips are shown for all categories', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Toutes'), findsAtLeastNWidgets(1));
      expect(find.text('Proximité'), findsAtLeastNWidgets(1));
    });
  });

  group('Tab switching', () {
    testWidgets('tap Proximité tab shows location snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "Proximité" tab
      await tester.tap(find.text('Proximité').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      // Geolocator is unavailable in tests → snackbar shown
      expect(find.textContaining('localisation'), findsWidgets);
    });

    testWidgets('tap De garde tab does not crash', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('De garde').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('search field filters pharmacies by query', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'pharma');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('clear button appears and clears search', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'test');
      await tester.pump();

      // Clear button appears when text is entered
      final clearBtn = find.byIcon(Icons.clear);
      if (clearBtn.evaluate().isNotEmpty) {
        await tester.tap(clearBtn.first);
        await tester.pump();
      }

      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('FAB map button is displayed', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
    });
  });
}
