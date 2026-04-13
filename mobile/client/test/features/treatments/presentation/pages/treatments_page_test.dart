import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/treatments/presentation/pages/treatments_page.dart';
import 'package:drpharma_client/features/treatments/presentation/providers/treatments_provider.dart';
import 'package:drpharma_client/features/treatments/presentation/providers/treatments_state.dart';
import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';
import 'package:drpharma_client/features/treatments/presentation/widgets/widgets.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockTreatmentsNotifier extends StateNotifier<TreatmentsState>
    with Mock
    implements TreatmentsNotifier {
  MockTreatmentsNotifier() : super(const TreatmentsState());

  @override
  Future<void> loadTreatments() async {}
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({TreatmentsState? initialState}) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const TreatmentsPage()),
        GoRoute(
          path: '/add-treatment',
          builder: (context, state) =>
              const Scaffold(body: Text('Add Treatment')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        treatmentsProvider.overrideWith(
          (_) =>
              MockTreatmentsNotifier()
                ..state = initialState ?? const TreatmentsState(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  group('TreatmentsPage Widget Tests', () {
    testWidgets('should render treatments page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(TreatmentsPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Mes traitements'), findsOneWidget);
    });

    testWidgets('should show skeleton loading when loading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const TreatmentsState(status: TreatmentsStatus.loading),
        ),
      );
      await tester.pump();
      expect(find.byType(TreatmentCardSkeleton), findsNWidgets(3));
    });

    testWidgets('should have floating action button to add treatment', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should have info icon in app bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('TreatmentsPage Error State Tests', () {
    testWidgets('shows Réessayer button in error state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const TreatmentsState(
            status: TreatmentsStatus.error,
            errorMessage: 'Erreur réseau',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('shows error message in error state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const TreatmentsState(
            status: TreatmentsStatus.error,
            errorMessage: 'Erreur réseau',
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Erreur'), findsAtLeastNWidgets(1));
    });

    testWidgets('has AppBar in error state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const TreatmentsState(
            status: TreatmentsStatus.error,
            errorMessage: 'Erreur réseau',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Mes traitements'), findsOneWidget);
    });
  });

  group('TreatmentsPage Empty State Tests', () {
    testWidgets('shows empty state text when loaded with no treatments', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [],
          ),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining('Aucune traitement').evaluate().isNotEmpty ||
            find.textContaining('Ajouter un traitement').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('shows FAB even in empty loaded state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('does not show CircularProgressIndicator when loaded', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('TreatmentsPage Loaded State Tests', () {
    TreatmentEntity makeTreatment({
      String id = 't1',
      String name = 'Paracétamol 500mg',
      int productId = 1,
      int renewalDays = 30,
    }) {
      return TreatmentEntity(
        id: id,
        productId: productId,
        productName: name,
        renewalPeriodDays: renewalDays,
        reminderEnabled: false,
        reminderDaysBefore: 3,
        isActive: true,
        createdAt: DateTime(2024),
      );
    }

    testWidgets('shows treatment name in loaded state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [makeTreatment()],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.textContaining('Paracétamol'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Modifier button in modal when card tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [makeTreatment()],
          ),
        ),
      );
      // Let tratment card animations complete
      await tester.pumpAndSettle(const Duration(seconds: 2));
      // Tap the treatment card to open modal
      await tester.tap(find.textContaining('Paracétamol'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Modifier'), findsOneWidget);
    });

    testWidgets('shows Commander button for treatment', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [makeTreatment()],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Commander'), findsOneWidget);
    });

    testWidgets('shows edit_outlined icon in modal when card tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [makeTreatment()],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.textContaining('Paracétamol'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('shows shopping cart icon for treatments', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [makeTreatment()],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('shows renewal period in treatment card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [makeTreatment(renewalDays: 30)],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // Renewal period shown in card via calendar icon or in modal
      expect(
        find.byIcon(Icons.calendar_today_outlined),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows Actifs section header when has treatments', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [makeTreatment()],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.textContaining('Tous mes'), findsAtLeastNWidgets(1));
    });

    testWidgets('opens info dialog on info_outline tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: const TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [],
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pump();
      expect(find.text('Compris'), findsOneWidget);
    });

    testWidgets('can close info dialog with Compris button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: const TreatmentsState(
            status: TreatmentsStatus.loaded,
            treatments: [],
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pump();
      await tester.tap(find.text('Compris'));
      await tester.pump();
      expect(find.text('Compris'), findsNothing);
    });
  });
}
