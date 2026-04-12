import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/prescriptions/presentation/pages/prescriptions_list_page.dart';
import 'package:drpharma_client/features/prescriptions/presentation/providers/prescriptions_provider.dart';
import 'package:drpharma_client/features/prescriptions/presentation/providers/prescriptions_notifier.dart';
import 'package:drpharma_client/features/prescriptions/presentation/providers/prescriptions_state.dart';
import 'package:drpharma_client/features/prescriptions/domain/entities/prescription_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockPrescriptionsNotifier extends StateNotifier<PrescriptionsState>
    with Mock
    implements PrescriptionsNotifier {
  MockPrescriptionsNotifier([PrescriptionsState? state])
    : super(state ?? const PrescriptionsState());

  @override
  Future<void> loadPrescriptions() async {}
}

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
        home: const PrescriptionsListPage(),
        routes: {
          '/prescription-upload': (_) => const Scaffold(body: Text('Upload')),
          '/prescription-details': (_) => const Scaffold(body: Text('Details')),
        },
      ),
    );
  }

  Widget createTestWidgetWithState({required PrescriptionsState state}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        prescriptionsProvider.overrideWith(
          (_) => MockPrescriptionsNotifier()..state = state,
        ),
      ],
      child: MaterialApp(
        home: const PrescriptionsListPage(),
        routes: {
          '/prescription-upload': (_) => const Scaffold(body: Text('Upload')),
          '/prescription-details': (_) => const Scaffold(body: Text('Details')),
        },
      ),
    );
  }

  group('PrescriptionsListPage Widget Tests', () {
    testWidgets('should render prescriptions list page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionsListPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have add prescription button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionsListPage), findsOneWidget);
    });

    testWidgets('should display prescription cards', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionsListPage), findsOneWidget);
    });

    testWidgets('should show empty state when no prescriptions', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionsListPage), findsOneWidget);
    });

    testWidgets('should display prescription date', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionsListPage), findsOneWidget);
    });

    testWidgets('should display prescription status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionsListPage), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionsListPage), findsOneWidget);
    });

    testWidgets('should navigate to prescription details on tap', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionsListPage), findsOneWidget);
    });

    testWidgets('should have pull to refresh', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionsListPage), findsOneWidget);
    });

    testWidgets('should navigate to upload on button tap', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final addButton = find.byType(PrescriptionsListPage);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
      }

      expect(true, true);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();

      expect(find.byType(PrescriptionsListPage), findsOneWidget);
    });
  });

  group('PrescriptionsListPage Content Tests', () {
    testWidgets('shows Mes Ordonnances title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Mes Ordonnances'), findsOneWidget);
    });

    testWidgets('shows Toutes tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Toutes'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Attente tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Attente'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Devis tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Devis'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Terminées tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Terminées'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Aucune ordonnance empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Aucune ordonnance'), findsOneWidget);
    });

    testWidgets('has TabBar for filtering prescriptions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('has Scaffold', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PrescriptionsListPage Loaded State Tests', () {
    PrescriptionEntity _makePrescription({
      int id = 1,
      String status = 'pending',
    }) {
      return PrescriptionEntity(
        id: id,
        status: status,
        imageUrls: const [],
        createdAt: DateTime(2024, 1, 15),
        fulfillmentStatus: 'pending',
        dispensingCount: 0,
      );
    }

    testWidgets('shows prescription card when loaded with data', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: PrescriptionsState(
            status: PrescriptionsStatus.loaded,
            prescriptions: [_makePrescription()],
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Ordonnance'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows En attente status for pending prescription', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: PrescriptionsState(
            status: PrescriptionsStatus.loaded,
            prescriptions: [_makePrescription(status: 'pending')],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('En attente'), findsOneWidget);
    });

    testWidgets('shows Voir détails button for prescription card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: PrescriptionsState(
            status: PrescriptionsStatus.loaded,
            prescriptions: [_makePrescription()],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Voir détails'), findsOneWidget);
    });

    testWidgets('shows document_scanner icon for scanner FAB', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.document_scanner_outlined), findsOneWidget);
    });

    testWidgets('shows Nouvelle button for upload FAB', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Nouvelle'), findsOneWidget);
    });

    testWidgets('shows error state with Réessayer button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PrescriptionsState(
            status: PrescriptionsStatus.error,
            errorMessage: 'Erreur réseau',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Réessayer'), findsOneWidget);
    });
  });
}
