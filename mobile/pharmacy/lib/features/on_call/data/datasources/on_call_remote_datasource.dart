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
    final data = response.data;
    final list = data is Map && data['data'] != null ? data['data'] as List : data as List;
    return list.map((e) => OnCallModel.fromJson(e)).toList();
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
