import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Data source locale pour l'authentification (cache token/user)
abstract class AuthLocalDataSource {
  Future<String?> getCachedToken();
  Future<void> cacheToken(String token);
  Future<void> clearToken();
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user';
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<String?> getCachedToken() async {
    return sharedPreferences.getString(_tokenKey);
  }

  @override
  Future<void> cacheToken(String token) async {
    await sharedPreferences.setString(_tokenKey, token);
  }

  @override
  Future<void> clearToken() async {
    await sharedPreferences.remove(_tokenKey);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final userJson = sharedPreferences.getString(_userKey);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await sharedPreferences.setString(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearUser() async {
    await sharedPreferences.remove(_userKey);
  }
}
