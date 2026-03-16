import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/exceptions.dart';
import '../../data/models/prescription_model.dart';
import '../../data/datasources/prescription_remote_datasource.dart';

/// Repository pour le provider de prescriptions (utilise les modèles directement)
class PrescriptionRepository {
  final PrescriptionRemoteDataSource _dataSource;

  PrescriptionRepository(this._dataSource);

  Future<Either<Failure, List<PrescriptionModel>>> getPrescriptions() async {
    try {
      final result = await _dataSource.getPrescriptions();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, PrescriptionModel>> updateStatus(
    int id,
    String status, {
    String? notes,
    double? quoteAmount,
  }) async {
    try {
      final result = await _dataSource.updateStatus(id, status, notes: notes, quoteAmount: quoteAmount);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, AnalysisResult>> analyzePrescription(int id, {bool force = false}) async {
    try {
      final result = await _dataSource.analyzePrescription(id, force: force);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  final dataSource = ref.watch(prescriptionRemoteDataSourceProvider);
  return PrescriptionRepository(dataSource);
});

enum PrescriptionStatus { initial, loading, loaded, error }
enum AnalysisStatus { initial, analyzing, analyzed, error }

class PrescriptionListState {
  final PrescriptionStatus status;
  final List<PrescriptionModel> prescriptions;
  final String? errorMessage;
  final String activeFilter; // 'all', 'pending', 'validated'
  
  // Analysis state
  final AnalysisStatus analysisStatus;
  final AnalysisResult? analysisResult;
  final String? analysisError;

  PrescriptionListState({
    this.status = PrescriptionStatus.initial,
    this.prescriptions = const [],
    this.errorMessage,
    this.activeFilter = 'all',
    this.analysisStatus = AnalysisStatus.initial,
    this.analysisResult,
    this.analysisError,
  });

  PrescriptionListState copyWith({
    PrescriptionStatus? status,
    List<PrescriptionModel>? prescriptions,
    String? errorMessage,
    String? activeFilter,
    AnalysisStatus? analysisStatus,
    AnalysisResult? analysisResult,
    String? analysisError,
  }) {
    return PrescriptionListState(
      status: status ?? this.status,
      prescriptions: prescriptions ?? this.prescriptions,
      errorMessage: errorMessage ?? this.errorMessage,
      activeFilter: activeFilter ?? this.activeFilter,
      analysisStatus: analysisStatus ?? this.analysisStatus,
      analysisResult: analysisResult ?? this.analysisResult,
      analysisError: analysisError ?? this.analysisError,
    );
  }
}

class PrescriptionListNotifier extends StateNotifier<PrescriptionListState> {
  final PrescriptionRepository _repository;

  PrescriptionListNotifier(this._repository) : super(PrescriptionListState()) {
    getPrescriptions();
  }

  Future<void> getPrescriptions() async {
    state = state.copyWith(status: PrescriptionStatus.loading);

    final result = await _repository.getPrescriptions();

    result.fold(
      (failure) => state = state.copyWith(
        status: PrescriptionStatus.error,
        errorMessage: failure.message,
      ),
      (prescriptions) => state = state.copyWith(
        status: PrescriptionStatus.loaded,
        prescriptions: prescriptions,
      ),
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }
  
  List<PrescriptionModel> get filteredPrescriptions {
    if (state.activeFilter == 'all') {
      return state.prescriptions;
    }
    return state.prescriptions.where((p) => p.status == state.activeFilter).toList();
  }

  Future<void> updateStatus(int id, String status, {String? notes, double? quoteAmount}) async {
      // Optimistic update or reload
      final result = await _repository.updateStatus(id, status, notes: notes, quoteAmount: quoteAmount);
      
      result.fold(
          (failure) => null, // Handle error toast in UI
          (updated) {
              final newList = state.prescriptions.map((p) => p.id == id ? updated : p).toList();
              state = state.copyWith(prescriptions: newList);
          }
      );
  }

  Future<void> sendQuote(int id, double amount, {String? notes}) async {
    // Re-use updateStatus logic but with specific status
    await updateStatus(id, 'quoted', notes: notes, quoteAmount: amount);
  }

  Future<AnalysisResult?> analyzePrescription(int id, {bool force = false}) async {
    state = state.copyWith(analysisStatus: AnalysisStatus.analyzing, analysisError: null);
    
    final result = await _repository.analyzePrescription(id, force: force);
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          analysisStatus: AnalysisStatus.error,
          analysisError: failure.message,
        );
        return null;
      },
      (analysisResult) {
        // Update the prescription in list
        final newList = state.prescriptions.map((p) {
          if (p.id == id) {
            return analysisResult.prescription;
          }
          return p;
        }).toList();
        
        state = state.copyWith(
          analysisStatus: AnalysisStatus.analyzed,
          analysisResult: analysisResult,
          prescriptions: newList,
        );
        return analysisResult;
      },
    );
  }

  void clearAnalysisResult() {
    state = state.copyWith(
      analysisStatus: AnalysisStatus.initial,
      analysisResult: null,
      analysisError: null,
    );
  }
}

final prescriptionListProvider = StateNotifierProvider<PrescriptionListNotifier, PrescriptionListState>((ref) {
  final repository = ref.watch(prescriptionRepositoryProvider);
  return PrescriptionListNotifier(repository);
});
