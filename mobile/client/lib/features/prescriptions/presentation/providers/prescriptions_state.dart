import 'package:equatable/equatable.dart';
import '../../domain/entities/prescription_entity.dart';

enum PrescriptionsStatus { initial, loading, loaded, uploading, error }

extension PrescriptionsStatusX on PrescriptionsStatus {
  bool get isLoading => this == PrescriptionsStatus.loading;
  bool get isUploading => this == PrescriptionsStatus.uploading;
  bool get isError => this == PrescriptionsStatus.error;
  bool get isLoaded => this == PrescriptionsStatus.loaded;
}

class PrescriptionsState extends Equatable {
  final PrescriptionsStatus status;
  final List<PrescriptionEntity> prescriptions;
  final PrescriptionEntity? selectedPrescription;
  final PrescriptionEntity? uploadedPrescription;
  final String? errorMessage;
  final bool lastUploadIsDuplicate;
  final int? lastUploadExistingId;
  final String? lastUploadExistingStatus;

  const PrescriptionsState({
    this.status = PrescriptionsStatus.initial,
    this.prescriptions = const [],
    this.selectedPrescription,
    this.uploadedPrescription,
    this.errorMessage,
    this.lastUploadIsDuplicate = false,
    this.lastUploadExistingId,
    this.lastUploadExistingStatus,
  });

  PrescriptionsState copyWith({
    PrescriptionsStatus? status,
    List<PrescriptionEntity>? prescriptions,
    PrescriptionEntity? selectedPrescription,
    bool clearSelected = false,
    PrescriptionEntity? uploadedPrescription,
    bool clearUploaded = false,
    String? errorMessage,
    bool clearError = false,
    bool? lastUploadIsDuplicate,
    int? lastUploadExistingId,
    String? lastUploadExistingStatus,
    bool clearDuplicateInfo = false,
  }) {
    return PrescriptionsState(
      status: status ?? this.status,
      prescriptions: prescriptions ?? this.prescriptions,
      selectedPrescription: clearSelected
          ? null
          : (selectedPrescription ?? this.selectedPrescription),
      uploadedPrescription: clearUploaded
          ? null
          : (uploadedPrescription ?? this.uploadedPrescription),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUploadIsDuplicate: clearDuplicateInfo
          ? false
          : (lastUploadIsDuplicate ?? this.lastUploadIsDuplicate),
      lastUploadExistingId: clearDuplicateInfo
          ? null
          : (lastUploadExistingId ?? this.lastUploadExistingId),
      lastUploadExistingStatus: clearDuplicateInfo
          ? null
          : (lastUploadExistingStatus ?? this.lastUploadExistingStatus),
    );
  }

  @override
  List<Object?> get props => [
    status,
    prescriptions,
    selectedPrescription,
    uploadedPrescription,
    errorMessage,
    lastUploadIsDuplicate,
    lastUploadExistingId,
    lastUploadExistingStatus,
  ];
}
