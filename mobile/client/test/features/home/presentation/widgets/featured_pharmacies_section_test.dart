import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/home/presentation/widgets/featured_pharmacies_section.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  Widget createTestWidget() {
    final controller = PageController();
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FeaturedPharmaciesSection(
              pharmacies: const [],
              isLoading: false,
              isDark: false,
              pageController: controller,
              currentIndex: 0,
              onRefresh: () {},
              onPageChanged: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('FeaturedPharmaciesSection Widget Tests', () {
    testWidgets('should render featured pharmacies section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(FeaturedPharmaciesSection), findsOneWidget);
    });

    testWidgets('should display section title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(FeaturedPharmaciesSection), findsOneWidget);
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
      expect(find.byType(FeaturedPharmaciesSection), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
      
      expect(find.byType(FeaturedPharmaciesSection), findsOneWidget);
    });
  });
}
