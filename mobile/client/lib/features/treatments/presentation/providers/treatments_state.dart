import 'package:equatable/equatable.dart';
import '../../domain/entities/treatment_entity.dart';

enum TreatmentsStatus { initial, loading, loaded, error }

class TreatmentsState extends Equatable {
  final TreatmentsStatus status;
  final List<TreatmentEntity> treatments;
  final List<TreatmentEntity> treatmentsNeedingRenewal;
  final String? errorMessage;

  const TreatmentsState({
    this.status = TreatmentsStatus.initial,
    this.treatments = const [],
    this.treatmentsNeedingRenewal = const [],
    this.errorMessage,
  });

  TreatmentsState copyWith({
    TreatmentsStatus? status,
    List<TreatmentEntity>? treatments,
    List<TreatmentEntity>? treatmentsNeedingRenewal,
    String? errorMessage,
  }) {
    return TreatmentsState(
      status: status ?? this.status,
      treatments: treatments ?? this.treatments,
      treatmentsNeedingRenewal: treatmentsNeedingRenewal ?? this.treatmentsNeedingRenewal,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, treatments, treatmentsNeedingRenewal, errorMessage];
}
