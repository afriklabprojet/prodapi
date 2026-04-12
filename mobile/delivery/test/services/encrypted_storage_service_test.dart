import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/encrypted_storage_service.dart';

void main() {
  group('EncryptedStorageService', () {
    test('singleton returns same instance', () {
      final s1 = EncryptedStorageService.instance;
      final s2 = EncryptedStorageService.instance;
      expect(identical(s1, s2), true);
    });

    test('instance is not null', () {
      expect(EncryptedStorageService.instance, isNotNull);
    });

    test('instance is of correct type', () {
      expect(EncryptedStorageService.instance, isA<EncryptedStorageService>());
    });

    test('multiple accesses return same hash code', () {
      final s1 = EncryptedStorageService.instance;
      final s2 = EncryptedStorageService.instance;
      expect(s1.hashCode, s2.hashCode);
    });
  });
}
