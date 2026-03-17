import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/prescription_model.dart';

/// Result of prescription analysis
class AnalysisResult {
  final PrescriptionModel prescription;
  final List<dynamic> extractedMedications;
  final List<dynamic> matchedProducts;
  final List<dynamic> unmatchedMedications;
  final Map<String, List<dynamic>> alternatives;
  final Map<String, dynamic> stats;
  final double estimatedTotal;
  final double confidence;
  final List<Map<String, dynamic>> alerts;

  AnalysisResult({
    required this.prescription,
    required this.extractedMedications,
    required this.matchedProducts,
    required this.unmatchedMedications,
    required this.alternatives,
    required this.stats,
    required this.estimatedTotal,
    required this.confidence,
    required this.alerts,
  });
}

abstract class PrescriptionRemoteDataSource {
  Future<List<PrescriptionModel>> getPrescriptions();
  Future<PrescriptionModel> getPrescription(int id);
  Future<PrescriptionModel> updateStatus(int id, String status, {String? notes, double? quoteAmount});
  Future<AnalysisResult> analyzePrescription(int id, {bool force = false});
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
    
    final data = response.data['data'];
    
    return AnalysisResult(
      prescription: PrescriptionModel.fromJson(data['prescription']),
      extractedMedications: data['extracted_medications'] ?? [],
      matchedProducts: data['matched_products'] ?? [],
      unmatchedMedications: data['unmatched'] ?? [],
      alternatives: Map<String, List<dynamic>>.from(data['alternatives'] ?? {}),
      stats: data['stats'] ?? {},
      estimatedTotal: _safeDouble(data['estimated_total']),
      confidence: _safeDouble(data['confidence']),
      alerts: List<Map<String, dynamic>>.from(data['alerts'] ?? []),
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
