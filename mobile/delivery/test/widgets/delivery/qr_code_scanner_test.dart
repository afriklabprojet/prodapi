import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/delivery/qr_code_scanner.dart';

void main() {
  group('QRCodeScannerWidget', () {
    testWidgets('renders scanner widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QRCodeScannerWidget(onCodeScanned: (code) {})),
        ),
      );
      expect(find.byType(QRCodeScannerWidget), findsOneWidget);
    });

    testWidgets('renders with cancel callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QRCodeScannerWidget(
              onCodeScanned: (code) {},
              onCancel: () {},
            ),
          ),
        ),
      );
      expect(find.byType(QRCodeScannerWidget), findsOneWidget);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QRCodeScannerWidget(onCodeScanned: (code) {})),
        ),
      );
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Container widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QRCodeScannerWidget(onCodeScanned: (code) {})),
        ),
      );
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('contains Column widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QRCodeScannerWidget(onCodeScanned: (code) {})),
        ),
      );
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('DeliveryConfirmationDialog', () {
    testWidgets('renders dialog with delivery ID', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DeliveryConfirmationDialog(deliveryId: 42)),
        ),
      );
      expect(find.byType(DeliveryConfirmationDialog), findsOneWidget);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DeliveryConfirmationDialog(deliveryId: 42)),
        ),
      );
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DeliveryConfirmationDialog(deliveryId: 42)),
        ),
      );
      expect(find.byType(Icon), findsWidgets);
    });
  });
}
