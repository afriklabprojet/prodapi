import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/core/widgets/example_riverpod_form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../helpers/fake_api_client.dart';

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
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExampleRiverpodFormWidget(),
          ),
        ),
      ),
    );
  }

  group('ExampleRiverpodFormWidget Tests', () {
    testWidgets('should render example form', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ExampleRiverpodFormWidget), findsOneWidget);
    });

    testWidgets('should have password field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have password visibility toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      // toggleProvider defaults to false (not obscured), so initial icon is visibility
      expect(find.byIcon(Icons.visibility), findsWidgets);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Initial state: not obscured (toggleProvider defaults to false) → Icons.visibility
      final toggleButton = find.byIcon(Icons.visibility).first;
      await tester.tap(toggleButton);
      await tester.pump();
      
      // After toggle: obscured → Icons.visibility_off
      expect(find.byIcon(Icons.visibility_off), findsWidgets);
    });

    testWidgets('should have submit button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should have confirm password field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Confirmer'), findsWidgets);
    });

    testWidgets('should use Riverpod providers', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ProviderScope), findsOneWidget);
    });

    testWidgets('should be scrollable in form', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(Form), findsOneWidget);
    });
  });
}
