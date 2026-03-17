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
    final list = _extractList(response.data);
    return list.map((e) => OnCallModel.fromJson(e)).toList();
  }

  /// Extract a List from various API response shapes:
  ///   - Direct List
  ///   - { "data": [ ... ] }                 (simple wrapper)
  ///   - { "data": { "data": [ ... ] } }     (Laravel paginate inside wrapper)
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
