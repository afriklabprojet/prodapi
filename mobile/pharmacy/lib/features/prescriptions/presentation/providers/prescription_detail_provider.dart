import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/prescription_model.dart';
import '../../data/datasources/prescription_remote_datasource.dart';
import '../../../auth/presentation/providers/auth_di_providers.dart';
import '../providers/prescription_provider.dart';

/// Provider dédié pour la logique de détail d'une ordonnance.
/// Gère: chargement token, duplicate check, OCR, dispensation, mise à jour statut.
final prescriptionDetailProvider = StateNotifierProvider.autoDispose
    .family<PrescriptionDetailNotifier, PrescriptionDetailState, PrescriptionModel>(
  (ref, prescription) {
    return PrescriptionDetailNotifier(ref, prescription);
  },
);

class PrescriptionDetailState {
  final PrescriptionModel prescription;
  final String? authToken;
  final DuplicateInfo? duplicateInfo;
  final AnalysisResult? analysisResult;
  final String? ocrError;
  final bool isAnalyzing;
  final bool isDispensing;
  final bool isLoading;
  final Map<String, bool> selectedMedications;

  const PrescriptionDetailState({
    required this.prescription,
    this.authToken,
    this.duplicateInfo,
    this.analysisResult,
    this.ocrError,
    this.isAnalyzing = false,
    this.isDispensing = false,
    this.isLoading = false,
    this.selectedMedications = const {},
  });

  PrescriptionDetailState copyWith({
    PrescriptionModel? prescription,
    String? authToken,
    DuplicateInfo? duplicateInfo,
    AnalysisResult? analysisResult,
    String? ocrError,
    bool? clearOcrError,
    bool? isAnalyzing,
    bool? isDispensing,
    bool? isLoading,
    Map<String, bool>? selectedMedications,
  }) {
    return PrescriptionDetailState(
      prescription: prescription ?? this.prescription,
      authToken: authToken ?? this.authToken,
      duplicateInfo: duplicateInfo ?? this.duplicateInfo,
      analysisResult: analysisResult ?? this.analysisResult,
      ocrError: clearOcrError == true ? null : (ocrError ?? this.ocrError),
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isDispensing: isDispensing ?? this.isDispensing,
      isLoading: isLoading ?? this.isLoading,
      selectedMedications: selectedMedications ?? this.selectedMedications,
    );
  }
}

class PrescriptionDetailNotifier extends StateNotifier<PrescriptionDetailState> {
  final Ref _ref;

  PrescriptionDetailNotifier(this._ref, PrescriptionModel prescription)
      : super(PrescriptionDetailState(prescription: prescription)) {
    _init();
  }

  Future<void> _init() async {
    await _loadAuthToken();
    await _loadDuplicateInfo();
  }

  Future<void> _loadAuthToken() async {
    final token = await _ref.read(authLocalDataSourceProvider).getToken();
    if (mounted) {
      state = state.copyWith(authToken: token);
    }
  }

  Future<void> _loadDuplicateInfo() async {
    final result = await _ref.read(prescriptionListProvider.notifier)
        .getPrescriptionWithDuplicate(state.prescription.id);
    if (mounted && result != null) {
      state = state.copyWith(
        prescription: result.prescription,
        duplicateInfo: result.duplicateInfo,
      );
    }
  }

  Future<bool> analyzePrescription() async {
    state = state.copyWith(isAnalyzing: true, clearOcrError: true);
    try {
      final result = await _ref.read(prescriptionListProvider.notifier)
          .analyzePrescription(state.prescription.id);
      if (!mounted) return false;
      if (result != null) {
        state = state.copyWith(
          analysisResult: result,
          prescription: result.prescription,
          isAnalyzing: false,
        );
        return true;
      } else {
        final errorMsg = _ref.read(prescriptionListProvider).analysisError;
        state = state.copyWith(
          ocrError: errorMsg ?? 'Échec de l\'analyse OCR',
          isAnalyzing: false,
        );
        return false;
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          ocrError: 'Erreur d\'analyse: $e',
          isAnalyzing: false,
        );
      }
      return false;
    }
  }

  Future<DispenseResult?> dispenseMedications(List<Map<String, dynamic>> medications) async {
    state = state.copyWith(isDispensing: true);
    try {
      final result = await _ref.read(prescriptionListProvider.notifier)
          .dispensePrescription(state.prescription.id, medications);
      if (mounted && result != null) {
        state = state.copyWith(
          prescription: result.prescription,
          selectedMedications: {},
          isDispensing: false,
        );
        return result;
      }
      if (mounted) state = state.copyWith(isDispensing: false);
      return null;
    } catch (e) {
      if (mounted) state = state.copyWith(isDispensing: false);
      rethrow;
    }
  }

  Future<bool> updateStatus(String status, {String? notes}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(prescriptionListProvider.notifier).updateStatus(
        state.prescription.id,
        status,
        notes: notes,
      );
      if (mounted) state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> sendQuote(double amount, {String? notes}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(prescriptionListProvider.notifier).sendQuote(
        state.prescription.id,
        amount,
        notes: notes,
      );
      if (mounted) state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false);
      return false;
    }
  }

  void toggleMedication(String name, bool value) {
    final updated = Map<String, bool>.from(state.selectedMedications);
    updated[name] = value;
    state = state.copyWith(selectedMedications: updated);
  }

  List<Map<String, dynamic>> buildMedicationsPayload(List<String> selectedNames) {
    final medications = <Map<String, dynamic>>[];
    final matched = state.analysisResult?.matchedProducts ?? state.prescription.matchedProducts ?? [];
    final extracted = state.analysisResult?.extractedMedications ?? state.prescription.extractedMedications ?? [];

    for (final name in selectedNames) {
      int? productId;
      int qtyPrescribed = 1;

      for (final m in matched) {
        if (m is Map) {
          final medName = m['medication'] ?? m['product_name'] ?? '';
          if (medName == name) {
            productId = (m['product_id'] as num?)?.toInt();
            break;
          }
        }
      }

      for (final e in extracted) {
        if (e is Map) {
          final medName = e['name'] ?? e['matched_text'] ?? '';
          if (medName == name) {
            qtyPrescribed = (e['quantity'] as num?)?.toInt() ?? 1;
            break;
          }
        }
      }

      final remaining = qtyPrescribed - state.prescription.getDispensedQuantity(name);
      if (remaining > 0) {
        medications.add({
          'medication_name': name,
          'product_id': productId,
          'quantity_prescribed': qtyPrescribed,
          'quantity_dispensed': remaining,
        });
      }
    }
    return medications;
  }
}
