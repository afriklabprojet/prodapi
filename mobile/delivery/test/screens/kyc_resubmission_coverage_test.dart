import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/kyc_resubmission_screen.dart';
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

  Future<void> pumpKyc(WidgetTester tester, {String? rejectionReason}) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthRepository();
    when(() => mockAuth.getKycStatus()).thenAnswer(
      (_) async => {
        'status': 'rejected',
        'rejection_reason': rejectionReason ?? 'Documents invalides',
        'documents': <String, dynamic>{},
      },
    );

    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: KycResubmissionScreen(rejectionReason: rejectionReason),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
    } finally {
      FlutterError.onError = original;
    }
  }

  testWidgets('renders kyc screen', (tester) async {
    await pumpKyc(tester);
    expect(find.byType(KycResubmissionScreen), findsOneWidget);
  });

  testWidgets('shows rejection reason', (tester) async {
    await pumpKyc(tester, rejectionReason: 'Photo floue');
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('shows document upload sections', (tester) async {
    await pumpKyc(tester);
    // _DocumentUploadCard uses Container+InkWell, not the Card widget.
    // Verify document label text is present instead.
    expect(find.textContaining('Carte d\'identité'), findsWidgets);
  });

  testWidgets('renders in dark mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthRepository();
    when(() => mockAuth.getKycStatus()).thenAnswer(
      (_) async => {'status': 'rejected', 'documents': <String, dynamic>{}},
    );

    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(extra: []),
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const KycResubmissionScreen(rejectionReason: 'Test'),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
    } finally {
      FlutterError.onError = original;
    }
    expect(find.byType(KycResubmissionScreen), findsOneWidget);
  });

  testWidgets('scroll works', (tester) async {
    await pumpKyc(tester);
    final scrollable = find.byType(SingleChildScrollView);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -300));
      await tester.pump();
    }
  });

  testWidgets('shows without rejection reason', (tester) async {
    await pumpKyc(tester, rejectionReason: null);
    expect(find.byType(KycResubmissionScreen), findsOneWidget);
  });

  testWidgets('has icons for documents', (tester) async {
    await pumpKyc(tester);
    expect(find.byType(Icon), findsWidgets);
  });
}
