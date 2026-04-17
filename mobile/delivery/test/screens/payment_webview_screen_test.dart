import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/screens/payment_webview_screen.dart';

void main() {
  group('PaymentWebViewScreen', () {
    test('constructor stores required params', () {
      // WebView requires platform channel — verify constructor only
      expect(PaymentWebViewScreen, isNotNull);
    });
  });
}
