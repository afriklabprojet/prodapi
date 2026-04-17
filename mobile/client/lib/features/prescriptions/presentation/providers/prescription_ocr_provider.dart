import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../../products/domain/entities/product_entity.dart';

/// État pour le scanner OCR d'ordonnance
class PrescriptionOcrState {
  final bool isLoading;
  final String? error;
  final List<ExtractedMedication> matchedProducts;
  final List<String> unmatchedMedications;
  final double confidence;
  final String? rawText;

  const PrescriptionOcrState({
    this.isLoading = false,
    this.error,
    this.matchedProducts = const [],
    this.unmatchedMedications = const [],
    this.confidence = 0,
    this.rawText,
  });

  bool get hasResults =>
      matchedProducts.isNotEmpty || unmatchedMedications.isNotEmpty;

  PrescriptionOcrState copyWith({
    bool? isLoading,
    String? error,
    List<ExtractedMedication>? matchedProducts,
    List<String>? unmatchedMedications,
    double? confidence,
    String? rawText,
  }) {
    return PrescriptionOcrState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      matchedProducts: matchedProducts ?? this.matchedProducts,
      unmatchedMedications: unmatchedMedications ?? this.unmatchedMedications,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
    );
  }
}

/// Médicament extrait de l'ordonnance
class ExtractedMedication {
  final String name;
  final String? dosage;
  final String? frequency;
  final int? quantity;
  final double confidence;
  final int? productId;
  final ProductEntity? product;

  const ExtractedMedication({
    required this.name,
    this.dosage,
    this.frequency,
    this.quantity,
    this.confidence = 0,
    this.productId,
    this.product,
  });

  factory ExtractedMedication.fromJson(Map<String, dynamic> json) {
    return ExtractedMedication(
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      quantity: json['quantity'] as int?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      productId: json['product_id'] as int?,
    );
  }
}

/// Provider pour l'OCR d'ordonnance
final prescriptionOcrProvider =
    StateNotifierProvider<PrescriptionOcrNotifier, PrescriptionOcrState>((ref) {
  return PrescriptionOcrNotifier(ref);
});

class PrescriptionOcrNotifier extends StateNotifier<PrescriptionOcrState> {
  final Ref _ref;

  PrescriptionOcrNotifier(this._ref) : super(const PrescriptionOcrState());

  /// Analyse une image d'ordonnance et extrait les médicaments
  Future<void> analyzeImage(File imageFile) async {
    state = const PrescriptionOcrState(isLoading: true);

    try {
      final response = await _ref.read(apiClientProvider).post(
        '/prescriptions/ocr',
        data: await _buildMultipartData(imageFile),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Parse matched products
        final matchedRaw = data['matched_products'] as List<dynamic>? ?? [];
        final matched = <ExtractedMedication>[];
        
        for (final item in matchedRaw) {
          if (item is Map<String, dynamic>) {
            var med = ExtractedMedication.fromJson(item);
            
            // Load product details if productId is available
            if (med.productId != null) {
              final productResult = await _ref
                  .read(productsRepositoryProvider)
                  .getProductDetails(med.productId!);
              
              productResult.fold(
                (failure) {
                  // Keep without product details
                  matched.add(med);
                },
                (product) {
                  matched.add(ExtractedMedication(
                    name: med.name,
                    dosage: med.dosage,
                    frequency: med.frequency,
                    quantity: med.quantity,
                    confidence: med.confidence,
                    productId: med.productId,
                    product: product,
                  ));
                },
              );
            } else {
              matched.add(med);
            }
          }
        }

        // Parse unmatched medications
        final unmatchedRaw = data['unmatched_medications'] as List<dynamic>? ?? [];
        final unmatched = unmatchedRaw
            .map((e) => e is String ? e : (e as Map<String, dynamic>)['name'] as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList();

        state = PrescriptionOcrState(
          isLoading: false,
          matchedProducts: matched,
          unmatchedMedications: unmatched,
          confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
          rawText: data['raw_text'] as String?,
        );

        AppLogger.info(
          'OCR completed: ${matched.length} matched, ${unmatched.length} unmatched, '
          'confidence: ${state.confidence}%',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Erreur lors de l\'analyse de l\'ordonnance',
        );
      }
    } catch (e) {
      AppLogger.error('OCR analysis failed', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'analyse. Vérifiez votre connexion.',
      );
    }
  }

  /// Construit les données multipart pour l'upload
  Future<FormData> _buildMultipartData(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final filename = imageFile.path.split('/').last;
    
    return FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
    });
  }

  /// Clear les résultats
  void clear() {
    state = const PrescriptionOcrState();
  }
}
