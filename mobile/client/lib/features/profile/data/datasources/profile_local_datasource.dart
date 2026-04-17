import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/app_logger.dart';
import '../models/profile_model.dart';

/// Datasource locale pour le profil utilisateur — SharedPreferences
class ProfileLocalDataSource {
  static const String _profileKey = 'cached_user_profile';

  /// Met en cache le profil utilisateur
  Future<void> cacheProfile(ProfileModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    } catch (e) {
      AppLogger.warning('ProfileLocalDataSource.cacheProfile failed: $e');
    }
  }

  /// Récupère le profil depuis le cache, null si absent ou invalide
  Future<ProfileModel?> getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_profileKey);
      if (data == null) return null;
      return ProfileModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (e) {
      AppLogger.warning('ProfileLocalDataSource.getCachedProfile failed: $e');
      return null;
    }
  }

  /// Supprime le profil du cache (ex: lors de la déconnexion)
  Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
    } catch (e) {
      AppLogger.warning('ProfileLocalDataSource.clearProfile failed: $e');
    }
  }
}
