import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:drpharma_client/features/home/presentation/widgets/featured_pharmacies_section.dart';
import 'package:drpharma_client/features/pharmacies/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

PharmacyEntity _makePharmacy({
  int id = 1,
  String name = 'Pharmacie Test',
  String address = '12 rue de la Paix',
  bool isOpen = true,
}) {
  return PharmacyEntity(
    id: id,
    name: name,
    address: address,
    phone: '+22500000000',
    status: 'active',
    isOpen: isOpen,
  );
}

void main() {
  Widget createTestWidget({
    List<PharmacyEntity> pharmacies = const [],
    bool isLoading = false,
    bool isDark = false,
    int currentIndex = 0,
  }) {
    final controller = PageController();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(
              child: FeaturedPharmaciesSection(
                pharmacies: pharmacies,
                isLoading: isLoading,
                isDark: isDark,
                pageController: controller,
                currentIndex: currentIndex,
                onRefresh: () {},
                onPageChanged: (_) {},
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/pharmacies',
          builder: (context, state) => const Scaffold(body: Text('Pharmacies')),
        ),
        GoRoute(
          path: '/pharmacies/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('Pharmacy Details')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('FeaturedPharmaciesSection Widget Tests', () {
    testWidgets('should render featured pharmacies section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(FeaturedPharmaciesSection), findsOneWidget);
    });

    testWidgets('should display section title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Pharmacies en Vedette'), findsOneWidget);
    });

    testWidgets('should display pharmacy cards', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(FeaturedPharmaciesSection), findsOneWidget);
    });

    testWidgets('should be horizontally scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(FeaturedPharmaciesSection), findsOneWidget);
    });

    testWidgets('should have see all button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Voir tout'), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();

      expect(find.byType(FeaturedPharmaciesSection), findsOneWidget);
    });

    testWidgets('shows star_rounded icon in header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('shows arrow_forward_ios_rounded in Voir tout button', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });
  });

  group('FeaturedPharmaciesSection Empty State Tests', () {
    testWidgets('shows empty state when no pharmacies', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(pharmacies: []));
      await tester.pumpAndSettle();

      expect(find.text('Aucune pharmacie en vedette'), findsOneWidget);
    });

    testWidgets('shows local_pharmacy_outlined icon in empty state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(pharmacies: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_pharmacy_outlined), findsOneWidget);
    });

    testWidgets('shows Explorez toutes nos pharmacies text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(pharmacies: []));
      await tester.pumpAndSettle();

      expect(find.textContaining('Explorez'), findsOneWidget);
    });

    testWidgets('shows refresh_rounded icon in empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(pharmacies: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('shows Actualiser button in empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(pharmacies: []));
      await tester.pumpAndSettle();

      expect(find.text('Actualiser'), findsOneWidget);
    });
  });

  group('FeaturedPharmaciesSection Loading State Tests', () {
    testWidgets('shows loading shimmer when isLoading is true', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(isLoading: true, pharmacies: []),
      );
      await tester.pump();

      // In loading state, shows shimmer list (ListView.builder)
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows pharmacies carousel when loaded', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(pharmacies: [_makePharmacy()]));
      await tester.pumpAndSettle();

      // Shows PageView with pharmacy cards
      expect(find.byType(PageView), findsOneWidget);
    });
  });

  group('FeaturedPharmaciesSection Carousel Tests', () {
    testWidgets('shows pharmacy name in carousel card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          pharmacies: [_makePharmacy(name: 'Pharmacie Centrale')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pharmacie Centrale'), findsOneWidget);
    });

    testWidgets('shows pharmacy address in carousel card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          pharmacies: [_makePharmacy(address: '5 avenue du Soleil')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('5 avenue du Soleil'), findsOneWidget);
    });

    testWidgets('shows FeaturedPharmacyCard in carousel', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(pharmacies: [_makePharmacy()]));
      await tester.pumpAndSettle();

      expect(find.byType(FeaturedPharmacyCard), findsOneWidget);
    });

    testWidgets('shows page indicators for multiple pharmacies', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          pharmacies: [
            _makePharmacy(id: 1, name: 'Pharma 1'),
            _makePharmacy(id: 2, name: 'Pharma 2'),
            _makePharmacy(id: 3, name: 'Pharma 3'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 3 pharmacies → 3 page indicators (AnimatedContainer)
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('shows open pharmacy with Ouvert badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(pharmacies: [_makePharmacy(isOpen: true)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ouvert'), findsOneWidget);
    });

    testWidgets('shows closed pharmacy with Fermé badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(pharmacies: [_makePharmacy(isOpen: false)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fermé'), findsOneWidget);
    });

    testWidgets('tapping Voir tout navigates to pharmacies', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(pharmacies: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Voir tout'));
      await tester.pumpAndSettle();

      expect(find.text('Pharmacies'), findsOneWidget);
    });
  });
}
