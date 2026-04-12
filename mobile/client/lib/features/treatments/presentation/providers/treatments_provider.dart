import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/datasources/treatments_local_datasource.dart';
import '../../data/repositories/treatments_repository_impl.dart';
import '../../domain/entities/treatment_entity.dart';
import '../../domain/repositories/treatments_repository.dart';
import 'treatments_state.dart';

/// Provider pour le datasource local des traitements
final treatmentsLocalDatasourceProvider = Provider<TreatmentsLocalDatasource>((ref) {
  return TreatmentsLocalDatasource();
});

/// Provider pour le repository des traitements
final treatmentsRepositoryProvider = Provider<TreatmentsRepository>((ref) {
  final localDatasource = ref.watch(treatmentsLocalDatasourceProvider);
  return TreatmentsRepositoryImpl(localDatasource);
});

/// Provider principal pour les traitements
final treatmentsProvider = StateNotifierProvider<TreatmentsNotifier, TreatmentsState>((ref) {
  final repository = ref.watch(treatmentsRepositoryProvider);
  return TreatmentsNotifier(repository);
});

/// Provider pour les traitements nécessitant un renouvellement
final treatmentsNeedingRenewalProvider = Provider<List<TreatmentEntity>>((ref) {
  final state = ref.watch(treatmentsProvider);
  return state.treatmentsNeedingRenewal;
});

/// Provider pour le nombre de traitements à renouveler (pour badge)
final renewalCountProvider = Provider<int>((ref) {
  return ref.watch(treatmentsNeedingRenewalProvider).length;
});

/// Notifier pour gérer l'état des traitements
class TreatmentsNotifier extends StateNotifier<TreatmentsState> {
  final TreatmentsRepository _repository;

  TreatmentsNotifier(this._repository) : super(const TreatmentsState());

  /// Charge tous les traitements
  Future<void> loadTreatments() async {
    state = state.copyWith(status: TreatmentsStatus.loading);

    final result = await _repository.getTreatments();
    final renewalResult = await _repository.getTreatmentsNeedingRenewal();

    result.fold(
      (failure) {
        state = state.copyWith(
          status: TreatmentsStatus.error,
          errorMessage: failure.message,
        );
      },
      (treatments) {
        renewalResult.fold(
          (failure) {
            state = state.copyWith(
              status: TreatmentsStatus.loaded,
              treatments: treatments,
              treatmentsNeedingRenewal: [],
            );
          },
          (needingRenewal) {
            state = state.copyWith(
              status: TreatmentsStatus.loaded,
              treatments: treatments,
              treatmentsNeedingRenewal: needingRenewal,
            );
          },
        );
      },
    );
  }

  /// Ajoute un nouveau traitement
  Future<bool> addTreatment(TreatmentEntity treatment) async {
    final result = await _repository.addTreatment(treatment);

    return result.fold(
      (failure) {
        AppLogger.error('Failed to add treatment: ${failure.message}');
        return false;
      },
      (newTreatment) {
        final updatedTreatments = [...state.treatments, newTreatment];
        // Recalculer ceux qui ont besoin de renouvellement
        final needingRenewal = updatedTreatments
            .where((t) => t.needsRenewalSoon || t.isOverdue)
            .toList();
        
        state = state.copyWith(
          treatments: updatedTreatments,
          treatmentsNeedingRenewal: needingRenewal,
        );
        return true;
      },
    );
  }

  /// Met à jour un traitement
  Future<bool> updateTreatment(TreatmentEntity treatment) async {
    final result = await _repository.updateTreatment(treatment);

    return result.fold(
      (failure) {
        AppLogger.error('Failed to update treatment: ${failure.message}');
        return false;
      },
      (updatedTreatment) {
        final updatedTreatments = state.treatments.map((t) {
          return t.id == updatedTreatment.id ? updatedTreatment : t;
        }).toList();
        
        final needingRenewal = updatedTreatments
            .where((t) => t.needsRenewalSoon || t.isOverdue)
            .toList();
        
        state = state.copyWith(
          treatments: updatedTreatments,
          treatmentsNeedingRenewal: needingRenewal,
        );
        return true;
      },
    );
  }

  /// Supprime un traitement
  Future<bool> deleteTreatment(String treatmentId) async {
    final result = await _repository.deleteTreatment(treatmentId);

    return result.fold(
      (failure) {
        AppLogger.error('Failed to delete treatment: ${failure.message}');
        return false;
      },
      (_) {
        final updatedTreatments = state.treatments
            .where((t) => t.id != treatmentId)
            .toList();
        
        final needingRenewal = updatedTreatments
            .where((t) => t.needsRenewalSoon || t.isOverdue)
            .toList();
        
        state = state.copyWith(
          treatments: updatedTreatments,
          treatmentsNeedingRenewal: needingRenewal,
        );
        return true;
      },
    );
  }

  /// Marque un traitement comme commandé
  Future<bool> markAsOrdered(String treatmentId) async {
    final result = await _repository.markAsOrdered(treatmentId);

    return result.fold(
      (failure) {
        AppLogger.error('Failed to mark treatment as ordered: ${failure.message}');
        return false;
      },
      (updatedTreatment) {
        final updatedTreatments = state.treatments.map((t) {
          return t.id == updatedTreatment.id ? updatedTreatment : t;
        }).toList();
        
        final needingRenewal = updatedTreatments
            .where((t) => t.needsRenewalSoon || t.isOverdue)
            .toList();
        
        state = state.copyWith(
          treatments: updatedTreatments,
          treatmentsNeedingRenewal: needingRenewal,
        );
        return true;
      },
    );
  }

  /// Active/désactive les rappels pour un traitement
  Future<bool> toggleReminder(String treatmentId, bool enabled) async {
    final result = await _repository.toggleReminder(treatmentId, enabled);

    return result.fold(
      (failure) {
        AppLogger.error('Failed to toggle reminder: ${failure.message}');
        return false;
      },
      (updatedTreatment) {
        final updatedTreatments = state.treatments.map((t) {
          return t.id == updatedTreatment.id ? updatedTreatment : t;
        }).toList();
        
        state = state.copyWith(treatments: updatedTreatments);
        return true;
      },
    );
  }
}
