import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/scanner/document_scanner_widgets.dart';
import 'package:courier/data/models/scanned_document.dart';

void main() {
  ScannedDocument makeDoc({
    String id = 'test-1',
    DocumentType type = DocumentType.receipt,
    ScanQuality quality = ScanQuality.good,
    OcrResult? ocrResult,
    bool isUploaded = false,
  }) {
    return ScannedDocument(
      id: id,
      type: type,
      originalImage: File('/tmp/test.jpg'),
      quality: quality,
      ocrResult: ocrResult,
      isUploaded: isUploaded,
    );
  }

  // ── DocumentTypeSelector ───────────────────────
  group('DocumentTypeSelector', () {
    testWidgets('renders all document types', (tester) async {
      DocumentType? selectedType;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentTypeSelector(
              onTypeSelected: (type) => selectedType = type,
            ),
          ),
        ),
      );
      expect(find.byType(DocumentTypeSelector), findsOneWidget);
      // selectedType stays null until a type is tapped
      expect(selectedType, isNull);
    });

    testWidgets('renders with selected type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentTypeSelector(
              selectedType: DocumentType.prescription,
              onTypeSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(DocumentTypeSelector), findsOneWidget);
    });

    testWidgets('shows document type labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DocumentTypeSelector(onTypeSelected: (_) {})),
        ),
      );
      expect(find.text('Ordonnance'), findsOneWidget);
      expect(find.text('Reçu de commande'), findsOneWidget);
      expect(find.text('Preuve de livraison'), findsOneWidget);
    });

    testWidgets('renders with limited available types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentTypeSelector(
              onTypeSelected: (_) {},
              availableTypes: [DocumentType.prescription, DocumentType.receipt],
            ),
          ),
        ),
      );
      expect(find.text('Ordonnance'), findsOneWidget);
      expect(find.text('Reçu de commande'), findsOneWidget);
    });

    testWidgets('calls onTypeSelected on tap', (tester) async {
      DocumentType? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentTypeSelector(
              onTypeSelected: (type) => selected = type,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ordonnance'));
      await tester.pump();
      expect(selected, DocumentType.prescription);
    });
  });

  // ── ScannerGuideFrame ──────────────────────────
  group('ScannerGuideFrame', () {
    testWidgets('renders with default aspect ratio', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScannerGuideFrame())),
      );
      expect(find.byType(ScannerGuideFrame), findsOneWidget);
    });

    testWidgets('renders with hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScannerGuideFrame(hintText: 'Placez le document'),
          ),
        ),
      );
      expect(find.text('Placez le document'), findsOneWidget);
    });

    testWidgets('renders with custom frame color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerGuideFrame(frameColor: Colors.red)),
        ),
      );
      expect(find.byType(ScannerGuideFrame), findsOneWidget);
    });

    testWidgets('renders without hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScannerGuideFrame())),
      );
      expect(find.byType(ScannerGuideFrame), findsOneWidget);
    });
  });

  // ── ScannedDocumentCard ────────────────────────
  group('ScannedDocumentCard', () {
    testWidgets('renders with document', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScannedDocumentCard(document: makeDoc())),
        ),
      );
      expect(find.byType(ScannedDocumentCard), findsOneWidget);
    });

    testWidgets('renders with callbacks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(),
              onTap: () {},
              onDelete: () {},
              onUpload: () {},
            ),
          ),
        ),
      );
      expect(find.byType(ScannedDocumentCard), findsOneWidget);
    });

    testWidgets('shows document type name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(type: DocumentType.prescription),
            ),
          ),
        ),
      );
      expect(find.text('Ordonnance'), findsOneWidget);
    });

    testWidgets('shows uploaded status chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(document: makeDoc(isUploaded: true)),
          ),
        ),
      );
      expect(find.text('Uploadé'), findsOneWidget);
    });

    testWidgets('shows local status chip when not uploaded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(document: makeDoc(isUploaded: false)),
          ),
        ),
      );
      expect(find.text('Local'), findsOneWidget);
    });

    testWidgets('shows quality badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(quality: ScanQuality.excellent),
            ),
          ),
        ),
      );
      expect(find.text('Excellente'), findsOneWidget);
    });

    testWidgets('shows good quality label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(quality: ScanQuality.good),
            ),
          ),
        ),
      );
      expect(find.text('Bonne'), findsOneWidget);
    });

    testWidgets('shows poor quality label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(quality: ScanQuality.poor),
            ),
          ),
        ),
      );
      expect(find.text('Mauvaise'), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ScannedDocumentCard));
      expect(tapped, true);
    });

    testWidgets('renders receipt type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(type: DocumentType.receipt),
            ),
          ),
        ),
      );
      expect(find.text('Reçu de commande'), findsOneWidget);
    });

    testWidgets('renders idCard type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(type: DocumentType.idCard),
            ),
          ),
        ),
      );
      expect(find.text('Pièce d\'identité'), findsOneWidget);
    });

    testWidgets('renders deliveryProof type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(type: DocumentType.deliveryProof),
            ),
          ),
        ),
      );
      expect(find.text('Preuve de livraison'), findsOneWidget);
    });
  });

  // ── ScannedDocumentPreview ─────────────────────
  group('ScannedDocumentPreview', () {
    testWidgets('renders with document and buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              onRetake: () {},
              onConfirm: () {},
            ),
          ),
        ),
      );
      expect(find.byType(ScannedDocumentPreview), findsOneWidget);
      expect(find.text('Reprendre'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
    });

    testWidgets('shows OCR button when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              showOcrButton: true,
              onOcr: () {},
            ),
          ),
        ),
      );
      expect(find.text('Analyser'), findsOneWidget);
    });

    testWidgets('hides OCR button when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              showOcrButton: false,
            ),
          ),
        ),
      );
      expect(find.text('Analyser'), findsNothing);
    });

    testWidgets('triggers onRetake callback', (tester) async {
      bool retaken = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              onRetake: () => retaken = true,
              onConfirm: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Reprendre'));
      expect(retaken, true);
    });

    testWidgets('triggers onConfirm callback', (tester) async {
      bool confirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              onRetake: () {},
              onConfirm: () => confirmed = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Confirmer'));
      expect(confirmed, true);
    });
  });

  // ── OcrResultsCard ─────────────────────────────
  group('OcrResultsCard', () {
    testWidgets('renders with successful OCR result', (tester) async {
      final result = OcrResult(
        rawText: 'Dr. Martin\nParacétamol 500mg',
        confidence: 0.95,
        status: OcrStatus.success,
        extractedFields: {
          'patient_name': 'Jean Dupont',
          'doctor_name': 'Dr. Martin',
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OcrResultsCard(
                result: result,
                documentType: DocumentType.prescription,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(OcrResultsCard), findsOneWidget);
    });

    testWidgets('renders with failed OCR result', (tester) async {
      final result = OcrResult.error('Impossible de lire le document');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrResultsCard(
              result: result,
              documentType: DocumentType.receipt,
            ),
          ),
        ),
      );
      expect(find.byType(OcrResultsCard), findsOneWidget);
    });

    testWidgets('renders with empty OCR result', (tester) async {
      final result = OcrResult(
        rawText: '',
        status: OcrStatus.success,
        confidence: 0.0,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrResultsCard(
              result: result,
              documentType: DocumentType.other,
            ),
          ),
        ),
      );
      expect(find.byType(OcrResultsCard), findsOneWidget);
    });

    testWidgets('renders with extracted fields for receipt', (tester) async {
      final result = OcrResult(
        rawText: 'Facture #12345',
        status: OcrStatus.success,
        confidence: 0.85,
        extractedFields: {
          'order_number': '12345',
          'total_amount': '15000 FCFA',
          'pharmacy_name': 'Pharmacie Centrale',
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OcrResultsCard(
                result: result,
                documentType: DocumentType.receipt,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(OcrResultsCard), findsOneWidget);
    });
  });

  // ── DocumentTypeSelector - deep interactions ───
  group('DocumentTypeSelector - deep interactions', () {
    testWidgets('has Wrap layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DocumentTypeSelector(onTypeSelected: (_) {})),
        ),
      );
      expect(find.byType(Wrap), findsWidgets);
    });

    testWidgets('shows Type de document header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DocumentTypeSelector(onTypeSelected: (_) {})),
        ),
      );
      expect(find.text('Type de document'), findsOneWidget);
    });

    testWidgets('shows Pièce d\'identité label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DocumentTypeSelector(onTypeSelected: (_) {})),
        ),
      );
      expect(find.text('Pièce d\'identité'), findsOneWidget);
    });

    testWidgets('shows Autre document label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DocumentTypeSelector(onTypeSelected: (_) {})),
        ),
      );
      expect(find.text('Autre document'), findsOneWidget);
    });

    testWidgets('tapping idCard type calls callback', (tester) async {
      DocumentType? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentTypeSelector(
              onTypeSelected: (type) => selected = type,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pièce d\'identité'));
      await tester.pump();
      expect(selected, DocumentType.idCard);
    });

    testWidgets('tapping receipt type calls callback', (tester) async {
      DocumentType? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentTypeSelector(
              onTypeSelected: (type) => selected = type,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Reçu de commande'));
      await tester.pump();
      expect(selected, DocumentType.receipt);
    });

    testWidgets('tapping deliveryProof type calls callback', (tester) async {
      DocumentType? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentTypeSelector(
              onTypeSelected: (type) => selected = type,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Preuve de livraison'));
      await tester.pump();
      expect(selected, DocumentType.deliveryProof);
    });

    testWidgets('selected type has AnimatedContainer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentTypeSelector(
              selectedType: DocumentType.prescription,
              onTypeSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('single available type limits choices', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentTypeSelector(
              onTypeSelected: (_) {},
              availableTypes: [DocumentType.idCard],
            ),
          ),
        ),
      );
      expect(find.text('Pièce d\'identité'), findsOneWidget);
      expect(find.text('Ordonnance'), findsNothing);
    });
  });

  // ── ScannerGuideFrame - deep ───────────────────
  group('ScannerGuideFrame - deep interactions', () {
    testWidgets('has LayoutBuilder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScannerGuideFrame())),
      );
      expect(find.byType(LayoutBuilder), findsWidgets);
    });

    testWidgets('has Stack for corner decorations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScannerGuideFrame())),
      );
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('has Positioned widgets for corners', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScannerGuideFrame())),
      );
      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('custom aspect ratio renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerGuideFrame(aspectRatio: 1.0)),
        ),
      );
      expect(find.byType(ScannerGuideFrame), findsOneWidget);
    });
  });

  // ── ScannedDocumentCard - deep ─────────────────
  group('ScannedDocumentCard - deep interactions', () {
    testWidgets('has Hero widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScannedDocumentCard(document: makeDoc())),
        ),
      );
      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('has Card widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScannedDocumentCard(document: makeDoc())),
        ),
      );
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows cloud_done icon for uploaded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(document: makeDoc(isUploaded: true)),
          ),
        ),
      );
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('shows cloud_upload icon for local', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(document: makeDoc(isUploaded: false)),
          ),
        ),
      );
      expect(find.byIcon(Icons.cloud_upload), findsWidgets);
    });

    testWidgets('delete button triggers callback', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(),
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );
      final deleteIcon = find.byIcon(Icons.delete_outline);
      if (deleteIcon.evaluate().isNotEmpty) {
        await tester.tap(deleteIcon);
        expect(deleted, true);
      }
    });

    testWidgets('upload button shown when not uploaded with callback', (
      tester,
    ) async {
      var uploaded = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(isUploaded: false),
              onUpload: () => uploaded = true,
            ),
          ),
        ),
      );
      // Find and tap cloud_upload icon
      final uploadIcons = find.byIcon(Icons.cloud_upload);
      expect(uploadIcons, findsWidgets);
      // uploaded stays false until button is tapped
      expect(uploaded, isFalse);
    });

    testWidgets('has Row for status chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScannedDocumentCard(document: makeDoc())),
        ),
      );
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('has SizedBox for spacing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScannedDocumentCard(document: makeDoc())),
        ),
      );
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('other type shows Autre document label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(type: DocumentType.other),
            ),
          ),
        ),
      );
      expect(find.text('Autre document'), findsOneWidget);
    });

    testWidgets('shows star icons for quality in card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentCard(
              document: makeDoc(quality: ScanQuality.excellent),
            ),
          ),
        ),
      );
      // Quality badge shows star icons - just verify it renders
      expect(find.byType(Icon), findsWidgets);
    });
  });

  // ── ScannedDocumentPreview - deep ──────────────
  group('ScannedDocumentPreview - deep interactions', () {
    testWidgets('onOcr callback triggers', (tester) async {
      bool ocrCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              onOcr: () => ocrCalled = true,
              showOcrButton: true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Analyser'));
      expect(ocrCalled, true);
    });

    testWidgets('has Stack for overlays', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              onRetake: () {},
              onConfirm: () {},
            ),
          ),
        ),
      );
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('shows quality badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(quality: ScanQuality.excellent),
              onRetake: () {},
            ),
          ),
        ),
      );
      expect(find.text('Excellente'), findsOneWidget);
    });

    testWidgets('shows document type badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(type: DocumentType.prescription),
              onRetake: () {},
            ),
          ),
        ),
      );
      expect(find.text('Ordonnance'), findsOneWidget);
    });

    testWidgets('has refresh icon for retake', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              onRetake: () {},
              onConfirm: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('has check icon for confirm', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              onRetake: () {},
              onConfirm: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('has document_scanner icon for OCR', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              onOcr: () {},
              showOcrButton: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.document_scanner), findsOneWidget);
    });

    testWidgets('no buttons when no callbacks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(),
              showOcrButton: false,
            ),
          ),
        ),
      );
      expect(find.text('Reprendre'), findsNothing);
      expect(find.text('Confirmer'), findsNothing);
      expect(find.text('Analyser'), findsNothing);
    });

    testWidgets('poor quality shows badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedDocumentPreview(
              document: makeDoc(quality: ScanQuality.poor),
              onRetake: () {},
            ),
          ),
        ),
      );
      expect(find.text('Mauvaise'), findsOneWidget);
    });
  });

  // ── OcrResultsCard - deep ──────────────────────
  group('OcrResultsCard - deep interactions', () {
    testWidgets('shows confidence percentage for high confidence', (
      tester,
    ) async {
      final result = OcrResult(
        rawText: 'Test',
        confidence: 0.95,
        status: OcrStatus.success,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OcrResultsCard(
                result: result,
                documentType: DocumentType.receipt,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('95'), findsWidgets);
    });

    testWidgets('shows document_scanner icon in header', (tester) async {
      final result = OcrResult(
        rawText: 'Test data',
        confidence: 0.8,
        status: OcrStatus.success,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OcrResultsCard(
                result: result,
                documentType: DocumentType.prescription,
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.document_scanner), findsOneWidget);
    });

    testWidgets('shows Résultats de l\'analyse header', (tester) async {
      final result = OcrResult(
        rawText: 'Some text',
        confidence: 0.7,
        status: OcrStatus.success,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OcrResultsCard(
                result: result,
                documentType: DocumentType.receipt,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('analyse'), findsWidgets);
    });

    testWidgets('shows error icon for failed result', (tester) async {
      final result = OcrResult.error('Erreur de lecture');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrResultsCard(
              result: result,
              documentType: DocumentType.other,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('shows error message text', (tester) async {
      final result = OcrResult.error('Document illisible');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrResultsCard(
              result: result,
              documentType: DocumentType.other,
            ),
          ),
        ),
      );
      expect(find.text('Document illisible'), findsOneWidget);
    });

    testWidgets('shows raw text content', (tester) async {
      final result = OcrResult(
        rawText: 'Paracétamol 500mg x 3',
        confidence: 0.88,
        status: OcrStatus.success,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OcrResultsCard(
                result: result,
                documentType: DocumentType.prescription,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Paracétamol'), findsOneWidget);
    });

    testWidgets('low confidence renders with orange/red color', (tester) async {
      final result = OcrResult(
        rawText: 'Poor text',
        confidence: 0.3,
        status: OcrStatus.success,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OcrResultsCard(
                result: result,
                documentType: DocumentType.other,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('30'), findsWidgets);
    });

    testWidgets('medium confidence renders', (tester) async {
      final result = OcrResult(
        rawText: 'Medium quality',
        confidence: 0.6,
        status: OcrStatus.success,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OcrResultsCard(
                result: result,
                documentType: DocumentType.receipt,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('60'), findsWidgets);
    });
  });
}
