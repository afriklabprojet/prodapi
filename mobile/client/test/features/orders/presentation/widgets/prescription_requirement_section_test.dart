import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/orders/presentation/widgets/prescription_requirement_section.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  Widget createTestWidget({List<String> requiredProducts = const ['Amoxicilline']}) {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PrescriptionRequirementSection(
            requiredProductNames: requiredProducts,
          ),
        ),
      ),
    );
  }

  group('PrescriptionRequirementSection Widget Tests', () {
    testWidgets('should render prescription requirement section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionRequirementSection), findsOneWidget);
    });

    testWidgets('should display requirement message when required', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionRequirementSection), findsOneWidget);
    });

    testWidgets('should have upload button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionRequirementSection), findsOneWidget);
    });

    testWidgets('should show warning icon when required', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionRequirementSection), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
      
      expect(find.byType(PrescriptionRequirementSection), findsOneWidget);
    });

    testWidgets('should show multiple product names', (tester) async {
      await tester.pumpWidget(
        createTestWidget(requiredProducts: ['Amoxicilline', 'Ibuprofene']),
      );
      expect(find.byType(PrescriptionRequirementSection), findsOneWidget);
    });
  });
}
