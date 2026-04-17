import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/profile_model.dart';

class ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSource(this.apiClient);

  Future<ProfileModel> getProfile() async {
    final response = await apiClient.get(ApiConstants.me);
    return ProfileModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    final response = await apiClient.post(
      ApiConstants.updateProfile,
      data: data,
    );
    return ProfileModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<String> uploadAvatar(Uint8List imageBytes) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(imageBytes, filename: 'avatar.jpg'),
    });
    final response = await apiClient.post(
      ApiConstants.uploadAvatar,
      data: formData,
    );
    final path = response.data['data']['avatar_url'] as String? ?? '';
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${EnvConfig.apiBaseUrl}$path';
  }

  Future<void> deleteAvatar() async {
    await apiClient.delete('/auth/avatar');
  }
}
