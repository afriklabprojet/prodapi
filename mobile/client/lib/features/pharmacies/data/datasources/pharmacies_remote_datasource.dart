import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/cache_service.dart';
import '../models/pharmacy_model.dart';

class PharmaciesRemoteDataSource {
  final ApiClient apiClient;

  PharmaciesRemoteDataSource(this.apiClient);

  Future<List<PharmacyModel>> getPharmacies({int page = 1, int perPage = AppConstants.defaultPageSize}) async {
    final cacheKey = 'pharmacies_p${page}_pp$perPage';
    try {
      final response = await apiClient.get(
        ApiConstants.pharmacies,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final List<dynamic> data = response.data['data'] ?? [];
      CacheService.cachePharmacies(cacheKey, data.cast<Map<String, dynamic>>());
      return data
          .map((json) => PharmacyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final cached = CacheService.getCachedPharmacies(cacheKey);
      if (cached != null) {
        AppLogger.info('Pharmacies loaded from cache');
        return cached.map((json) => PharmacyModel.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<List<PharmacyModel>> getNearbyPharmacies({
    required double latitude,
    required double longitude,
    double? radius,
  }) async {
    final response = await apiClient.get(
      ApiConstants.nearbyPharmacies,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': ?radius,
      },
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data
        .map((json) => PharmacyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PharmacyModel>> getOnDutyPharmacies({double? latitude, double? longitude, double? radius}) async {
    final cacheKey = 'on_duty';
    try {
      final response = await apiClient.get(
        ApiConstants.onDutyPharmacies,
        queryParameters: {
          'latitude': ?latitude,
          'longitude': ?longitude,
          'radius': ?radius,
        },
      );
      final List<dynamic> data = response.data['data'] ?? [];
      CacheService.cachePharmacies(cacheKey, data.cast<Map<String, dynamic>>());
      return data
          .map((json) => PharmacyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final cached = CacheService.getCachedPharmacies(cacheKey);
      if (cached != null) {
        AppLogger.info('On-duty pharmacies loaded from cache');
        return cached.map((json) => PharmacyModel.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<PharmacyModel> getPharmacyDetails(int pharmacyId) async {
    final response = await apiClient.get(ApiConstants.pharmacyDetails(pharmacyId));
    return PharmacyModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<PharmacyModel>> getFeaturedPharmacies() async {
    const cacheKey = 'featured';
    try {
      final response = await apiClient.get(ApiConstants.featuredPharmacies);
      final List<dynamic> data = response.data['data'] ?? [];
      CacheService.cachePharmacies(cacheKey, data.cast<Map<String, dynamic>>());
      return data
          .map((json) => PharmacyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final cached = CacheService.getCachedPharmacies(cacheKey);
      if (cached != null) {
        AppLogger.info('Featured pharmacies loaded from cache');
        return cached.map((json) => PharmacyModel.fromJson(json)).toList();
      }
      rethrow;
    }
  }
}
