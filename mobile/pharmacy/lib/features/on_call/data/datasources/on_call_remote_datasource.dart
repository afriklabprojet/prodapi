import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/on_call_model.dart';

abstract class OnCallRemoteDataSource {
  Future<List<OnCallModel>> getOnCalls();
  Future<OnCallModel> createOnCall(Map<String, dynamic> data);
  Future<void> deleteOnCall(int id);
}

class OnCallRemoteDataSourceImpl implements OnCallRemoteDataSource {
  final ApiClient _apiClient;

  OnCallRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<OnCallModel>> getOnCalls() async {
    final response = await _apiClient.get('/pharmacy/on-calls');
    final raw = response.data;
    if (kDebugMode) {
      debugPrint('[OnCall] response.data runtimeType=${raw.runtimeType}');
      if (raw is Map) {
        debugPrint('[OnCall] keys=${raw.keys.toList()}');
        final d = raw['data'];
        debugPrint('[OnCall] data runtimeType=${d.runtimeType}');
        if (d is Map) debugPrint('[OnCall] data.keys=${d.keys.toList()}');
      }
    }
    final list = _extractList(raw);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => OnCallModel.fromJson(e))
        .toList();
  }

  /// Extract a List from any API response shape — maximally defensive.
  ///
  /// Handles:
  ///   - Direct List
  ///   - { "data": [ ... ] }
  ///   - { "data": { "data": [ ... ], ... } }   (paginate inside wrapper)
  ///   - { "current_page": .., "data": [ ... ] } (raw paginator)
  ///   - { "status": .., "data": { "current_page": .., "data": [...] } }
  static List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map) {
        final nested = inner['data'];
        if (nested is List) return nested;
      }
      // Maybe 'items' key from some APIs
      final items = data['items'];
      if (items is List) return items;
    }
    return [];
  }

  @override
  Future<OnCallModel> createOnCall(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/pharmacy/on-calls', data: data);
    final responseData = response.data;
    final onCallData = responseData is Map && responseData['data'] != null
        ? responseData['data']
        : responseData;
    return OnCallModel.fromJson(onCallData);
  }

  @override
  Future<void> deleteOnCall(int id) async {
    await _apiClient.delete('/pharmacy/on-calls/$id');
  }
}

final onCallRemoteDataSourceProvider = Provider<OnCallRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnCallRemoteDataSourceImpl(apiClient: apiClient);
});
