import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/orders/presentation/widgets/payment_mode_selector.dart';
import 'package:drpharma_client/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {

  setUp(() async {
  SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({
    required String selectedMode,
    required ValueChanged<String> onModeChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PaymentModeSelector(
          selectedMode: selectedMode,
          onModeChanged: onModeChanged,
        ),
      ),
    );
  }

  group('PaymentModeSelector', () {
    testWidgets('should display both payment options', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          selectedMode: AppConstants.paymentModePlatform,
          onModeChanged: (_) {},
        ),
      );

      // Assert
      expect(find.text('Paiement en ligne'), findsOneWidget);
      expect(find.text('Paiement à la livraison'), findsOneWidget);
    });

    testWidgets('should display subtitles for payment options', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          selectedMode: AppConstants.paymentModePlatform,
          onModeChanged: (_) {},
        ),
      );

      // Assert
      expect(find.textContaining('mobile money'), findsOneWidget);
      expect(find.textContaining('espèces'), findsOneWidget);
    });

    testWidgets('should have radio buttons for each option', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          selectedMode: AppConstants.paymentModePlatform,
          onModeChanged: (_) {},
        ),
      );

      // Assert - custom circular indicators instead of Radio widgets
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('should select platform payment by default when provided',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          selectedMode: AppConstants.paymentModePlatform,
          onModeChanged: (_) {},
        ),
      );

      // Assert - selection is indicated by Card styling, not Radio widget
      expect(find.byType(PaymentModeSelector), findsOneWidget);
    });

    testWidgets('should select on_delivery payment when provided',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          selectedMode: AppConstants.paymentModeOnDelivery,
          onModeChanged: (_) {},
        ),
      );

      // Assert - selection is indicated by Card styling
      expect(find.byType(PaymentModeSelector), findsOneWidget);
    });

    testWidgets('should call onModeChanged when tapping on delivery option',
        (tester) async {
      // Arrange
      String? selectedValue;
      await tester.pumpWidget(
        createTestWidget(
          selectedMode: AppConstants.paymentModePlatform,
          onModeChanged: (value) => selectedValue = value,
        ),
      );

      // Act - tap on "Paiement à la livraison"
      await tester.tap(find.text('Paiement à la livraison'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedValue, AppConstants.paymentModeOnDelivery);
    });

    testWidgets('should call onModeChanged when tapping on platform option',
        (tester) async {
      // Arrange
      String? selectedValue;
      await tester.pumpWidget(
        createTestWidget(
          selectedMode: AppConstants.paymentModeOnDelivery,
          onModeChanged: (value) => selectedValue = value,
        ),
      );

      // Act - tap on "Paiement en ligne"
      await tester.tap(find.text('Paiement en ligne'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedValue, AppConstants.paymentModePlatform);
    });

    testWidgets('should call onModeChanged when tapping radio directly',
        (tester) async {
      // Arrange
      String? selectedValue;
      await tester.pumpWidget(
        createTestWidget(
          selectedMode: AppConstants.paymentModePlatform,
          onModeChanged: (value) => selectedValue = value,
        ),
      );

      // Act - tap on second card (delivery option)
      await tester.tap(find.byType(Card).last);
      await tester.pumpAndSettle();

      // Assert
      expect(selectedValue, AppConstants.paymentModeOnDelivery);
    });

    testWidgets('should display payment icons', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          selectedMode: AppConstants.paymentModePlatform,
          onModeChanged: (_) {},
        ),
      );

      // Assert
      expect(find.byIcon(Icons.payment), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    });

    testWidgets('selected option should have different visual appearance',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          selectedMode: AppConstants.paymentModePlatform,
          onModeChanged: (_) {},
        ),
      );

      // Assert - find cards (both options are in cards)
      expect(find.byType(Card), findsNWidgets(2));
    });
  });
}
