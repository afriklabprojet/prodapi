import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/prescriptions/presentation/pages/prescription_scanner_page.dart';
import 'package:drpharma_client/features/prescriptions/presentation/providers/prescription_ocr_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_notifier.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockPrescriptionOcrNotifier extends StateNotifier<PrescriptionOcrState>
    with Mock
    implements PrescriptionOcrNotifier {
  MockPrescriptionOcrNotifier() : super(const PrescriptionOcrState());
}

class MockCartNotifier extends StateNotifier<CartState>
    with Mock
    implements CartNotifier {
  MockCartNotifier() : super(CartState.initial());
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({PrescriptionOcrState? initialState}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        prescriptionOcrProvider.overrideWith(
          (_) =>
              MockPrescriptionOcrNotifier()
                ..state = initialState ?? const PrescriptionOcrState(),
        ),
        cartProvider.overrideWith((_) => MockCartNotifier()),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PrescriptionScannerPage(),
      ),
    );
  }

  group('PrescriptionScannerPage Widget Tests', () {
    testWidgets('should render prescription scanner page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(PrescriptionScannerPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Scanner d\'ordonnance'), findsOneWidget);
    });

    testWidgets('should display instructions card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('should have help icon in app bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });
  });
}
