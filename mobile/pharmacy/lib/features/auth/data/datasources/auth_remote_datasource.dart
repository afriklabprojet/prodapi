import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Helper pour parser response.data de manière sûre
Map<String, dynamic> _safeData(dynamic data) => ApiClient.parseResponseData(data);

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<AuthResponseModel> register({
    required String name,
    required String pName, // pharmacy name
    required String email,
    required String phone,
    required String password,
    required String licenseNumber,
    required String city,
    required String address,
    required double latitude,
    required double longitude,
  });

  Future<void> logout(String token);

  Future<UserModel> getCurrentUser(String token);

  Future<void> forgotPassword({required String email});

  Future<AuthResponseModel> refreshSession({required String token});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    // Normaliser l'email en minuscules pour éviter les problèmes de case sensitivity
    final normalizedEmail = email.toLowerCase().trim();
    
    if (kDebugMode) debugPrint('🌐 [AuthRemoteDataSource] login() - email: $normalizedEmail');
    if (kDebugMode) debugPrint('🌐 [AuthRemoteDataSource] Envoi requête POST vers /auth/login...');
    
    final response = await apiClient.post(
      '/auth/login', // Adjust endpoint if needed
      data: {
        'email': normalizedEmail,
        'password': password,
        'device_name': 'pharmacy-app',
        'role':
            'pharmacy', // Assuming backend filters or validates role if sent
      },
    );
    
    if (kDebugMode) debugPrint('🌐 [AuthRemoteDataSource] Réponse reçue - status: ${response.statusCode}');
    if (kDebugMode) debugPrint('🌐 [AuthRemoteDataSource] Données: ${response.data}');

    final json = _safeData(response.data);
    return AuthResponseModel.fromJson(json['data'] ?? json);
  }

  @override
  Future<AuthResponseModel> register({
    required String name,
    required String pName,
    required String email,
    required String phone,
    required String password,
    required String licenseNumber,
    required String city,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    // Normaliser l'email en minuscules pour éviter les problèmes de case sensitivity
    final normalizedEmail = email.toLowerCase().trim();
    
    final response = await apiClient.post(
      '/auth/register/pharmacy',
      data: {
        'name': name,
        'pharmacy_name': pName,
        'pharmacy_license': licenseNumber,
        'pharmacy_address': address,
        'city': city,
        'email': normalizedEmail,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'role': 'pharmacy',
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    final json = _safeData(response.data);
    return AuthResponseModel.fromJson(json['data'] ?? json);
  }

  @override
  Future<void> logout(String token) async {
    await apiClient.post(
      '/auth/logout',
      options: apiClient.authorizedOptions(token),
    );
  }

  @override
  Future<UserModel> getCurrentUser(String token) async {
    final response = await apiClient.get(
      '/auth/me',
      options: apiClient.authorizedOptions(token),
    );

    final json = _safeData(response.data);
    return UserModel.fromJson(json['data'] ?? json);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await apiClient.post(
      '/auth/forgot-password',
      data: {'email': email.toLowerCase().trim()},
    );
  }

  @override
  Future<AuthResponseModel> refreshSession({required String token}) async {
    if (kDebugMode) debugPrint('🌐 [AuthRemoteDataSource] refreshSession() - Validation du token...');
    
    // Utiliser /auth/me pour valider le token et récupérer les données utilisateur
    final response = await apiClient.get(
      '/auth/me',
      options: apiClient.authorizedOptions(token),
    );

    if (kDebugMode) debugPrint('🌐 [AuthRemoteDataSource] Token valide, session restaurée');

    final json = _safeData(response.data);
    final user = UserModel.fromJson(json['data'] ?? json);
    
    // Construire AuthResponseModel avec le token existant
    return AuthResponseModel(
      token: token,
      user: user,
    );
  }
}
