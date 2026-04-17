import 'dart:io';
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
import '../../core/utils/safe_json_utils.dart';
import '../../core/utils/app_exceptions.dart';
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
      final responseData = SafeJsonUtils.safeMap(response.data);
      final data = responseData['data'] ?? responseData;

      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Token manquant dans la réponse du serveur.');
      }
      await SecureTokenService.instance.setToken(token);

      // Stocker le refresh token s'il est présent
      final refreshToken = data['refresh_token'] as String?;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await SecureTokenService.instance.setRefreshToken(refreshToken);
      }

      // Authentifier auprès de Firebase avec le custom token (pour Firestore)
      final firebaseToken = data['firebase_token'] as String?;
      if (firebaseToken != null) {
        try {
          final firebaseAuth = FirebaseAuthService();
          await firebaseAuth.signInWithCustomToken(firebaseToken);
        } catch (firebaseError) {
          // Rollback : supprimer le token Sanctum pour éviter un état semi-connecté
          await SecureTokenService.instance.removeToken();
          if (kDebugMode) {
            debugPrint(
              '❌ [Auth] Firebase auth failed, token rolled back: $firebaseError',
            );
          }
          throw Exception('Connexion Firebase échouée. Veuillez réessayer.');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [Auth] Pas de firebase_token dans la réponse login');
        }
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
        final data = SafeJsonUtils.safeMap(e.response?.data);
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
        throw Exception(
          'Connexion au serveur impossible. Vérifiez votre connexion internet.',
        );
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Email ou mot de passe incorrect');
      }
      if (e.response?.statusCode == 500) {
        throw Exception('Erreur serveur. Réessayez plus tard.');
      }
      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur de connexion',
        ),
      );
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

  /// Rafraîchir le token d'authentification via le refresh token.
  /// Retourne `true` si le refresh a réussi, `false` sinon.
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await SecureTokenService.instance.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      final responseData = SafeJsonUtils.safeMap(response.data);
      final data = responseData['data'] ?? responseData;

      final newToken = data['token'] as String?;
      if (newToken == null || newToken.isEmpty) return false;

      await SecureTokenService.instance.setToken(newToken);

      final newRefreshToken = data['refresh_token'] as String?;
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await SecureTokenService.instance.setRefreshToken(newRefreshToken);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Auth] Token refresh failed: $e');
      }
      return false;
    }
  }

  /// Demander la réinitialisation du mot de passe
  Future<void> forgotPassword(String email) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      await _dio.post(
        ApiConstants.forgotPassword,
        data: {'email': normalizedEmail},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = SafeJsonUtils.safeMap(e.response?.data);
        if (data.containsKey('message')) {
          throw Exception(data['message']);
        }
        throw Exception('Aucun compte trouvé avec cet email.');
      }
      if (e.response?.statusCode == 429) {
        throw Exception(
          'Trop de tentatives. Veuillez patienter quelques minutes.',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connexion impossible. Vérifiez votre connexion internet.',
        );
      }
      throw Exception('Erreur lors de l\'envoi. Veuillez réessayer.');
    }
  }

  /// Inscription d'un nouveau coursier avec documents KYC (recto/verso)
  Future<User> registerCourier({
    required String name,
    String? email,
    required String phone,
    required String password,
    required String vehicleType,
    required String vehicleRegistration,
    String? licenseNumber,
    File? idCardFrontImage, // CNI Recto
    File? idCardBackImage, // CNI Verso
    File? selfieImage,
    File? drivingLicenseFrontImage, // Permis Recto
    File? drivingLicenseBackImage, // Permis Verso
  }) async {
    try {
      // Normaliser l'email en minuscules pour éviter les problèmes de case sensitivity
      // Créer le FormData pour l'upload multipart
      final formData = FormData.fromMap({
        'name': name,
        if (email != null && email.trim().isNotEmpty)
          'email': email.toLowerCase().trim(),
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
            filename:
                'id_card_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        // CNI Verso
        if (idCardBackImage != null)
          'id_card_back_document': await MultipartFile.fromFile(
            idCardBackImage.path,
            filename:
                'id_card_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
            filename:
                'license_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        // Permis Verso
        if (drivingLicenseBackImage != null)
          'driving_license_back_document': await MultipartFile.fromFile(
            drivingLicenseBackImage.path,
            filename:
                'license_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      });

      final response = await _dio.post(
        ApiConstants.registerCourier,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final responseData = SafeJsonUtils.safeMap(response.data);

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
        final data = SafeJsonUtils.safeMap(e.response?.data);
        // Handle 422 validation errors with specific field messages
        if (e.response?.statusCode == 422 && data.containsKey('errors')) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError.first);
          }
        }
        if (data.containsKey('message') &&
            data['message'] != null &&
            data['message'].toString().isNotEmpty) {
          throw Exception(data['message']);
        }
      }
      // Map status codes to French error messages
      final statusCode = e.response?.statusCode;
      if (statusCode == 500) {
        throw Exception(
          'Erreur serveur temporaire. Veuillez réessayer dans quelques instants.',
        );
      } else if (statusCode == 503) {
        throw Exception(
          'Service temporairement indisponible. Veuillez réessayer.',
        );
      } else if (statusCode == 413) {
        throw Exception(
          'Les fichiers sont trop volumineux. Réduisez la taille des images.',
        );
      } else if (statusCode == 408 ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Délai d\'attente dépassé. Vérifiez votre connexion et réessayez.',
        );
      }
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage:
              'Inscription échouée. Vérifiez les informations saisies.',
        ),
      );
    } catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Inscription échouée',
        ),
      );
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
      final responseData = SafeJsonUtils.safeMap(response.data);
      final data = responseData['data'] ?? responseData;

      // Vérifier le statut du coursier
      if (data['courier'] != null) {
        final courierStatus = data['courier']['status'];

        // pending_approval et incomplete_kyc → laisser passer, le dashboard gère
        // Seuls les comptes suspendus/rejetés sont bloqués
        if (courierStatus == 'suspended') {
          await SecureTokenService.instance.removeToken();
          throw Exception(
            'SUSPENDED:Votre compte a été suspendu. Veuillez contacter le support.',
          );
        }
        if (courierStatus == 'rejected') {
          await SecureTokenService.instance.removeToken();
          throw Exception(
            'REJECTED:Votre demande d\'inscription a été refusée.',
          );
        }
      }

      // Sauvegarder dans le cache
      if (data is Map<String, dynamic>) {
        await cache.cacheProfile(data);
      }

      return User.fromJson(
        data is Map<String, dynamic> ? data : <String, dynamic>{},
      );
    } catch (e) {
      // Re-throw typed courier status exceptions without wrapping
      if (e is IncompleteKycException || e is PendingApprovalException) {
        rethrow;
      }
      final msg = e.toString();
      if (msg.contains('SUSPENDED') || msg.contains('REJECTED')) {
        rethrow;
      }
      throw Exception(ErrorHandler.getProfileErrorMessage(e));
    }
  }

  /// Mettre à jour le profil utilisateur (nom, téléphone, etc.)
  Future<User> updateProfile({String? name, String? phone}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null && name.isNotEmpty) data['name'] = name;
      if (phone != null && phone.isNotEmpty) data['phone'] = phone;

      if (data.isEmpty) {
        throw Exception('Aucune donnée à mettre à jour');
      }

      final response = await _dio.post(ApiConstants.updateMe, data: data);

      // Handle wrapped response structure
      final responseData = response.data;
      final userData = responseData['data'] ?? responseData;

      // Invalider le cache profil après mise à jour
      await CacheService.instance.invalidateProfile();

      return User.fromJson(userData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = SafeJsonUtils.safeMap(e.response?.data);
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
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors de la mise à jour du profil',
        ),
      );
    }
  }

  /// Upload avatar image
  Future<String> uploadAvatar(Uint8List imageBytes) async {
    try {
      final formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(imageBytes, filename: 'avatar.jpg'),
      });

      final response = await _dio.post(
        ApiConstants.uploadAvatar,
        data: formData,
      );

      await CacheService.instance.invalidateProfile();

      final path = response.data['data']?['avatar_url'] as String? ?? '';
      if (path.isEmpty) return '';
      if (path.startsWith('http')) return path;
      return '${ApiConstants.baseUrl}$path';
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception(
          'Image invalide. Formats acceptés : JPG, PNG, WEBP (max 2 Mo)',
        );
      }
      throw Exception('Erreur lors de l\'envoi de la photo');
    } catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors de l\'envoi de la photo',
        ),
      );
    }
  }

  /// Delete avatar
  Future<void> deleteAvatar() async {
    try {
      await _dio.delete(ApiConstants.deleteAvatar);
      await CacheService.instance.invalidateProfile();
    } catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors de la suppression de la photo',
        ),
      );
    }
  }

  /// Obtenir le statut KYC du coursier
  Future<Map<String, dynamic>> getKycStatus() async {
    try {
      final response = await _dio.get('/courier/kyc/status');
      final responseData = SafeJsonUtils.safeMap(response.data);
      return responseData['data'] ?? responseData;
    } catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors de la récupération du statut KYC',
        ),
      );
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
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (idCardFrontImage != null)
          'id_card_front_document': await MultipartFile.fromFile(
            idCardFrontImage.path,
            filename:
                'id_card_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        if (idCardBackImage != null)
          'id_card_back_document': await MultipartFile.fromFile(
            idCardBackImage.path,
            filename:
                'id_card_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        if (selfieImage != null)
          'selfie_document': await MultipartFile.fromFile(
            selfieImage.path,
            filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        if (drivingLicenseFrontImage != null)
          'driving_license_front_document': await MultipartFile.fromFile(
            drivingLicenseFrontImage.path,
            filename:
                'license_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        if (drivingLicenseBackImage != null)
          'driving_license_back_document': await MultipartFile.fromFile(
            drivingLicenseBackImage.path,
            filename:
                'license_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        if (vehicleRegistrationImage != null)
          'vehicle_registration_document': await MultipartFile.fromFile(
            vehicleRegistrationImage.path,
            filename:
                'vehicle_reg_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      });

      final response = await _dio.post(
        '/courier/kyc/resubmit',
        data: formData,
        onSendProgress: onSendProgress,
      );

      final responseData = SafeJsonUtils.safeMap(response.data);
      return responseData['data'] ?? responseData;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors de la soumission des documents',
        ),
      );
    } catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors de la soumission des documents',
        ),
      );
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
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Firebase signout error: $e');
      }

      await SecureTokenService.instance.removeToken();
      await SecureTokenService.instance.removeRefreshToken();
      // Vider tout le cache applicatif
      await CacheService.instance.clearAll();
      // Ne pas effacer les credentials biométriques pour permettre reconnexion rapide
      // Pour les effacer complètement: await clearStoredCredentials();
    }
  }

  /// Demande la suppression du compte (Loi 2013-450 CI — droit à l'effacement)
  Future<void> deleteAccount() async {
    await _dio.delete('/api/courier/account');
    await logout();
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _dio.post(
        ApiConstants.updatePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );
    } catch (e) {
      // Extract specific message if possible (Laravel validation errors)
      if (e is DioException && e.response?.data != null) {
        final data = SafeJsonUtils.safeMap(e.response?.data);
        if (data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Impossible de modifier le mot de passe.',
        ),
      );
    }
  }

  // ── OTP / Phone Authentication ──────────────────────

  /// Envoyer un OTP au numéro de téléphone (inscription ou connexion)
  /// [identifier] peut être un email ou un téléphone
  /// [purpose] : 'verification' | 'login' | 'password_reset'
  /// [forceFallback] : forcer l'envoi direct par SMS (bypass Firebase)
  Future<Map<String, dynamic>> sendOtp(
    String identifier, {
    String purpose = 'verification',
    bool forceFallback = true,
  }) async {
    try {
      debugPrint(
        '[sendOtp] POST ${ApiConstants.baseUrl}${ApiConstants.resendOtp} '
        'identifier=$identifier, purpose=$purpose, forceFallback=$forceFallback',
      );
      final response = await _dio.post(
        ApiConstants.resendOtp,
        data: {
          'identifier': identifier.trim(),
          'purpose': purpose,
          if (forceFallback) 'force_fallback': true,
        },
      );
      debugPrint('[sendOtp] Réponse: ${response.statusCode} ${response.data}');
      final responseData = SafeJsonUtils.safeMap(response.data);
      return responseData['data'] ?? responseData;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception(
          'Ce numéro n\'est pas enregistré. Veuillez créer un compte.',
        );
      }
      if (e.response?.statusCode == 429) {
        throw Exception(
          'Trop de tentatives. Veuillez patienter quelques minutes.',
        );
      }
      if (e.response?.statusCode == 422) {
        final data = SafeJsonUtils.safeMap(e.response?.data);
        throw Exception(data['message'] ?? 'Numéro de téléphone invalide.');
      }
      // Message d'erreur du serveur si disponible
      if (e.response?.data != null) {
        final data = SafeJsonUtils.safeMap(e.response?.data);
        final serverMsg = data['message'] as String?;
        if (serverMsg != null && serverMsg.isNotEmpty) {
          throw Exception(serverMsg);
        }
      }
      // Erreurs réseau spécifiques
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception(
            'Délai de connexion dépassé. Vérifiez votre connexion internet.',
          );
        case DioExceptionType.connectionError:
          throw Exception(
            'Impossible de joindre le serveur. Vérifiez votre connexion internet.',
          );
        default:
          final statusCode = e.response?.statusCode;
          debugPrint(
            '[sendOtp] DioException: type=${e.type}, '
            'status=$statusCode, message=${e.message}',
          );
          throw Exception(
            'Erreur lors de l\'envoi du code (${statusCode ?? 'réseau'}). Réessayez.',
          );
      }
    }
  }

  /// Vérifier un OTP et obtenir un token d'authentification
  /// Retourne un User si le code est valide.
  /// [firebaseUid] optionnel : passé si Firebase Phone Auth a déjà vérifié.
  Future<User> verifyOtp(
    String identifier,
    String otp, {
    String? firebaseUid,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtp,
        data: {
          'identifier': identifier.trim(),
          'otp': otp.trim(),
          'role': 'courier',
          'device_name': 'courier-app',
          // ignore: use_null_aware_elements
          if (firebaseUid != null) 'firebase_uid': firebaseUid,
        },
      );

      final responseData = SafeJsonUtils.safeMap(response.data);
      final data = responseData['data'] ?? responseData;

      // Stocker le token si fourni (vérification post-inscription)
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await SecureTokenService.instance.setToken(token);

        // Firebase auth si disponible
        final firebaseToken = data['firebase_token'] as String?;
        if (firebaseToken != null) {
          try {
            final firebaseAuth = FirebaseAuthService();
            await firebaseAuth.signInWithCustomToken(firebaseToken);
          } catch (firebaseError) {
            if (kDebugMode) {
              debugPrint('⚠️ [Auth] Firebase auth after OTP: $firebaseError');
            }
          }
        }

        await _markBiometricCredentialsAvailable();
      }

      final userData = data['user'];
      if (userData != null && userData is Map<String, dynamic>) {
        return User.fromJson(userData);
      }

      // Si pas de user dans la réponse, récupérer le profil
      return getProfile();
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = SafeJsonUtils.safeMap(e.response?.data);
        throw Exception(data['message'] ?? 'Code invalide ou expiré.');
      }
      if (e.response?.statusCode == 429) {
        throw Exception('Trop de tentatives. Veuillez patienter.');
      }
      throw Exception('Erreur de vérification. Réessayez.');
    }
  }

  /// Demander un OTP de réinitialisation de mot de passe par téléphone
  Future<void> forgotPasswordByPhone(String phone) async {
    try {
      await _dio.post(
        ApiConstants.forgotPassword,
        data: {'identifier': phone.trim(), 'channel': 'sms'},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = SafeJsonUtils.safeMap(e.response?.data);
        throw Exception(data['message'] ?? 'Aucun compte associé à ce numéro.');
      }
      if (e.response?.statusCode == 429) {
        throw Exception(
          'Trop de tentatives. Veuillez patienter quelques minutes.',
        );
      }
      throw Exception('Erreur lors de l\'envoi. Réessayez.');
    }
  }

  /// Vérifier l'OTP de réinitialisation
  Future<String> verifyResetOtp(String identifier, String otp) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyResetOtp,
        data: {'identifier': identifier.trim(), 'otp': otp.trim()},
      );
      final responseData = SafeJsonUtils.safeMap(response.data);
      final data = responseData['data'] ?? responseData;
      // Retourne un reset_token temporaire
      return data['reset_token'] as String? ?? '';
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = SafeJsonUtils.safeMap(e.response?.data);
        throw Exception(data['message'] ?? 'Code invalide ou expiré.');
      }
      throw Exception('Erreur de vérification. Réessayez.');
    }
  }

  /// Réinitialiser le mot de passe avec le reset_token obtenu via OTP
  Future<void> resetPasswordWithToken(
    String resetToken,
    String newPassword,
  ) async {
    try {
      await _dio.post(
        ApiConstants.resetPassword,
        data: {
          'reset_token': resetToken,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = SafeJsonUtils.safeMap(e.response?.data);
        throw Exception(data['message'] ?? 'Réinitialisation échouée.');
      }
      throw Exception('Erreur lors de la réinitialisation. Réessayez.');
    }
  }
}
