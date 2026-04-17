import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/login_screen_redesign.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/core/services/biometric_service.dart';
import 'package:courier/l10n/app_localizations.dart';
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

  Widget buildScreen() {
    final mockAuthRepo = MockAuthRepository();
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        biometricSettingsProvider.overrideWith(() => _FakeBiometricSettings()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const LoginScreenRedesign(),
      ),
    );
  }

  group('LoginScreenRedesign', () {
    testWidgets('renders login form', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows DR-PHARMA branding', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('DR-PHARMA'), findsWidgets);
    });

    testWidgets('shows text form fields', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('has ElevatedButton or FilledButton for login', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      // Main action button
      final elevated = find.byType(ElevatedButton);
      final filled = find.byType(FilledButton);
      expect(
        elevated.evaluate().length + filled.evaluate().length,
        greaterThanOrEqualTo(1),
      );
    });

    testWidgets('shows login action button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('can enter email text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
      await tester.enterText(textFields.first, 'test@test.com');
      await tester.pump();
      expect(find.text('test@test.com'), findsOneWidget);
    });

    testWidgets('has icon buttons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('has Scaffold with body', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}

class _FakeBiometricSettings extends BiometricSettingsNotifier {
  @override
  bool build() => false;
}
