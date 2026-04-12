import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dio/dio.dart';

import '../models/scanned_document.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/config/app_config.dart';

/// Provider pour le service de scanner
final documentScannerServiceProvider = Provider<DocumentScannerService>((ref) {
  return DocumentScannerService(ref.read(dioProvider));
});

/// Provider pour l'état du scanner
final documentScannerStateProvider =
    StateNotifierProvider<DocumentScannerNotifier, DocumentScannerState>((ref) {
      return DocumentScannerNotifier(ref.read(documentScannerServiceProvider));
    });

/// Provider pour les documents d'une livraison
final deliveryDocumentsProvider =
    FutureProvider.family<List<ScannedDocument>, int>((ref, deliveryId) async {
      final service = ref.read(documentScannerServiceProvider);
      return service.getDocumentsForDelivery(deliveryId);
    });

/// Service pour le scanner de documents
class DocumentScannerService {
  final Dio _dio;
  final ImagePicker _picker;
  final FirebaseStorage? _storage;

  // Cache local des documents scannés
  final Map<int, List<ScannedDocument>> _documentsCache = {};

  DocumentScannerService(
    this._dio, {
    ImagePicker? picker,
    FirebaseStorage? storage,
  }) : _picker = picker ?? ImagePicker(),
       _storage = storage;

  /// Capture un document depuis la caméra avec guidage
  Future<File?> captureDocument({
    CameraDevice preferredCamera = CameraDevice.rear,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: AppConfig.documentMaxWidth.toDouble(),
        maxHeight: AppConfig.documentMaxHeight.toDouble(),
        imageQuality: AppConfig.documentImageQuality,
        preferredCameraDevice: preferredCamera,
      );

      if (image != null) {
        if (kDebugMode) {
          debugPrint('📄 [Scanner] Document capturé: ${image.path}');
        }
        return File(image.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Scanner] Erreur capture: $e');
      rethrow;
    }
  }

  /// Sélectionne un document depuis la galerie
  Future<File?> selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: AppConfig.documentMaxWidth.toDouble(),
        maxHeight: AppConfig.documentMaxHeight.toDouble(),
        imageQuality: AppConfig.documentImageQuality,
      );

      if (image != null) {
        if (kDebugMode) {
          debugPrint('📄 [Scanner] Document sélectionné: ${image.path}');
        }
        return File(image.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Scanner] Erreur galerie: $e');
      rethrow;
    }
  }

  /// Capture plusieurs documents en rafale
  Future<List<File>> captureMultipleDocuments({int maxCount = 5}) async {
    final documents = <File>[];

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: AppConfig.documentMaxWidth.toDouble(),
        maxHeight: AppConfig.documentMaxHeight.toDouble(),
        imageQuality: AppConfig.documentImageQuality,
        limit: maxCount,
      );

      for (final image in images) {
        documents.add(File(image.path));
      }

      if (kDebugMode) {
        debugPrint('📄 [Scanner] ${documents.length} documents sélectionnés');
      }
      return documents;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Scanner] Erreur multi-sélection: $e');
      rethrow;
    }
  }

  /// Analyse la qualité du scan
  Future<ScanQuality> analyzeQuality(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = await decodeImageFromList(bytes);

      // Calcul du score basé sur la résolution
      final pixels = image.width * image.height;
      final resolutionScore = math.min(
        1.0,
        pixels / AppConfig.qualityBenchmarkPixels,
      );

      // Calcul basé sur la taille du fichier (netteté indirecte)
      final fileSize = await imageFile.length();
      final sizeScore = math.min(1.0, fileSize / 500000); // 500KB = bon score

      // Score final pondéré
      final totalScore =
          (resolutionScore * AppConfig.qualityWeightResolution) +
          (sizeScore * AppConfig.qualityWeightSize);

      return ScanQuality.fromScore(totalScore);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Scanner] Erreur analyse qualité: $e');
      return ScanQuality.fair;
    }
  }

  /// Traite l'image avec amélioration automatique
  Future<File?> processImage(File originalImage) async {
    try {
      final bytes = await originalImage.readAsBytes();

      // Décodage de l'image
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Création du recorder pour les modifications
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Application des améliorations
      final paint = Paint()..filterQuality = FilterQuality.high;

      // Augmentation légère du contraste via ColorFilter
      paint.colorFilter = const ColorFilter.matrix(<double>[
        1.2, 0, 0, 0, -20, // Rouge : augmente contraste
        0, 1.2, 0, 0, -20, // Vert
        0, 0, 1.2, 0, -20, // Bleu
        0, 0, 0, 1, 0, // Alpha
      ]);

      // Dessin de l'image améliorée
      canvas.drawImage(image, Offset.zero, paint);

      final picture = recorder.endRecording();
      final processedImage = await picture.toImage(image.width, image.height);

      // Encodage en PNG
      final byteData = await processedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;

      // Sauvegarde dans un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final processedFile = File('${tempDir.path}/processed_$timestamp.png');
      await processedFile.writeAsBytes(byteData.buffer.asUint8List());

      if (kDebugMode) {
        debugPrint('✅ [Scanner] Image traitée: ${processedFile.path}');
      }
      return processedFile;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Scanner] Erreur traitement: $e');
      return null;
    }
  }

  /// Effectue l'OCR sur le document (via API backend)
  Future<OcrResult> performOcr(File imageFile, DocumentType type) async {
    try {
      if (kDebugMode) debugPrint('🔍 [Scanner] Début OCR pour ${type.label}');

      // Préparation du fichier pour l'upload
      final fileName = 'ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        'document_type': type.name,
      });

      // Appel API OCR
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/ocr/analyze',
        data: formData,
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return OcrResult(
          rawText: data['raw_text'] ?? '',
          extractedFields: Map<String, String>.from(data['fields'] ?? {}),
          confidence: (data['confidence'] ?? 0.0).toDouble(),
          status: OcrStatus.success,
        );
      }

      return OcrResult.error('Réponse invalide du serveur');
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ [Scanner] Erreur OCR API: ${e.message}');

      // Fallback: extraction locale basique basée sur le type
      return _performLocalOcr(imageFile, type);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Scanner] Erreur OCR: $e');
      return OcrResult.error(e.toString());
    }
  }

  /// OCR local de fallback (extraction basique)
  Future<OcrResult> _performLocalOcr(File imageFile, DocumentType type) async {
    // Simulation d'extraction basique selon le type
    final extractedFields = <String, String>{};

    switch (type) {
      case DocumentType.prescription:
        extractedFields['document_type'] = 'Ordonnance';
        extractedFields['status'] = 'Document scanné';
        break;

      case DocumentType.receipt:
        extractedFields['document_type'] = 'Reçu';
        extractedFields['status'] = 'Document scanné';
        break;

      case DocumentType.deliveryProof:
        extractedFields['document_type'] = 'Preuve de livraison';
        extractedFields['timestamp'] = DateTime.now().toIso8601String();
        break;

      default:
        extractedFields['document_type'] = type.label;
        extractedFields['status'] = 'Non analysé';
    }

    return OcrResult(
      rawText: '',
      extractedFields: extractedFields,
      confidence: 0.5,
      status: OcrStatus.success,
    );
  }

  /// Upload le document vers Firebase Storage
  /// SÉCURITÉ: Supprime automatiquement les fichiers locaux après upload réussi
  Future<String?> uploadDocument(ScannedDocument document) async {
    try {
      final file = document.displayImage;
      final fileName =
          'documents/${document.deliveryId ?? 'unknown'}/'
          '${document.id}_${document.type.name}.jpg';

      if (kDebugMode) debugPrint('📤 [Scanner] Upload: $fileName');

      final storage = _storage ?? FirebaseStorage.instance;
      final ref = storage.ref().child(fileName);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'document_type': document.type.name,
            'delivery_id': document.deliveryId?.toString() ?? '',
            'scanned_at': document.scannedAt.toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) debugPrint('✅ [Scanner] Uploadé: $downloadUrl');

      // SÉCURITÉ: Supprimer le fichier local après upload réussi
      // Protège les données KYC sensibles en cas de perte/vol du device
      await _cleanupLocalFile(file);

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Scanner] Erreur upload: $e');
      return null;
    }
  }

  /// SÉCURITÉ: Supprime un fichier local sensible (KYC, ordonnances)
  /// À appeler après chaque upload réussi pour éviter la persistance
  /// de données sensibles sur le device
  Future<void> _cleanupLocalFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          debugPrint('🗑️ [Scanner] Fichier local supprimé: ${file.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Scanner] Erreur suppression fichier: $e');
    }
  }

  /// SÉCURITÉ: Nettoie tous les fichiers temporaires de documents
  /// À appeler au démarrage de l'app ou périodiquement
  Future<void> cleanupAllTempDocuments() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      int deletedCount = 0;
      for (final entity in files) {
        if (entity is File &&
            (entity.path.contains('processed_') ||
                entity.path.contains('scanned_') ||
                entity.path.contains('ocr_'))) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (_) {}
        }
      }

      if (kDebugMode && deletedCount > 0) {
        debugPrint(
          '🗑️ [Scanner] Nettoyage: $deletedCount fichiers temporaires supprimés',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Scanner] Erreur nettoyage temp: $e');
    }
  }

  /// Enregistre le document via l'API
  Future<bool> saveToServer(ScannedDocument document, String cloudUrl) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/documents',
        data: {
          'delivery_id': document.deliveryId,
          'type': document.type.name,
          'url': cloudUrl,
          'quality': document.quality.name,
          'ocr_data': document.ocrResult?.toJson(),
          'notes': document.notes,
          'scanned_at': document.scannedAt.toIso8601String(),
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Scanner] Erreur sauvegarde: $e');
      return false;
    }
  }

  /// Récupère les documents d'une livraison
  Future<List<ScannedDocument>> getDocumentsForDelivery(int deliveryId) async {
    // Retourne depuis le cache si disponible
    if (_documentsCache.containsKey(deliveryId)) {
      return _documentsCache[deliveryId]!;
    }

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/api/deliveries/$deliveryId/documents',
      );

      if (response.statusCode == 200) {
        // Parser les documents (à implémenter selon la structure API)
        return [];
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Scanner] Erreur récupération: $e');
      return [];
    }
  }

  /// Ajoute un document au cache local
  void cacheDocument(int deliveryId, ScannedDocument document) {
    if (!_documentsCache.containsKey(deliveryId)) {
      _documentsCache[deliveryId] = [];
    }
    _documentsCache[deliveryId]!.add(document);
  }
}

/// Notifier pour l'état du scanner
class DocumentScannerNotifier extends StateNotifier<DocumentScannerState> {
  final DocumentScannerService _service;

  DocumentScannerNotifier(this._service) : super(const DocumentScannerState());

  /// Initialise le scanner
  void initialize() {
    state = state.copyWith(isInitialized: true);
  }

  /// Sélectionne le type de document
  void selectDocumentType(DocumentType type) {
    state = state.copyWith(selectedType: type);
  }

  /// Active/désactive le flash
  void toggleFlash() {
    state = state.copyWith(flashEnabled: !state.flashEnabled);
  }

  /// Scanne un document
  Future<ScannedDocument?> scanDocument({
    required DocumentType type,
    int? deliveryId,
    bool fromGallery = false,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Capture ou sélection du document
      final File? capturedFile = fromGallery
          ? await _service.selectFromGallery()
          : await _service.captureDocument();

      if (capturedFile == null) {
        state = state.copyWith(isProcessing: false);
        return null;
      }

      // Analyse de la qualité
      final quality = await _service.analyzeQuality(capturedFile);

      // Traitement de l'image
      final processedFile = await _service.processImage(capturedFile);

      // Création du document
      final document = ScannedDocument(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        originalImage: capturedFile,
        processedImage: processedFile,
        quality: quality,
        deliveryId: deliveryId,
      );

      // Ajoute à la liste
      final updatedDocs = [...state.scannedDocuments, document];
      state = state.copyWith(
        isProcessing: false,
        scannedDocuments: updatedDocs,
      );

      // Cache pour la livraison
      if (deliveryId != null) {
        _service.cacheDocument(deliveryId, document);
      }

      return document;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Erreur lors du scan. Veuillez réessayer.',
      );
      return null;
    }
  }

  /// Lance l'OCR sur un document
  Future<ScannedDocument?> performOcrOnDocument(
    ScannedDocument document,
  ) async {
    state = state.copyWith(isProcessing: true);

    try {
      final ocrResult = await _service.performOcr(
        document.displayImage,
        document.type,
      );

      final updatedDocument = document.copyWith(ocrResult: ocrResult);

      // Met à jour dans la liste
      final updatedDocs = state.scannedDocuments.map((d) {
        return d.id == document.id ? updatedDocument : d;
      }).toList();

      state = state.copyWith(
        isProcessing: false,
        scannedDocuments: updatedDocs,
      );

      return updatedDocument;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Erreur OCR. Veuillez réessayer.',
      );
      return null;
    }
  }

  /// Upload et sauvegarde un document
  Future<ScannedDocument?> uploadDocument(ScannedDocument document) async {
    state = state.copyWith(isProcessing: true);

    try {
      // Upload vers Firebase
      final cloudUrl = await _service.uploadDocument(document);

      if (cloudUrl == null) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Échec de l\'upload',
        );
        return null;
      }

      // Sauvegarde via API
      await _service.saveToServer(document, cloudUrl);

      // Met à jour le document
      final updatedDocument = document.copyWith(
        isUploaded: true,
        cloudUrl: cloudUrl,
      );

      // Met à jour dans la liste
      final updatedDocs = state.scannedDocuments.map((d) {
        return d.id == document.id ? updatedDocument : d;
      }).toList();

      state = state.copyWith(
        isProcessing: false,
        scannedDocuments: updatedDocs,
      );

      return updatedDocument;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Erreur upload. Veuillez réessayer.',
      );
      return null;
    }
  }

  /// Supprime un document de la liste
  void removeDocument(String documentId) {
    final updatedDocs = state.scannedDocuments
        .where((d) => d.id != documentId)
        .toList();
    state = state.copyWith(scannedDocuments: updatedDocs);
  }

  /// Efface l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Réinitialise le scanner
  void reset() {
    state = const DocumentScannerState(isInitialized: true);
  }
}

/// Extension pour OcrResult JSON
extension OcrResultJson on OcrResult {
  Map<String, dynamic> toJson() {
    return {
      'raw_text': rawText,
      'extracted_fields': extractedFields,
      'confidence': confidence,
      'status': status.name,
      'error_message': errorMessage,
      'processed_at': processedAt.toIso8601String(),
    };
  }
}
