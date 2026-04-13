import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/address_model.dart';

/// Données de formulaire d'adresse (labels, valeurs par défaut)
class AddressFormData {
  final List<String> labels;
  final String? defaultPhone;
  final String? userName;

  const AddressFormData({
    required this.labels,
    this.defaultPhone,
    this.userName,
  });
}

/// Data source pour les adresses via l'API
class AddressRemoteDataSource {
  final ApiClient _apiClient;

  AddressRemoteDataSource(this._apiClient);

  /// Obtenir toutes les adresses
  Future<List<AddressModel>> getAddresses() async {
    final response = await _apiClient.get(ApiConstants.addresses);

    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => AddressModel.fromJson(json)).toList();
  }

  /// Obtenir une adresse par ID
  Future<AddressModel> getAddress(int id) async {
    final response = await _apiClient.get(ApiConstants.addressDetails(id));
    return AddressModel.fromJson(response.data['data']);
  }

  /// Obtenir l'adresse par défaut
  Future<AddressModel> getDefaultAddress() async {
    final response = await _apiClient.get(ApiConstants.addressDefault);
    return AddressModel.fromJson(response.data['data']);
  }

  /// Créer une adresse
  Future<AddressModel> createAddress({
    required String label,
    required String address,
    String? city,
    String? district,
    String? phone,
    String? instructions,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.addresses,
      data: {
        'label': label,
        'address': address,
        'city': ?city,
        'district': ?district,
        'phone': ?phone,
        'instructions': ?instructions,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'is_default': isDefault,
      },
    );
    return AddressModel.fromJson(response.data['data']);
  }

  /// Mettre à jour une adresse
  Future<AddressModel> updateAddress({
    required int id,
    String? label,
    String? address,
    String? city,
    String? district,
    String? phone,
    String? instructions,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.addressDetails(id),
      data: {
        'label': ?label,
        'address': ?address,
        'city': ?city,
        'district': ?district,
        'phone': ?phone,
        'instructions': ?instructions,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'is_default': ?isDefault,
      },
    );
    return AddressModel.fromJson(response.data['data']);
  }

  /// Supprimer une adresse
  Future<void> deleteAddress(int id) async {
    await _apiClient.delete(ApiConstants.addressDetails(id).toString());
  }

  /// Définir une adresse comme défaut
  Future<AddressModel> setDefaultAddress(int id) async {
    final response = await _apiClient.post(ApiConstants.setDefaultAddress(id));
    return AddressModel.fromJson(response.data['data']);
  }

  /// Obtenir les labels disponibles avec données de pré-remplissage
  Future<AddressFormData> getLabels() async {
    final response = await _apiClient.get(ApiConstants.addressLabels);
    final data = response.data['data'];

    // Gérer le nouveau format (objet avec labels, default_phone, user_name)
    if (data is Map<String, dynamic>) {
      final labelsList = data['labels'] as List<dynamic>? ?? [];
      return AddressFormData(
        labels: labelsList.map((e) => e.toString()).toList(),
        defaultPhone: data['default_phone'] as String?,
        userName: data['user_name'] as String?,
      );
    }

    // Fallback pour l'ancien format (liste simple)
    if (data is List) {
      return AddressFormData(labels: data.map((e) => e.toString()).toList());
    }

    return AddressFormData(labels: ['Maison', 'Bureau', 'Famille', 'Autre']);
  }
}
