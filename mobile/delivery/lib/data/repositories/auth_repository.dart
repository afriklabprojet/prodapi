import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/secure_token_service.dart';
import '../../core/utils/error_handler.dart';
import '../models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  final Dio _dio;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  // Clés pour le stockage sécurisé
  static const String _credentialsKey = 'biometric_credentials';

  AuthRepository(this._dio);

  /// Parse response.data qui peut être un String JSON ou un Map
  static Map<String, dynamic> _safeData(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) return parsed;
        if (parsed is Map) return Map<String, dynamic>.from(parsed);
      } catch (_) {}
    }
    return {};
  }

  Future<User> login(String email, String password) async {
    try {
      // Normaliser l'email en minuscules pour éviter les problèmes de case sensitivity
      final normalizedEmail = email.toLowerCase().trim();
      
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': normalizedEmail,
          'password': password,
          'role': 'courier', // Indiquer que c'est l'app coursier
          'device_name': 'courier-app',
        },
      );

      // Handle wrapped response structure: { success: true, data: { token: ..., user: ... } }
      final responseData = _safeData(response.data);
      final data = responseData['data'] ?? responseData;
      
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Token manquant dans la réponse du serveur.');
      }
      await SecureTokenService.instance.setToken(token);
      
      // Authentifier auprès de Firebase avec le custom token (pour Firestore)
      final firebaseToken = data['firebase_token'] as String?;
      if (firebaseToken != null) {
        try {
          final firebaseAuth = FirebaseAuthService();
          await firebaseAuth.signInWithCustomToken(firebaseToken);
        } catch (firebaseError) {
          // Rollback : supprimer le token Sanctum pour éviter un état semi-connecté
          await SecureTokenService.instance.removeToken();
          if (kDebugMode) debugPrint('❌ [Auth] Firebase auth failed, token rolled back: $firebaseError');
          throw Exception('Connexion Firebase échouée. Veuillez réessayer.');
        }
      } else {
        if (kDebugMode) debugPrint('⚠️ [Auth] Pas de firebase_token dans la réponse login');
      }
      
      // Marquer que des credentials biométriques existent (le token est déjà stocké dans SecureTokenService)
      await _markBiometricCredentialsAvailable();

      final userData = data['user'];
      if (userData == null || userData is! Map<String, dynamic>) {
        throw Exception('Données utilisateur manquantes dans la réponse.');
      }
      return User.fromJson(userData);
    } on DioException catch (e) {
      // Gérer les erreurs de validation Laravel (422)
      if (e.response?.statusCode == 422) {
        final data = _safeData(e.response?.data);
        if (data.containsKey('message')) {
          throw Exception(data['message']);
        }
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError.first);
          }
        }
        throw Exception('Identifiants incorrects');
      }
      // Erreur réseau ou serveur
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connexion au serveur impossible. Vérifiez votre connexion internet.');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Email ou mot de passe incorrect');
      }
      if (e.response?.statusCode == 500) {
        throw Exception('Erreur serveur. Réessayez plus tard.');
      }
      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Erreur de connexion'));
    }
  }
  
  /// Marquer que des credentials biométriques sont disponibles
  /// (le token est stocké dans SecureTokenService, on ne stocke plus le mot de passe)
  Future<void> _markBiometricCredentialsAvailable() async {
    await _secureStorage.write(key: _credentialsKey, value: 'token_based');
  }
  
  /// Vérifier si des credentials biométriques sont disponibles
  Future<bool> hasStoredCredentials() async {
    final marker = await _secureStorage.read(key: _credentialsKey);
    if (marker == null) return false;
    // Vérifier aussi que le token existe toujours
    return SecureTokenService.instance.hasToken();
  }
  
  /// Connexion avec le token stocké (pour biométrie)
  /// Au lieu de rejouer le mot de passe, on valide le token existant
  Future<User> loginWithStoredCredentials() async {
    final hasToken = await SecureTokenService.instance.hasToken();
    if (!hasToken) {
      throw Exception('Aucun token stocké. Veuillez vous reconnecter.');
    }
    
    // Valider le token en appelant getProfile
    // Si le token est expiré, une exception sera levée
    return getProfile();
  }
  
  /// Supprimer les credentials stockés
  Future<void> clearStoredCredentials() async {
    await _secureStorage.delete(key: _credentialsKey);
  }

  /// Inscription d'un nouveau coursier avec documents KYC (recto/verso)
  Future<User> registerCourier({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String vehicleRegistration,
    String? licenseNumber,
    File? idCardFrontImage,      // CNI Recto
    File? idCardBackImage,       // CNI Verso
    File? selfieImage,
    File? drivingLicenseFrontImage,  // Permis Recto
    File? drivingLicenseBackImage,   // Permis Verso
  }) async {
    try {
      // Normaliser l'email en minuscules pour éviter les problèmes de case sensitivity
      final normalizedEmail = email.toLowerCase().trim();
      
      // Créer le FormData pour l'upload multipart
      final formData = FormData.fromMap({
        'name': name,
        'email': normalizedEmail,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'vehicle_type': vehicleType,
        'vehicle_registration': vehicleRegistration,
        if (licenseNumber != null && licenseNumber.isNotEmpty)
          'license_number': licenseNumber,
        // CNI Recto
        if (idCardFrontImage != null)
          'id_card_front_document': await MultipartFile.fromFile(
            idCardFrontImage.path,
            filename: 'id_card_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        // CNI Verso
        if (idCardBackImage != null)
          'id_card_back_document': await MultipartFile.fromFile(
            idCardBackImage.path,
            filename: 'id_card_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        // Selfie
        if (selfieImage != null)
          'selfie_document': await MultipartFile.fromFile(
            selfieImage.path,
            filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        // Permis Recto
        if (drivingLicenseFrontImage != null)
          'driving_license_front_document': await MultipartFile.fromFile(
            drivingLicenseFrontImage.path,
            filename: 'license_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        // Permis Verso
        if (drivingLicenseBackImage != null)
          'driving_license_back_document': await MultipartFile.fromFile(
            drivingLicenseBackImage.path,
            filename: 'license_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      });

      final response = await _dio.post(
        ApiConstants.registerCourier,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final responseData = _safeData(response.data);
      
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Inscription échouée');
      }

      final data = responseData['data'];
      
      // NE PAS stocker de token pour les coursiers en attente d'approbation
      // Le coursier doit attendre l'approbation admin avant de pouvoir se connecter
      // Le token sera créé uniquement lors de la connexion après approbation

      return User.fromJson(data['user']);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final data = _safeData(e.response?.data);
        // Handle 422 validation errors with specific field messages
        if (e.response?.statusCode == 422 && data.containsKey('errors')) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError.first);
          }
        }
        if (data.containsKey('message') && data['message'] != null && data['message'].toString().isNotEmpty) {
          throw Exception(data['message']);
        }
      }
      // Map status codes to French error messages
      final statusCode = e.response?.statusCode;
      if (statusCode == 500) {
        throw Exception('Erreur serveur temporaire. Veuillez réessayer dans quelques instants.');
      } else if (statusCode == 503) {
        throw Exception('Service temporairement indisponible. Veuillez réessayer.');
      } else if (statusCode == 413) {
        throw Exception('Les fichiers sont trop volumineux. Réduisez la taille des images.');
      } else if (statusCode == 408 || e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé. Vérifiez votre connexion et réessayez.');
      }
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Inscription échouée. Vérifiez les informations saisies.'));
    } catch (e) {
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Inscription échouée'));
    }
  }

  Future<User> getProfile() async {
    // Tenter de lire le cache d'abord
    final cache = CacheService.instance;
    final cached = await cache.getCachedProfile();
    if (cached != null) {
      return User.fromJson(cached);
    }

    try {
      final response = await _dio.get(ApiConstants.me);
      final responseData = _safeData(response.data);
      final data = responseData['data'] ?? responseData;
      
      // Vérifier le statut du coursier
      if (data['courier'] != null) {
        final courierStatus = data['courier']['status'];
        final kycStatus = data['courier']['kyc_status'];
        final kycRejectionReason = data['courier']['kyc_rejection_reason'];
        
        // KYC incomplet - permettre connexion mais signaler
        if (kycStatus == 'incomplete') {
          throw Exception('INCOMPLETE_KYC:${kycRejectionReason ?? "Veuillez soumettre vos documents KYC."}');
        }
        
        if (courierStatus == 'pending_approval') {
          // Supprimer le token stocké car le coursier n'est pas encore approuvé
          await SecureTokenService.instance.removeToken();
          throw Exception('PENDING_APPROVAL:Votre compte est en attente d\'approbation par l\'administrateur.');
        }
        if (courierStatus == 'suspended') {
          await SecureTokenService.instance.removeToken();
          throw Exception('SUSPENDED:Votre compte a été suspendu. Veuillez contacter le support.');
        }
        if (courierStatus == 'rejected') {
          await SecureTokenService.instance.removeToken();
          throw Exception('REJECTED:Votre demande d\'inscription a été refusée.');
        }
      }

      // Sauvegarder dans le cache
      if (data is Map<String, dynamic>) {
        await cache.cacheProfile(data);
      }
      
      return User.fromJson(data is Map<String, dynamic> ? data : <String, dynamic>{});
    } catch (e) {
      // Re-throw courier status exceptions without wrapping
      final msg = e.toString();
      if (msg.contains('PENDING_APPROVAL') || msg.contains('SUSPENDED') || msg.contains('REJECTED') || msg.contains('INCOMPLETE_KYC')) {
        rethrow;
      }
      throw Exception(ErrorHandler.getProfileErrorMessage(e));
    }
  }

  /// Mettre à jour le profil utilisateur (nom, téléphone, etc.)
  Future<User> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null && name.isNotEmpty) data['name'] = name;
      if (phone != null && phone.isNotEmpty) data['phone'] = phone;
      
      if (data.isEmpty) {
        throw Exception('Aucune donnée à mettre à jour');
      }
      
      final response = await _dio.post(
        ApiConstants.updateMe,
        data: data,
      );
      
      // Handle wrapped response structure
      final responseData = response.data;
      final userData = responseData['data'] ?? responseData;
      
      // Invalider le cache profil après mise à jour
      await CacheService.instance.invalidateProfile();
      
      return User.fromJson(userData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = _safeData(e.response?.data);
        if (data.containsKey('message')) {
          throw Exception(data['message']);
        }
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError.first);
          }
        }
      }
      throw Exception('Erreur lors de la mise à jour: ${e.message}');
    } catch (e) {
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Erreur lors de la mise à jour du profil'));
    }
  }

  /// Obtenir le statut KYC du coursier
  Future<Map<String, dynamic>> getKycStatus() async {
    try {
      final response = await _dio.get('/api/courier/kyc/status');
      final responseData = _safeData(response.data);
      return responseData['data'] ?? responseData;
    } catch (e) {
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Erreur lors de la récupération du statut KYC'));
    }
  }

  /// Resoumettre des documents KYC
  Future<Map<String, dynamic>> resubmitKycDocuments({
    File? idCardFrontImage,
    File? idCardBackImage,
    File? selfieImage,
    File? drivingLicenseFrontImage,
    File? drivingLicenseBackImage,
    File? vehicleRegistrationImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (idCardFrontImage != null)
          'id_card_front_document': await MultipartFile.fromFile(
            idCardFrontImage.path,
            filename: 'id_card_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        if (idCardBackImage != null)
          'id_card_back_document': await MultipartFile.fromFile(
            idCardBackImage.path,
            filename: 'id_card_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        if (selfieImage != null)
          'selfie_document': await MultipartFile.fromFile(
            selfieImage.path,
            filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        if (drivingLicenseFrontImage != null)
          'driving_license_front_document': await MultipartFile.fromFile(
            drivingLicenseFrontImage.path,
            filename: 'license_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        if (drivingLicenseBackImage != null)
          'driving_license_back_document': await MultipartFile.fromFile(
            drivingLicenseBackImage.path,
            filename: 'license_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        if (vehicleRegistrationImage != null)
          'vehicle_registration_document': await MultipartFile.fromFile(
            vehicleRegistrationImage.path,
            filename: 'vehicle_reg_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      });
      
      final response = await _dio.post(
        '/api/courier/kyc/resubmit',
        data: formData,
      );
      
      final responseData = _safeData(response.data);
      return responseData['data'] ?? responseData;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Erreur lors de la soumission des documents'));
    } catch (e) {
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Erreur lors de la soumission des documents'));
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (e) {
      // Ignore network errors on logout
    } finally {
      // Déconnecter Firebase Auth (Firestore)
      try {
        final firebaseAuth = FirebaseAuthService();
        await firebaseAuth.signOut();
      } catch (_) {}
      
      await SecureTokenService.instance.removeToken();
      // Vider tout le cache applicatif
      await CacheService.instance.clearAll();
      // Ne pas effacer les credentials biométriques pour permettre reconnexion rapide
      // Pour les effacer complètement: await clearStoredCredentials();
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      await _dio.post(ApiConstants.updatePassword, data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      });
    } catch (e) {
      // Extract specific message if possible (Laravel validation errors)
      if (e is DioException && e.response?.data != null) {
         final data = _safeData(e.response?.data);
         if (data.containsKey('message')) {
            throw Exception(data['message']);
         }
      }
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Impossible de modifier le mot de passe.'));
    }
  }
}
