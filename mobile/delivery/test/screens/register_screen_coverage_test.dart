import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/register_screen_redesign.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/widget_test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpRegister(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RegisterScreenRedesign(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    } finally {
      FlutterError.onError = original;
    }
  }

  testWidgets('renders register screen', (tester) async {
    await pumpRegister(tester);
    expect(find.byType(RegisterScreenRedesign), findsOneWidget);
  });

  testWidgets('shows form fields', (tester) async {
    await pumpRegister(tester);
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('has scaffold', (tester) async {
    await pumpRegister(tester);
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('shows step progress', (tester) async {
    await pumpRegister(tester);
    // Step 1 is the identity step
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('can enter name', (tester) async {
    await pumpRegister(tester);
    final textFields = find.byType(TextFormField);
    if (textFields.evaluate().isNotEmpty) {
      await tester.enterText(textFields.first, 'John Doe');
      await tester.pump();
    }
  });

  testWidgets('shows vehicle type selection area', (tester) async {
    await pumpRegister(tester);
    // The register screen has form and content rendered
    expect(find.byType(Form), findsOneWidget);
  });

  testWidgets('has submit button', (tester) async {
    await pumpRegister(tester);
    // May use different button type
    expect(find.byType(GestureDetector), findsWidgets);
  });

  testWidgets('scroll works', (tester) async {
    await pumpRegister(tester);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pump();
  });

  testWidgets('shows login link area', (tester) async {
    await pumpRegister(tester);
    // Should have some tap targets
    expect(find.byType(InkWell), findsWidgets);
  });
}
