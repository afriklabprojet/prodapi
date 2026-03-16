import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service centralisé pour le chiffrement des boxes Hive.
///
/// Génère une clé AES-256 stockée dans FlutterSecureStorage
/// et la fournit pour ouvrir les boxes Hive chiffrées.
class EncryptedStorageService {
  EncryptedStorageService._();
  static final EncryptedStorageService instance = EncryptedStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _hiveEncryptionKeyKey = 'hive_encryption_key';

  HiveCipher? _cipher;
  bool _initialized = false;

  /// Initialiser Hive avec le chiffrement.
  /// Doit être appelé une fois au démarrage (dans SplashScreen).
  Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();
    _cipher = HiveAesCipher(await _getOrCreateEncryptionKey());
    _initialized = true;

    if (kDebugMode) debugPrint('🔐 [EncryptedStorage] Hive chiffré initialisé');
  }

  /// Obtenir le cipher pour ouvrir des boxes chiffrées.
  HiveCipher get cipher {
    assert(_initialized, 'EncryptedStorageService.initialize() doit être appelé avant utilisation.');
    return _cipher!;
  }

  /// Ouvrir une box Hive chiffrée.
  Future<Box<String>> openEncryptedBox(String name) async {
    if (!_initialized) await initialize();
    return Hive.openBox<String>(name, encryptionCipher: _cipher!);
  }

  /// Obtenir ou générer la clé de chiffrement AES-256.
  Future<Uint8List> _getOrCreateEncryptionKey() async {
    final existing = await _storage.read(key: _hiveEncryptionKeyKey);

    if (existing != null) {
      try {
        final bytes = base64Decode(existing);
        if (bytes.length == 32) return bytes;
      } catch (_) {
        // Clé corrompue, en régénérer une
      }
    }

    // Générer une nouvelle clé AES-256 (32 bytes)
    final key = Uint8List(32);
    final random = Random.secure();
    for (int i = 0; i < 32; i++) {
      key[i] = random.nextInt(256);
    }

    await _storage.write(
      key: _hiveEncryptionKeyKey,
      value: base64Encode(key),
    );

    if (kDebugMode) debugPrint('🔐 [EncryptedStorage] Nouvelle clé AES-256 générée');
    return key;
  }

  /// Supprimer la clé (utilisé au logout complet / reset).
  Future<void> deleteEncryptionKey() async {
    await _storage.delete(key: _hiveEncryptionKeyKey);
    _cipher = null;
    _initialized = false;
  }
}
