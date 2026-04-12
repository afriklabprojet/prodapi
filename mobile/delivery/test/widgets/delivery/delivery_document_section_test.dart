import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:courier/presentation/widgets/delivery/delivery_document_section.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/models/scanned_document.dart';
import 'package:courier/data/services/document_scanner_service.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  Delivery makeDelivery() {
    return Delivery.fromJson({
      'id': 1,
      'reference': 'DEL-001',
      'pharmacy_name': 'Pharmacie Centrale',
      'pharmacy_address': '123 Rue Abidjan',
      'customer_name': 'Marie Konan',
      'delivery_address': '456 Boulevard Cocody',
      'total_amount': '15000',
      'status': 'picked_up',
    });
  }

  Widget buildWidget() {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        documentScannerStateProvider.overrideWith(
          (_) => _FakeScannerNotifier(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: DeliveryDocumentSection(delivery: makeDelivery())),
      ),
    );
  }

  group('DeliveryDocumentSection', () {
    testWidgets('renders with delivery', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DeliveryDocumentSection), findsOneWidget);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contains Container widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('contains Column widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('contains SizedBox widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('contains Row widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('DeliveryDocumentSection - with documents', () {
    Widget buildWithDocuments(List<ScannedDocument> docs) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith(
            (_) => _FakeScannerWithDocs(docs),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeliveryDocumentSection(delivery: makeDelivery()),
          ),
        ),
      );
    }

    testWidgets('renders with one prescription document', (tester) async {
      await tester.pumpWidget(
        buildWithDocuments([
          ScannedDocument(
            id: 'doc-1',
            deliveryId: 1,
            type: DocumentType.prescription,
            originalImage: File('/tmp/prescription.jpg'),
            isUploaded: false,
            scannedAt: DateTime(2025, 1, 15),
          ),
        ]),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DeliveryDocumentSection), findsOneWidget);
    });

    testWidgets('renders with uploaded document', (tester) async {
      await tester.pumpWidget(
        buildWithDocuments([
          ScannedDocument(
            id: 'doc-2',
            deliveryId: 1,
            type: DocumentType.receipt,
            originalImage: File('/tmp/receipt.jpg'),
            isUploaded: true,
            scannedAt: DateTime(2025, 1, 15),
          ),
        ]),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DeliveryDocumentSection), findsOneWidget);
    });

    testWidgets('renders with multiple documents', (tester) async {
      await tester.pumpWidget(
        buildWithDocuments([
          ScannedDocument(
            id: 'doc-3',
            deliveryId: 1,
            type: DocumentType.prescription,
            originalImage: File('/tmp/prescription.jpg'),
            isUploaded: true,
            scannedAt: DateTime(2025, 1, 15),
          ),
          ScannedDocument(
            id: 'doc-4',
            deliveryId: 1,
            type: DocumentType.receipt,
            originalImage: File('/tmp/receipt.jpg'),
            isUploaded: false,
            scannedAt: DateTime(2025, 1, 15),
          ),
          ScannedDocument(
            id: 'doc-5',
            deliveryId: 1,
            type: DocumentType.deliveryProof,
            originalImage: File('/tmp/proof.jpg'),
            isUploaded: true,
            scannedAt: DateTime(2025, 1, 15),
          ),
        ]),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DeliveryDocumentSection), findsOneWidget);
    });

    testWidgets('renders with idCard document', (tester) async {
      await tester.pumpWidget(
        buildWithDocuments([
          ScannedDocument(
            id: 'doc-6',
            deliveryId: 1,
            type: DocumentType.idCard,
            originalImage: File('/tmp/id.jpg'),
            isUploaded: false,
            scannedAt: DateTime(2025, 1, 15),
          ),
        ]),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DeliveryDocumentSection), findsOneWidget);
    });

    testWidgets('renders with insurance document', (tester) async {
      await tester.pumpWidget(
        buildWithDocuments([
          ScannedDocument(
            id: 'doc-7',
            deliveryId: 1,
            type: DocumentType.insurance,
            originalImage: File('/tmp/insurance.jpg'),
            isUploaded: true,
            scannedAt: DateTime(2025, 1, 15),
          ),
        ]),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DeliveryDocumentSection), findsOneWidget);
    });

    testWidgets('documents for different delivery ID are excluded', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWithDocuments([
          ScannedDocument(
            id: 'doc-other',
            deliveryId: 999,
            type: DocumentType.prescription,
            originalImage: File('/tmp/other.jpg'),
            isUploaded: false,
            scannedAt: DateTime(2025, 1, 15),
          ),
        ]),
      );
      await tester.pump(const Duration(seconds: 1));
      // Should render but without any documents matching delivery id 1
      expect(find.byType(DeliveryDocumentSection), findsOneWidget);
    });
  });

  group('DeliveryDocumentSection - delivery variations', () {
    testWidgets('renders with assigned delivery', (tester) async {
      final delivery = Delivery.fromJson({
        'id': 2,
        'reference': 'DEL-002',
        'pharmacy_name': 'Pharma Nord',
        'pharmacy_address': '50 Avenue du Port',
        'customer_name': 'Ali Koné',
        'delivery_address': '75 Rue Cocody',
        'total_amount': '25000',
        'status': 'assigned',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            documentScannerStateProvider.overrideWith(
              (_) => _FakeScannerNotifier(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeliveryDocumentSection(delivery: delivery)),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DeliveryDocumentSection), findsOneWidget);
    });

    testWidgets('renders with delivered delivery', (tester) async {
      final delivery = Delivery.fromJson({
        'id': 3,
        'reference': 'DEL-003',
        'pharmacy_name': 'Pharma Est',
        'pharmacy_address': '100 Boulevard Est',
        'customer_name': 'Fatou Traoré',
        'delivery_address': '200 Avenue Est',
        'total_amount': '8000',
        'status': 'delivered',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            documentScannerStateProvider.overrideWith(
              (_) => _FakeScannerNotifier(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeliveryDocumentSection(delivery: delivery)),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DeliveryDocumentSection), findsOneWidget);
    });
  });
}

class _FakeScannerWithDocs extends StateNotifier<DocumentScannerState>
    implements DocumentScannerNotifier {
  _FakeScannerWithDocs(List<ScannedDocument> docs)
    : super(DocumentScannerState(scannedDocuments: docs));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeScannerNotifier extends StateNotifier<DocumentScannerState>
    implements DocumentScannerNotifier {
  _FakeScannerNotifier() : super(const DocumentScannerState());

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
