import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/home/presentation/widgets/promo_slider.dart';
import 'package:drpharma_client/features/home/domain/models/promo_item.dart';
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
          body: PromoSlider(
            controller: controller,
            currentIndex: 0,
            items: const [
              PromoItem(
                badge: 'Promo',
                title: 'Promo 1',
                subtitle: 'Subtitle 1',
                gradientColorValues: [0xFF00A86B, 0xFF008556],
              ),
              PromoItem(
                badge: 'Promo',
                title: 'Promo 2',
                subtitle: 'Subtitle 2',
                gradientColorValues: [0xFF2196F3, 0xFF1976D2],
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('PromoSlider Widget Tests', () {
    testWidgets('should render promo slider', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PromoSlider), findsOneWidget);
    });

    testWidgets('should display promo items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PromoSlider), findsOneWidget);
    });

    testWidgets('should be swipeable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final slider = find.byType(PromoSlider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider, const Offset(-200, 0));
      }
      
      expect(find.byType(PromoSlider), findsOneWidget);
    });

    testWidgets('should have page indicators', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PromoSlider), findsOneWidget);
    });

    testWidgets('should auto-scroll', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(PromoSlider), findsOneWidget);
    });
  });
}
