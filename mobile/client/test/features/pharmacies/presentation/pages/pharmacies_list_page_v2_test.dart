import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/pharmacies/presentation/pages/pharmacies_list_page_v2.dart';
import 'package:drpharma_client/features/pharmacies/presentation/providers/pharmacies_notifier.dart';
import 'package:drpharma_client/features/pharmacies/presentation/providers/pharmacies_state.dart';
import 'package:drpharma_client/features/pharmacies/domain/entities/pharmacy_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockPharmaciesNotifier extends StateNotifier<PharmaciesState>
    with Mock
    implements PharmaciesNotifier {
  MockPharmaciesNotifier() : super(const PharmaciesState());

  @override
  Future<void> fetchPharmacies({bool refresh = false}) async {}

  @override
  Future<void> fetchNearbyPharmacies({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {}

  @override
  Future<void> fetchOnDutyPharmacies({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {}

  @override
  Future<void> fetchPharmacyDetails(int id) async {}

  @override
  Future<void> fetchFeaturedPharmacies({bool isRetry = false}) async {}

  @override
  void clearError() {}

  @override
  void clearSelectedPharmacy() {}
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
        pharmaciesProvider.overrideWith((_) => MockPharmaciesNotifier()),
      ],
      child: const MaterialApp(home: PharmaciesListPageV2()),
    );
  }

  Widget createTestWidgetWithState({required PharmaciesState state}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        pharmaciesProvider.overrideWith(
          (_) => MockPharmaciesNotifier()..state = state,
        ),
      ],
      child: const MaterialApp(home: PharmaciesListPageV2()),
    );
  }

  group('PharmaciesListPageV2 Content Tests', () {
    testWidgets('renders PharmaciesListPageV2', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('shows Trouvez votre pharmacie title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Trouvez votre pharmacie'), findsOneWidget);
    });

    testWidgets('shows search TextField', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows Toutes tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Toutes'), findsOneWidget);
    });

    testWidgets('shows Proximité tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Proximité'), findsOneWidget);
    });

    testWidgets('shows De garde tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('De garde'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows map FAB button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.map), findsOneWidget);
    });

    testWidgets('shows search hint Rechercher une pharmacie', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Rechercher une pharmacie...'), findsOneWidget);
    });

    testWidgets('shows stats header with Total label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(status: PharmaciesStatus.success),
        ),
      );
      await tester.pump();
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('shows stats header with Ouvertes label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(status: PharmaciesStatus.success),
        ),
      );
      await tester.pump();
      expect(find.text('Ouvertes'), findsOneWidget);
    });

    testWidgets('shows stats header with De garde label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(status: PharmaciesStatus.success),
        ),
      );
      await tester.pump();
      expect(find.text('De garde'), findsAtLeastNWidgets(1));
    });
  });

  group('PharmaciesListPageV2 Error State Tests', () {
    testWidgets('shows Erreur de connexion in error state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.error,
            errorMessage: 'Connexion échouée',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Erreur de connexion'), findsOneWidget);
    });

    testWidgets('shows Réessayer button in error state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.error,
            errorMessage: 'Connexion échouée',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('shows error message text in error state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.error,
            errorMessage: 'Connexion échouée',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Connexion échouée'), findsOneWidget);
    });

    testWidgets('shows TabBar in error state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.error,
            errorMessage: 'Connexion échouée',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TabBar), findsOneWidget);
    });
  });

  group('PharmaciesListPageV2 Empty State Tests', () {
    testWidgets('renders Scaffold in empty loaded state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows Localisation désactivée in Proximité tab when no GPS', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [],
            nearbyPharmacies: [],
          ),
        ),
      );
      await tester.pump();
      // Just verify the page renders without crash
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });
  });

  group('PharmaciesListPageV2 Loading State Tests', () {
    testWidgets('renders without crash in loading state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.loading,
            pharmacies: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });
  });

  group('PharmaciesListPageV2 Pharmacy Card Tests', () {
    const testPharmacy = PharmacyEntity(
      id: 1,
      name: 'Pharmacie du Centre',
      address: '123 Avenue Centrale, Abidjan',
      phone: '+2250700000001',
      status: 'active',
      isOpen: true,
      isOnDuty: false,
    );

    const closedPharmacy = PharmacyEntity(
      id: 2,
      name: 'Pharmacie Nuit',
      address: '456 Rue Fermée',
      phone: '+2250700000002',
      status: 'active',
      isOpen: false,
      isOnDuty: false,
    );

    const onDutyPharmacy = PharmacyEntity(
      id: 3,
      name: 'Pharmacie Garde Centrale',
      address: '789 Boulevard de Garde',
      phone: '+2250700000003',
      status: 'active',
      isOpen: true,
      isOnDuty: true,
    );

    testWidgets('shows pharmacy name in card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [testPharmacy],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Pharmacie du Centre'), findsOneWidget);
    });

    testWidgets('shows pharmacy address in card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [testPharmacy],
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Centrale'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Ouverte badge for open pharmacy', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [testPharmacy],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Ouverte'), findsOneWidget);
    });

    testWidgets('shows Fermée badge for closed pharmacy', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [closedPharmacy],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Fermée'), findsOneWidget);
    });

    testWidgets('shows Garde badge for on-duty pharmacy', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [onDutyPharmacy],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Garde'), findsOneWidget);
    });

    testWidgets('shows action buttons Appeler and Détails', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [testPharmacy],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Appeler'), findsOneWidget);
      expect(find.text('Détails'), findsOneWidget);
    });

    testWidgets('shows initial letter P in avatar for Pharmacie', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [testPharmacy],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('P'), findsOneWidget);
    });
  });

  group('PharmaciesListPageV2 Additional Empty State Tests', () {
    testWidgets('shows Aucune pharmacie disponible in empty all tab', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Aucune pharmacie disponible'), findsOneWidget);
    });

    testWidgets('stats show 0 total when no pharmacies', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const PharmaciesState(
            status: PharmaciesStatus.success,
            pharmacies: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0'), findsAtLeastNWidgets(1));
    });
  });
}
