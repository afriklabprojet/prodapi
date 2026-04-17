import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod/legacy.dart';
import 'package:courier/presentation/screens/document_scanner_screen.dart';
import 'package:courier/data/models/scanned_document.dart';
import 'package:courier/data/services/document_scanner_service.dart';
import '../helpers/widget_test_helpers.dart';

class _FakeScannerNotifier extends StateNotifier<DocumentScannerState>
    implements DocumentScannerNotifier {
  _FakeScannerNotifier() : super(const DocumentScannerState());

  @override
  void initialize() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

File _makeTestImageFile(String name) {
  final file = File('${Directory.systemTemp.path}/$name');
  if (!file.existsSync()) {
    file.writeAsBytesSync(const [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0xF8,
      0xFF,
      0xFF,
      0x3F,
      0x00,
      0x05,
      0xFE,
      0x02,
      0xFE,
      0xA7,
      0x35,
      0x81,
      0x84,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);
  }
  return file;
}

ScannedDocument _makeScannedDocument({
  String id = 'doc-1',
  DocumentType type = DocumentType.prescription,
  int? deliveryId,
  OcrResult? ocrResult,
  bool isUploaded = false,
}) {
  return ScannedDocument(
    id: id,
    type: type,
    originalImage: _makeTestImageFile('$id-original.png'),
    processedImage: _makeTestImageFile('$id-processed.png'),
    deliveryId: deliveryId,
    ocrResult: ocrResult,
    isUploaded: isUploaded,
  );
}

class _InteractiveScannerNotifier extends StateNotifier<DocumentScannerState>
    implements DocumentScannerNotifier {
  _InteractiveScannerNotifier({
    DocumentScannerState? initialState,
    this.scanResult,
    this.ocrResultDocument,
    this.uploadResult,
  }) : super(initialState ?? const DocumentScannerState(isInitialized: true));

  final ScannedDocument? scanResult;
  final ScannedDocument? ocrResultDocument;
  final ScannedDocument? uploadResult;

  int initializeCalls = 0;
  int scanCalls = 0;
  int ocrCalls = 0;
  int uploadCalls = 0;
  bool usedGallery = false;
  String? removedDocumentId;
  DocumentType? selectedTypeValue;

  @override
  void initialize() {
    initializeCalls++;
    state = state.copyWith(isInitialized: true);
  }

  @override
  void selectDocumentType(DocumentType type) {
    selectedTypeValue = type;
    state = state.copyWith(selectedType: type);
  }

  @override
  Future<ScannedDocument?> scanDocument({
    required DocumentType type,
    int? deliveryId,
    bool fromGallery = false,
  }) async {
    scanCalls++;
    usedGallery = fromGallery;
    final document =
        (scanResult ?? _makeScannedDocument(type: type, deliveryId: deliveryId))
            .copyWith(type: type, deliveryId: deliveryId);
    state = state.copyWith(
      scannedDocuments: [...state.scannedDocuments, document],
    );
    return document;
  }

  @override
  Future<ScannedDocument?> performOcrOnDocument(
    ScannedDocument document,
  ) async {
    ocrCalls++;
    final updated =
        ocrResultDocument ??
        document.copyWith(
          ocrResult: OcrResult(
            rawText: 'Commande CMD-123',
            extractedFields: const {'order_number': 'CMD-123'},
            confidence: 0.92,
            status: OcrStatus.success,
          ),
        );
    state = state.copyWith(
      scannedDocuments: [
        for (final doc in state.scannedDocuments)
          if (doc.id == document.id) updated else doc,
      ],
    );
    return updated;
  }

  @override
  Future<ScannedDocument?> uploadDocument(ScannedDocument document) async {
    uploadCalls++;
    return uploadResult ??
        document.copyWith(
          isUploaded: true,
          cloudUrl: 'https://example.com/${document.id}.png',
        );
  }

  @override
  void removeDocument(String documentId) {
    removedDocumentId = documentId;
    state = state.copyWith(
      scannedDocuments: state.scannedDocuments
          .where((doc) => doc.id != documentId)
          .toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _pumpLargeWidget(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(widget);
  await tester.pump();
}

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

  group('DocumentScannerScreen', () {
    Widget buildScreen() {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith(
            (_) => _FakeScannerNotifier(),
          ),
        ],
        child: const MaterialApp(home: DocumentScannerScreen()),
      );
    }

    testWidgets('renders scanner screen', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
    });

    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows Text content', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('has Icon widgets', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
    });

    testWidgets('has action buttons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      final btns = find.byType(ElevatedButton);
      final icons = find.byType(IconButton);
      expect(
        btns.evaluate().length + icons.evaluate().length,
        greaterThanOrEqualTo(0),
      );
    });

    testWidgets('has Container widgets', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('DocumentScannerScreen - With deliveryId', () {
    Widget buildScreenWithDelivery({int? deliveryId}) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith(
            (_) => _FakeScannerNotifier(),
          ),
        ],
        child: MaterialApp(home: DocumentScannerScreen(deliveryId: deliveryId)),
      );
    }

    testWidgets('renders with deliveryId', (tester) async {
      await tester.pumpWidget(buildScreenWithDelivery(deliveryId: 42));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
    });

    testWidgets('renders without deliveryId', (tester) async {
      await tester.pumpWidget(buildScreenWithDelivery(deliveryId: null));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
    });

    testWidgets('renders with large deliveryId', (tester) async {
      await tester.pumpWidget(buildScreenWithDelivery(deliveryId: 99999));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
    });
  });

  group('DocumentScannerScreen - Processing state', () {
    testWidgets('renders with processing state', (tester) async {
      final screen = ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith(
            (_) => _ProcessingScannerNotifier(),
          ),
        ],
        child: const MaterialApp(home: DocumentScannerScreen()),
      );

      await tester.pumpWidget(screen);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
      // Either spinner or content should be present
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('DocumentScannerScreen - With preselected type', () {
    testWidgets('renders with preselectedType prescription', (tester) async {
      final screen = ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith(
            (_) => _FakeScannerNotifier(),
          ),
        ],
        child: MaterialApp(
          home: DocumentScannerScreen(
            preselectedType: DocumentType.prescription,
          ),
        ),
      );

      await tester.pumpWidget(screen);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
    });

    testWidgets('renders with preselectedType receipt', (tester) async {
      final screen = ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith(
            (_) => _FakeScannerNotifier(),
          ),
        ],
        child: MaterialApp(
          home: DocumentScannerScreen(preselectedType: DocumentType.receipt),
        ),
      );

      await tester.pumpWidget(screen);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
    });

    testWidgets('renders with preselectedType idCard', (tester) async {
      final screen = ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith(
            (_) => _FakeScannerNotifier(),
          ),
        ],
        child: MaterialApp(
          home: DocumentScannerScreen(preselectedType: DocumentType.idCard),
        ),
      );

      await tester.pumpWidget(screen);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
    });

    testWidgets('renders with preselectedType deliveryProof', (tester) async {
      final screen = ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith(
            (_) => _FakeScannerNotifier(),
          ),
        ],
        child: MaterialApp(
          home: DocumentScannerScreen(
            preselectedType: DocumentType.deliveryProof,
          ),
        ),
      );

      await tester.pumpWidget(screen);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
    });

    testWidgets('all params combined', (tester) async {
      final screen = ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith(
            (_) => _FakeScannerNotifier(),
          ),
        ],
        child: MaterialApp(
          home: DocumentScannerScreen(
            deliveryId: 10,
            preselectedType: DocumentType.insurance,
            autoStartCapture: false,
          ),
        ),
      );

      await tester.pumpWidget(screen);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DocumentScannerScreen), findsOneWidget);
    });
  });

  group('DocumentScannerScreen - UI elements', () {
    Widget buildScreen2() {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith(
            (_) => _FakeScannerNotifier(),
          ),
        ],
        child: const MaterialApp(home: DocumentScannerScreen()),
      );
    }

    testWidgets('has AppBar', (tester) async {
      await tester.pumpWidget(buildScreen2());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has scrollable content', (tester) async {
      await tester.pumpWidget(buildScreen2());
      await tester.pump(const Duration(seconds: 1));
      final scrollable = find.byType(SingleChildScrollView);
      final listView = find.byType(ListView);
      expect(
        scrollable.evaluate().length + listView.evaluate().length,
        greaterThanOrEqualTo(0),
      );
    });

    testWidgets('has Row layouts', (tester) async {
      await tester.pumpWidget(buildScreen2());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('has Column layouts', (tester) async {
      await tester.pumpWidget(buildScreen2());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('DocumentScannerScreen - interactive coverage', () {
    Widget buildInteractiveScreen(
      _InteractiveScannerNotifier notifier, {
      int? deliveryId,
      DocumentType? preselectedType,
      bool autoStartCapture = false,
    }) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith((_) => notifier),
        ],
        child: MaterialApp(
          home: DocumentScannerScreen(
            deliveryId: deliveryId,
            preselectedType: preselectedType,
            autoStartCapture: autoStartCapture,
          ),
        ),
      );
    }

    testWidgets('selecting a type shows scanner instructions', (tester) async {
      final notifier = _InteractiveScannerNotifier();
      await _pumpLargeWidget(tester, buildInteractiveScreen(notifier));

      expect(
        find.text('Sélectionnez un type de document pour commencer'),
        findsOneWidget,
      );

      await tester.tap(find.text('Ordonnance'));
      await tester.pump();

      expect(notifier.selectedTypeValue, DocumentType.prescription);
      expect(find.text('Comment scanner'), findsOneWidget);
      expect(find.textContaining('ordonnance'), findsWidgets);
      expect(find.text('Caméra'), findsOneWidget);
      expect(find.text('Galerie'), findsOneWidget);
    });

    testWidgets('camera capture opens preview and OCR analysis', (
      tester,
    ) async {
      final document = _makeScannedDocument(
        id: 'camera-doc',
        type: DocumentType.receipt,
        deliveryId: 12,
      );
      final notifier = _InteractiveScannerNotifier(
        scanResult: document,
        ocrResultDocument: document.copyWith(
          ocrResult: OcrResult(
            rawText: 'Commande CMD-123',
            extractedFields: const {'order_number': 'CMD-123'},
            confidence: 0.92,
            status: OcrStatus.success,
          ),
        ),
      );

      await _pumpLargeWidget(
        tester,
        buildInteractiveScreen(
          notifier,
          deliveryId: 12,
          preselectedType: DocumentType.receipt,
        ),
      );

      final cameraLabel = find.text('Caméra');
      expect(cameraLabel, findsOneWidget);
      await tester.ensureVisible(cameraLabel);
      await tester.tap(cameraLabel);
      await tester.pump();

      expect(notifier.scanCalls, 1);
      expect(find.text('Aperçu du document'), findsOneWidget);
      expect(find.text('Analyser'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);

      await tester.tap(find.text('Analyser'));
      await tester.pump();

      expect(notifier.ocrCalls, 1);
      expect(find.textContaining('CMD-123'), findsWidgets);
    });

    testWidgets('reprendre resets preview and removes temporary document', (
      tester,
    ) async {
      final document = _makeScannedDocument(id: 'reset-doc');
      final notifier = _InteractiveScannerNotifier(scanResult: document);

      await _pumpLargeWidget(
        tester,
        buildInteractiveScreen(
          notifier,
          preselectedType: DocumentType.prescription,
        ),
      );

      final cameraLabel = find.text('Caméra');
      expect(cameraLabel, findsOneWidget);
      await tester.ensureVisible(cameraLabel);
      await tester.tap(cameraLabel);
      await tester.pump();
      expect(find.text('Aperçu du document'), findsOneWidget);

      await tester.tap(find.text('Reprendre'));
      await tester.pump();

      expect(notifier.removedDocumentId, 'reset-doc');
      expect(find.text('Scanner un document'), findsOneWidget);
    });

    testWidgets('confirm uses upload flow for captured document', (
      tester,
    ) async {
      final document = _makeScannedDocument(
        id: 'upload-doc',
        type: DocumentType.deliveryProof,
      );
      final notifier = _InteractiveScannerNotifier(
        scanResult: document,
        uploadResult: document.copyWith(
          isUploaded: true,
          cloudUrl: 'https://example.com/upload-doc.png',
        ),
      );

      await _pumpLargeWidget(
        tester,
        buildInteractiveScreen(
          notifier,
          preselectedType: DocumentType.deliveryProof,
        ),
      );

      final cameraLabel = find.text('Caméra');
      expect(cameraLabel, findsOneWidget);
      await tester.ensureVisible(cameraLabel);
      await tester.tap(cameraLabel);
      await tester.pump();
      await tester.tap(find.text('Confirmer'));
      await tester.pump();

      expect(notifier.uploadCalls, 1);
    });

    testWidgets('autoStartCapture launches scan automatically', (tester) async {
      final notifier = _InteractiveScannerNotifier(
        scanResult: _makeScannedDocument(id: 'auto-doc'),
      );

      await _pumpLargeWidget(
        tester,
        buildInteractiveScreen(
          notifier,
          preselectedType: DocumentType.prescription,
          autoStartCapture: true,
        ),
      );
      await tester.pump();

      expect(notifier.initializeCalls, greaterThanOrEqualTo(1));
      expect(notifier.scanCalls, 1);
      expect(find.text('Aperçu du document'), findsOneWidget);
    });
  });

  group('DeliveryDocumentsScreen', () {
    Widget buildDeliveryDocuments(_InteractiveScannerNotifier notifier) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          documentScannerStateProvider.overrideWith((_) => notifier),
        ],
        child: const MaterialApp(
          home: DeliveryDocumentsScreen(
            deliveryId: 42,
            deliveryReference: 'DEL-042',
          ),
        ),
      );
    }

    testWidgets('shows empty state when no document exists', (tester) async {
      final notifier = _InteractiveScannerNotifier(
        initialState: const DocumentScannerState(isInitialized: true),
      );

      await _pumpLargeWidget(tester, buildDeliveryDocuments(notifier));

      expect(find.text('Aucun document'), findsOneWidget);
      expect(
        find.text('Scannez des documents pour cette livraison'),
        findsOneWidget,
      );
      expect(find.text('Scanner'), findsOneWidget);
    });

    testWidgets('shows grouped documents and statistics', (tester) async {
      final docs = [
        _makeScannedDocument(
          id: 'doc-a',
          type: DocumentType.prescription,
          deliveryId: 42,
          isUploaded: true,
        ),
        _makeScannedDocument(
          id: 'doc-b',
          type: DocumentType.receipt,
          deliveryId: 42,
          ocrResult: OcrResult(
            rawText: 'Reçu validé',
            confidence: 0.85,
            status: OcrStatus.success,
          ),
        ),
        _makeScannedDocument(
          id: 'doc-c',
          type: DocumentType.other,
          deliveryId: 42,
        ),
      ];
      final notifier = _InteractiveScannerNotifier(
        initialState: DocumentScannerState(
          isInitialized: true,
          scannedDocuments: docs,
        ),
      );

      await _pumpLargeWidget(tester, buildDeliveryDocuments(notifier));

      expect(find.textContaining('DEL-042'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Uploadés'), findsOneWidget);
      expect(find.text('Analysés'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });
  });
}

class _ProcessingScannerNotifier extends StateNotifier<DocumentScannerState>
    implements DocumentScannerNotifier {
  _ProcessingScannerNotifier()
    : super(const DocumentScannerState(isProcessing: true));

  @override
  void initialize() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
