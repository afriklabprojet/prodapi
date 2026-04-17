import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/treatments/presentation/pages/add_treatment_page.dart';
import 'package:drpharma_client/features/treatments/presentation/providers/treatments_provider.dart';
import 'package:drpharma_client/features/treatments/presentation/providers/treatments_state.dart';
import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_provider.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_notifier.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_state.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
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

  @override
  Future<bool> addTreatment(TreatmentEntity treatment) async => true;
}

class MockProductsNotifier extends StateNotifier<ProductsState>
    with Mock
    implements ProductsNotifier {
  MockProductsNotifier([ProductsState? state])
    : super(state ?? const ProductsState.initial());

  @override
  Future<void> searchProducts(String query) async {}

  @override
  void clearSearch() {}
}

ProductEntity _makeProduct({
  int id = 1,
  String name = 'Paracétamol 500mg',
  String pharmacyName = 'Pharmacie Centrale',
}) {
  return ProductEntity(
    id: id,
    name: name,
    price: 500.0,
    stockQuantity: 10,
    requiresPrescription: false,
    pharmacy: PharmacyEntity(
      id: 1,
      name: pharmacyName,
      address: '12 rue Test',
      phone: '+22500000000',
      status: 'active',
      isOpen: true,
    ),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({
    ProductsState? productsState,
    ProductEntity? initialProduct,
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              AddTreatmentPage(initialProduct: initialProduct),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        treatmentsProvider.overrideWith((_) => MockTreatmentsNotifier()),
        productsProvider.overrideWith(
          (_) => MockProductsNotifier(productsState),
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

  group('AddTreatmentPage Widget Tests', () {
    testWidgets('should render add treatment page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(AddTreatmentPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Ajouter un traitement'), findsOneWidget);
    });

    testWidgets('should have a form', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should display medication section', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Médicament'), findsOneWidget);
    });
  });

  group('AddTreatmentPage Sections Tests', () {
    testWidgets('shows Détails du traitement section', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Détails du traitement'), findsOneWidget);
    });

    testWidgets('shows Renouvellement section', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Renouvellement'), findsOneWidget);
    });

    testWidgets('shows Rappels section', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Rappels'), findsOneWidget);
    });

    testWidgets('shows search text field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Rechercher un médicament...'), findsOneWidget);
    });

    testWidgets('shows Dosage field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Dosage (optionnel)'), findsOneWidget);
    });

    testWidgets('shows Fréquence de prise dropdown', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Fréquence de prise'), findsOneWidget);
    });

    testWidgets('shows Activer les rappels switch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Activer les rappels'), findsOneWidget);
    });

    testWidgets('shows renewal period choice chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('shows Notes field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Notes (optionnel)'), findsOneWidget);
    });
  });

  group('AddTreatmentPage Save Button Tests', () {
    testWidgets('save button is disabled when no product selected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.byWidgetPredicate((w) => w is ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows save icon on Enregistrer button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save), findsOneWidget);
    });
  });

  group('AddTreatmentPage with Initial Product Tests', () {
    testWidgets('shows selected product card when initialProduct provided', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialProduct: _makeProduct(name: 'Ibuprofène 400mg'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ibuprofène 400mg'), findsOneWidget);
    });

    testWidgets('shows pharmacy name in product card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialProduct: _makeProduct(pharmacyName: 'Pharmacie du Marché'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pharmacie du Marché'), findsOneWidget);
    });

    testWidgets('save button enabled when product is selected', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(initialProduct: _makeProduct()));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.byWidgetPredicate((w) => w is ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows close button to deselect product', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(initialProduct: _makeProduct()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping close button deselects product', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialProduct: _makeProduct(name: 'Produit à désélectionner'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // After deselecting, search field reappears
      expect(find.text('Rechercher un médicament...'), findsOneWidget);
    });
  });

  group('AddTreatmentPage Search Results Tests', () {
    testWidgets('shows search results when products loaded and text entered', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loadedState = ProductsState(
        status: ProductsStatus.loaded,
        products: [_makeProduct(name: 'Aspirine 500mg')],
      );

      await tester.pumpWidget(createTestWidget(productsState: loadedState));
      await tester.pumpAndSettle();

      // Enter search text to trigger results display
      await tester.enterText(find.byType(TextField).first, 'Asp');
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Aspirine 500mg'), findsOneWidget);
    });

    testWidgets('shows Aucun produit trouvé when no results', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final emptyLoaded = const ProductsState(
        status: ProductsStatus.loaded,
        products: [],
      );

      await tester.pumpWidget(createTestWidget(productsState: emptyLoaded));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'xyz');
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Aucun produit trouvé'), findsOneWidget);
    });

    testWidgets('selecting product from results shows product card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loadedState = ProductsState(
        status: ProductsStatus.loaded,
        products: [_makeProduct(name: 'Doliprane 1000mg')],
      );

      await tester.pumpWidget(createTestWidget(productsState: loadedState));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Dol');
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('Doliprane 1000mg'));
      await tester.pumpAndSettle();

      // Product card should appear
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('AddTreatmentPage Reminder Tests', () {
    testWidgets('reminder days dropdown visible when reminder enabled', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Reminder is enabled by default, so days dropdown should show
      expect(find.text('Me rappeler '), findsOneWidget);
    });

    testWidgets('disabling reminder hides days section', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Toggle off the reminder switch
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      // Days dropdown should disappear
      expect(find.text('Me rappeler '), findsNothing);
    });
  });

  group('AddTreatmentPage Renewal Period Tests', () {
    testWidgets('shows multiple ChoiceChips for renewal period', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('quantity field validates empty value', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(initialProduct: _makeProduct()));
      await tester.pumpAndSettle();

      // Clear quantity field (dosage=0, quantity=1 with text '1', notes=2)
      // With initialProduct set, search field is replaced by product card
      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.tap(find.byWidgetPredicate((w) => w is ElevatedButton));
      await tester.pump();

      expect(find.text('Requis'), findsOneWidget);
    });
  });
}
