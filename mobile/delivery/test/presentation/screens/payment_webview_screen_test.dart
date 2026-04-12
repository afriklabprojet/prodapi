import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:courier/data/repositories/jeko_payment_repository.dart';
import 'package:courier/presentation/screens/payment_webview_screen.dart';

// --- Fake WebView platform for tests ---

class FakeWebViewPlatformController extends PlatformWebViewController {
  FakeWebViewPlatformController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}
  @override
  Future<void> loadRequest(LoadRequestParams params) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> setUserAgent(String? userAgent) async {}
}

class FakeWebViewPlatformNavigationDelegate extends PlatformNavigationDelegate {
  FakeWebViewPlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}
  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}
  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}
  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}
  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}
  @override
  Future<void> setOnHttpAuthRequest(
    HttpAuthRequestCallback onHttpAuthRequest,
  ) async {}
}

class FakeWebViewPlatformWidget extends PlatformWebViewWidget {
  FakeWebViewPlatformWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return FakeWebViewPlatformController(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return FakeWebViewPlatformNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return FakeWebViewPlatformWidget(params);
  }
}

class MockJekoPaymentRepository extends Mock implements JekoPaymentRepository {}

void main() {
  late MockJekoPaymentRepository mockRepo;

  setUpAll(() {
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  setUp(() {
    mockRepo = MockJekoPaymentRepository();
  });

  group('PaymentWebViewScreen', () {
    testWidgets('renders with app bar and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentWebViewScreen(
            redirectUrl: 'https://jeko.example.com/pay?ref=TEST',
            reference: 'PAY-TEST',
            repository: mockRepo,
          ),
        ),
      );

      expect(find.text('Paiement sécurisé'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentWebViewScreen(
            redirectUrl: 'https://jeko.example.com/pay?ref=TEST',
            reference: 'PAY-TEST',
            repository: mockRepo,
          ),
        ),
      );

      // _isLoading starts true → CircularProgressIndicator shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('close button shows exit confirmation dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentWebViewScreen(
            redirectUrl: 'https://jeko.example.com/pay?ref=TEST',
            reference: 'PAY-TEST',
            repository: mockRepo,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      // Use pump() instead of pumpAndSettle() because the periodic
      // polling timer prevents settling
      await tester.pump();

      expect(find.text('Annuler le paiement ?'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
    });

    testWidgets('exit confirmation dismiss keeps screen open', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentWebViewScreen(
            redirectUrl: 'https://jeko.example.com/pay?ref=TEST',
            reference: 'PAY-TEST',
            repository: mockRepo,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Tap "Continuer" to dismiss dialog
      await tester.tap(find.text('Continuer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // animation

      // Dialog should be gone, screen still visible
      expect(find.text('Annuler le paiement ?'), findsNothing);
      expect(find.text('Paiement sécurisé'), findsOneWidget);
    });

    testWidgets('creates with correct parameters', (tester) async {
      const url = 'https://jeko.example.com/pay?ref=REF-123';
      const ref = 'REF-123';

      await tester.pumpWidget(
        MaterialApp(
          home: PaymentWebViewScreen(
            redirectUrl: url,
            reference: ref,
            repository: mockRepo,
          ),
        ),
      );

      final screen = tester.widget<PaymentWebViewScreen>(
        find.byType(PaymentWebViewScreen),
      );
      expect(screen.redirectUrl, url);
      expect(screen.reference, ref);
      expect(screen.repository, mockRepo);
    });

    testWidgets('exit confirmation Fermer pops with null', (tester) async {
      bool? popResult = false; // sentinel

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                popResult = await Navigator.of(context).push<bool?>(
                  MaterialPageRoute(
                    builder: (_) => PaymentWebViewScreen(
                      redirectUrl: 'https://jeko.example.com/pay',
                      reference: 'PAY-TEST',
                      repository: mockRepo,
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump(); // start route animation
      await tester.pump(const Duration(milliseconds: 500)); // finish animation

      // Tap close icon → open dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Tap "Fermer" → should pop with null
      await tester.tap(find.text('Fermer'));
      await tester.pump(); // start pop
      await tester.pump(const Duration(milliseconds: 500)); // finish animation

      expect(popResult, isNull);
    });
  });
}
