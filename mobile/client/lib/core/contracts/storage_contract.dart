/// Contract pour le stockage local
/// Abstrait SharedPreferences, Hive, SQLite, etc.
abstract class StorageContract {
  /// Initialiser le storage (si nécessaire)
  Future<void> init();

  // ─────────────────────────────────────────────────────────
  // Primitives
  // ─────────────────────────────────────────────────────────

  Future<String?> getString(String key);
  Future<void> setString(String key, String value);

  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);

  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);

  Future<double?> getDouble(String key);
  Future<void> setDouble(String key, double value);

  // ─────────────────────────────────────────────────────────
  // Collections
  // ─────────────────────────────────────────────────────────

  Future<List<String>?> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);

  // ─────────────────────────────────────────────────────────
  // JSON objects
  // ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> setJson(String key, Map<String, dynamic> value);

  // ─────────────────────────────────────────────────────────
  // Management
  // ─────────────────────────────────────────────────────────

  Future<void> remove(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);
  Future<Set<String>> getKeys();
}

/// Contract pour le stockage sécurisé (credentials, tokens)
abstract class SecureStorageContract {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<Map<String, String>> readAll();
}
