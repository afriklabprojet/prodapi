import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/utils/error_translator.dart';
import '../../data/datasources/prescriptions_remote_datasource.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../../prescriptions/data/models/prescription_model.dart';
import 'prescriptions_state.dart';

class PrescriptionsNotifier extends StateNotifier<PrescriptionsState> {
  final PrescriptionsRemoteDataSource remoteDataSource;

  PrescriptionsNotifier({required this.remoteDataSource})
    : super(const PrescriptionsState());

  Future<void> loadPrescriptions() async {
    state = state.copyWith(status: PrescriptionsStatus.loading);
    try {
      final data = await remoteDataSource.getPrescriptions();
      final prescriptions = data
          .map((json) => PrescriptionModel.fromJson(json).toEntity())
          .toList();
      state = state.copyWith(
        status: PrescriptionsStatus.loaded,
        prescriptions: prescriptions,
      );
    } catch (e) {
      AppLogger.error('Failed to load prescriptions', error: e);
      state = state.copyWith(
        status: PrescriptionsStatus.error,
        errorMessage: ErrorTranslator.toUserFriendly(e.toString()),
      );
    }
  }

  Future<void> getPrescriptionDetails(int id) async {
    state = state.copyWith(status: PrescriptionsStatus.loading);
    try {
      final data = await remoteDataSource.getPrescriptionDetails(id);
      final prescription = PrescriptionModel.fromJson(data).toEntity();
      state = state.copyWith(
        status: PrescriptionsStatus.loaded,
        selectedPrescription: prescription,
      );
    } catch (e) {
      AppLogger.error('Failed to get prescription details', error: e);
      state = state.copyWith(
        status: PrescriptionsStatus.error,
        errorMessage: ErrorTranslator.toUserFriendly(e.toString()),
      );
    }
  }

  Future<PrescriptionEntity?> uploadPrescription({
    required List<XFile> images,
    String? notes,
  }) async {
    state = state.copyWith(
      status: PrescriptionsStatus.uploading,
      clearDuplicateInfo: true,
    );
    try {
      final responseData = await remoteDataSource.uploadPrescription(
        images: images,
        notes: notes,
      );
      final prescriptionData =
          responseData['data'] as Map<String, dynamic>? ?? {};
      final prescription = PrescriptionModel.fromJson(
        prescriptionData,
      ).toEntity();
      final isDuplicate = responseData['is_duplicate'] == true;
      state = state.copyWith(
        status: PrescriptionsStatus.loaded,
        uploadedPrescription: prescription,
        lastUploadIsDuplicate: isDuplicate,
        lastUploadExistingId: responseData['existing_prescription_id'] as int?,
        lastUploadExistingStatus: responseData['existing_status'] as String?,
      );
      return prescription;
    } catch (e) {
      AppLogger.error('Failed to upload prescription', error: e);
      state = state.copyWith(
        status: PrescriptionsStatus.error,
        errorMessage: ErrorTranslator.toUserFriendly(e.toString()),
      );
      return null;
    }
  }

  Future<void> payPrescription(int id) async {
    state = state.copyWith(status: PrescriptionsStatus.loading);
    try {
      final data = await remoteDataSource.payPrescription(id, 'jeko');
      final prescription = PrescriptionModel.fromJson(data).toEntity();
      state = state.copyWith(
        status: PrescriptionsStatus.loaded,
        selectedPrescription: prescription,
      );
    } catch (e) {
      AppLogger.error('Failed to pay prescription', error: e);
      state = state.copyWith(
        status: PrescriptionsStatus.error,
        errorMessage: ErrorTranslator.toUserFriendly(e.toString()),
      );
    }
  }
}
