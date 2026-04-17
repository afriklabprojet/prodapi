import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/prescription_model.dart';

/// Result of prescription analysis
class AnalysisResult {
  final PrescriptionModel prescription;
  final List<dynamic> extractedMedications;
  final List<dynamic> medicalExams;
  final List<dynamic> matchedProducts;
  final List<dynamic> unmatchedMedications;
  final Map<String, List<dynamic>> alternatives;
  final Map<String, dynamic> stats;
  final double estimatedTotal;
  final double confidence;
  final List<Map<String, dynamic>> alerts;
  final String rawText;
  final bool hasHandwriting;

  AnalysisResult({
    required this.prescription,
    required this.extractedMedications,
    this.medicalExams = const [],
    required this.matchedProducts,
    required this.unmatchedMedications,
    required this.alternatives,
    required this.stats,
    required this.estimatedTotal,
    required this.confidence,
    required this.alerts,
    this.rawText = '',
    this.hasHandwriting = false,
  });
}

/// Result of dispensing medications
class DispenseResult {
  final PrescriptionModel prescription;
  final int dispensedCount;
  final String fulfillmentStatus;
  final String message;

  DispenseResult({
    required this.prescription,
    required this.dispensedCount,
    required this.fulfillmentStatus,
    required this.message,
  });
}

/// Duplicate prescription info
class DuplicateInfo {
  final int prescriptionId;
  final String status;
  final String fulfillmentStatus;
  final String? firstDispensedAt;
  final int dispensingCount;
  final String? createdAt;

  DuplicateInfo({
    required this.prescriptionId,
    required this.status,
    required this.fulfillmentStatus,
    this.firstDispensedAt,
    required this.dispensingCount,
    this.createdAt,
  });

  factory DuplicateInfo.fromJson(Map<String, dynamic> json) {
    return DuplicateInfo(
      prescriptionId: json['prescription_id'] ?? 0,
      status: json['status']?.toString() ?? '',
      fulfillmentStatus: json['fulfillment_status']?.toString() ?? '',
      firstDispensedAt: json['first_dispensed_at']?.toString(),
      dispensingCount: (json['dispensing_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }
}

abstract class PrescriptionRemoteDataSource {
  Future<List<PrescriptionModel>> getPrescriptions();
  Future<PrescriptionModel> getPrescription(int id);
  Future<PrescriptionModel> updateStatus(int id, String status, {String? notes, double? quoteAmount});
  Future<AnalysisResult> analyzePrescription(int id, {bool force = false});
  Future<DispenseResult> dispensePrescription(int id, List<Map<String, dynamic>> medications);
}

class PrescriptionRemoteDataSourceImpl implements PrescriptionRemoteDataSource {
  final ApiClient _client;

  PrescriptionRemoteDataSourceImpl(this._client);

  /// Extract a List from various API response shapes.
  static List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map && inner['data'] is List) return inner['data'] as List;
    }
    return [];
  }

  @override
  Future<List<PrescriptionModel>> getPrescriptions() async {
    final response = await _client.get('/pharmacy/prescriptions');
    final data = _extractList(response.data);
    // Parse each item individually so one corrupt entry doesn't crash the whole list.
    final List<PrescriptionModel> result = [];
    for (final json in data) {
      try {
        result.add(PrescriptionModel.fromJson(json as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed entries silently - user still sees valid prescriptions.
      }
    }
    return result;
  }

  @override
  Future<PrescriptionModel> getPrescription(int id) async {
    final response = await _client.get('/pharmacy/prescriptions/$id');
    return PrescriptionModel.fromJson(response.data['data']);
  }

  /// Get prescription with duplicate info
  Future<({PrescriptionModel prescription, DuplicateInfo? duplicateInfo})> getPrescriptionWithDuplicate(int id) async {
    final response = await _client.get('/pharmacy/prescriptions/$id');
    final prescription = PrescriptionModel.fromJson(response.data['data']);
    DuplicateInfo? duplicateInfo;
    if (response.data['duplicate_info'] != null && response.data['duplicate_info'] is Map) {
      duplicateInfo = DuplicateInfo.fromJson(response.data['duplicate_info']);
    }
    return (prescription: prescription, duplicateInfo: duplicateInfo);
  }

  @override
  Future<PrescriptionModel> updateStatus(int id, String status, {String? notes, double? quoteAmount}) async {
    final response = await _client.post(
      '/pharmacy/prescriptions/$id/status',
      data: {
        'status': status,
        if (notes != null) 'pharmacy_notes': notes,
        if (quoteAmount != null) 'quote_amount': quoteAmount,
      },
    );
    return PrescriptionModel.fromJson(response.data['data']);
  }

  @override
  Future<AnalysisResult> analyzePrescription(int id, {bool force = false}) async {
    final response = await _client.post(
      '/pharmacy/prescriptions/$id/analyze',
      data: {'force': force},
    );
    
    final responseData = response.data;
    final data = responseData['data'] as Map<String, dynamic>?;
    
    if (data == null || data['prescription'] == null) {
      throw Exception(responseData['message']?.toString() ?? 'Réponse invalide du serveur');
    }
    
    // Parse alternatives safely
    final rawAlternatives = data['alternatives'];
    Map<String, List<dynamic>> alternatives = {};
    if (rawAlternatives is Map) {
      rawAlternatives.forEach((key, value) {
        alternatives[key.toString()] = value is List ? value : [];
      });
    }
    
    return AnalysisResult(
      prescription: PrescriptionModel.fromJson(data['prescription']),
      extractedMedications: data['extracted_medications'] ?? [],
      medicalExams: data['medical_exams'] ?? [],
      matchedProducts: data['matched_products'] ?? [],
      unmatchedMedications: data['unmatched'] ?? [],
      alternatives: alternatives,
      stats: data['stats'] is Map<String, dynamic> ? data['stats'] : {},
      estimatedTotal: _safeDouble(data['estimated_total']),
      confidence: _safeDouble(data['confidence']),
      alerts: (data['alerts'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      rawText: data['raw_text']?.toString() ?? '',
      hasHandwriting: data['has_handwriting'] == true,
    );
  }

  @override
  Future<DispenseResult> dispensePrescription(int id, List<Map<String, dynamic>> medications) async {
    final response = await _client.post(
      '/pharmacy/prescriptions/$id/dispense',
      data: {'medications': medications},
    );

    final responseData = response.data;
    final prescriptionData = responseData['data'];

    return DispenseResult(
      prescription: prescriptionData != null
          ? PrescriptionModel.fromJson(prescriptionData)
          : PrescriptionModel.fromJson({'id': id, 'customer_id': 0, 'status': 'pending', 'created_at': ''}),
      dispensedCount: (responseData['dispensed_count'] as num?)?.toInt() ?? 0,
      fulfillmentStatus: responseData['fulfillment_status']?.toString() ?? 'none',
      message: responseData['message']?.toString() ?? '',
    );
  }
}

/// Parse a value that may be int, double, String, or null into double safely.
double _safeDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

final prescriptionRemoteDataSourceProvider = Provider<PrescriptionRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PrescriptionRemoteDataSourceImpl(apiClient);
});
