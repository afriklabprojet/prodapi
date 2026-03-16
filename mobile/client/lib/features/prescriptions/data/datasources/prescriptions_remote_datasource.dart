import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart'; // Keep for FormData
import '../../../../core/network/api_client.dart';

abstract class PrescriptionsRemoteDataSource {
  Future<Map<String, dynamic>> uploadPrescription({
    required List<XFile> images,
    String? notes,
  });

  Future<List<Map<String, dynamic>>> getPrescriptions();
  Future<Map<String, dynamic>> getPrescriptionDetails(int prescriptionId);
  Future<Map<String, dynamic>> payPrescription(int prescriptionId, String paymentMethod);
}

class PrescriptionsRemoteDataSourceImpl
    implements PrescriptionsRemoteDataSource {
  final ApiClient apiClient;

  PrescriptionsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> uploadPrescription({
    required List<XFile> images,
    String? notes,
  }) async {
    try {
      // Prepare multipart form data
      final formData = FormData();

      // Add images
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = file.path.split('/').last;

        formData.files.add(
          MapEntry(
            'images[]',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      // Add notes if provided
      if (notes != null && notes.isNotEmpty) {
        formData.fields.add(MapEntry('notes', notes));
      }

      // Upload
      final response = await apiClient.post(
        '/customer/prescriptions/upload',
        data: formData,
        // FormData automatically sets the correct Content-Type with boundary
      );

      return response.data['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    final response = await apiClient.get('/customer/prescriptions');
    final rawData = response.data['data'];
    return rawData is List ? List<Map<String, dynamic>>.from(rawData) : [];
  }

  @override
  Future<Map<String, dynamic>> getPrescriptionDetails(
    int prescriptionId,
  ) async {
    final response = await apiClient.get('/customer/prescriptions/$prescriptionId');
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> payPrescription(int prescriptionId, String paymentMethod) async {
    final response = await apiClient.post(
      '/customer/prescriptions/$prescriptionId/pay',
      data: {'payment_method': paymentMethod},
    );
    return response.data;
  }
}
