import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/core/services/delivery_proof_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock path_provider channel to return system temp directory
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getTemporaryDirectory') {
              return Directory.systemTemp.path;
            }
            return null;
          },
        );
  });

  group('DeliveryProof', () {
    test('creates with default timestamp', () {
      final proof = DeliveryProof();
      expect(proof.photo, isNull);
      expect(proof.signatureBytes, isNull);
      expect(proof.notes, isNull);
      expect(proof.latitude, isNull);
      expect(proof.longitude, isNull);
      expect(proof.timestamp, isA<DateTime>());
    });

    test('hasPhoto returns false when no photo', () {
      final proof = DeliveryProof();
      expect(proof.hasPhoto, false);
    });

    test('hasSignature returns false when no signature', () {
      final proof = DeliveryProof();
      expect(proof.hasSignature, false);
    });

    test('hasSignature returns false for empty bytes', () {
      final proof = DeliveryProof(signatureBytes: Uint8List(0));
      expect(proof.hasSignature, false);
    });

    test('hasSignature returns true for non-empty bytes', () {
      final proof = DeliveryProof(
        signatureBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(proof.hasSignature, true);
    });

    test('isValid returns false with no photo or signature', () {
      final proof = DeliveryProof();
      expect(proof.isValid, false);
    });

    test('isValid returns true with signature only', () {
      final proof = DeliveryProof(signatureBytes: Uint8List.fromList([1, 2]));
      expect(proof.isValid, true);
    });

    test('creates with notes and coordinates', () {
      final proof = DeliveryProof(
        notes: 'Left at door',
        latitude: 5.36,
        longitude: -4.008,
      );
      expect(proof.notes, 'Left at door');
      expect(proof.latitude, 5.36);
      expect(proof.longitude, -4.008);
    });

    test('custom timestamp is used when provided', () {
      final customTime = DateTime(2024, 6, 15, 14, 30);
      final proof = DeliveryProof(timestamp: customTime);
      expect(proof.timestamp, customTime);
    });
  });

  group('DeliveryProof - extended model tests', () {
    test('creates with all fields', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final tempFile = File('/tmp/test_photo.jpg');

      final proof = DeliveryProof(
        photo: tempFile,
        signatureBytes: bytes,
        notes: 'Livré au gardien',
        timestamp: now,
        latitude: 5.3167,
        longitude: -3.9833,
      );

      expect(proof.photo, tempFile);
      expect(proof.signatureBytes, bytes);
      expect(proof.notes, 'Livré au gardien');
      expect(proof.timestamp, now);
      expect(proof.latitude, 5.3167);
      expect(proof.longitude, -3.9833);
    });

    test('isValid returns true when photo is set', () {
      final proof = DeliveryProof(photo: File('/tmp/test.jpg'));
      expect(proof.isValid, isTrue);
      expect(proof.hasPhoto, isTrue);
    });

    test('isValid returns true when both photo and signature present', () {
      final proof = DeliveryProof(
        photo: File('/tmp/test.jpg'),
        signatureBytes: Uint8List.fromList([10, 20, 30]),
      );
      expect(proof.isValid, isTrue);
      expect(proof.hasPhoto, isTrue);
      expect(proof.hasSignature, isTrue);
    });

    test('hasSignature returns true for large signature data', () {
      final proof = DeliveryProof(
        signatureBytes: Uint8List.fromList(
          List.generate(10000, (i) => i % 256),
        ),
      );
      expect(proof.hasSignature, isTrue);
    });

    test('default timestamp is close to now', () {
      final before = DateTime.now();
      final proof = DeliveryProof();
      final after = DateTime.now();
      expect(
        proof.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        proof.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('notes can be empty string', () {
      final proof = DeliveryProof(notes: '');
      expect(proof.notes, '');
    });

    test('notes can contain unicode', () {
      final proof = DeliveryProof(notes: 'Livré chez M. Koné 🏠📦');
      expect(proof.notes, contains('Koné'));
      expect(proof.notes, contains('📦'));
    });

    test('notes can be very long', () {
      final longNotes = 'A' * 5000;
      final proof = DeliveryProof(notes: longNotes);
      expect(proof.notes!.length, 5000);
    });

    test('latitude and longitude can be zero', () {
      final proof = DeliveryProof(latitude: 0.0, longitude: 0.0);
      expect(proof.latitude, 0.0);
      expect(proof.longitude, 0.0);
    });

    test('negative latitude and longitude', () {
      final proof = DeliveryProof(latitude: -33.8688, longitude: -151.2093);
      expect(proof.latitude, -33.8688);
      expect(proof.longitude, -151.2093);
    });

    test('only latitude set (longitude null)', () {
      final proof = DeliveryProof(latitude: 5.3167);
      expect(proof.latitude, 5.3167);
      expect(proof.longitude, isNull);
    });

    test('only longitude set (latitude null)', () {
      final proof = DeliveryProof(longitude: -3.9833);
      expect(proof.latitude, isNull);
      expect(proof.longitude, -3.9833);
    });

    test('proof with photo only is valid', () {
      final proof = DeliveryProof(
        photo: File('/tmp/photo.jpg'),
        notes: 'Photo only delivery',
        latitude: 5.3,
        longitude: -4.0,
      );
      expect(proof.isValid, isTrue);
      expect(proof.hasPhoto, isTrue);
      expect(proof.hasSignature, isFalse);
    });

    test('proof with notes only is not valid', () {
      final proof = DeliveryProof(
        notes: 'Only notes, no photo or signature',
        latitude: 5.3,
        longitude: -4.0,
      );
      expect(proof.isValid, isFalse);
    });

    test('proof with location only is not valid', () {
      final proof = DeliveryProof(latitude: 5.3167, longitude: -3.9833);
      expect(proof.isValid, isFalse);
    });

    test('multiple proofs have independent timestamps', () {
      final t1 = DateTime(2024, 1, 1);
      final t2 = DateTime(2024, 6, 15);
      final proof1 = DeliveryProof(timestamp: t1);
      final proof2 = DeliveryProof(timestamp: t2);
      expect(proof1.timestamp, isNot(proof2.timestamp));
      expect(proof1.timestamp.isBefore(proof2.timestamp), isTrue);
    });

    test('proof with all null optional fields', () {
      final proof = DeliveryProof();
      expect(proof.isValid, isFalse);
      expect(proof.hasPhoto, isFalse);
      expect(proof.hasSignature, isFalse);
      expect(proof.notes, isNull);
      expect(proof.latitude, isNull);
      expect(proof.longitude, isNull);
    });
  });

  group('DeliveryProofService - encodeImageToBase64', () {
    late DeliveryProofService service;

    setUp(() {
      service = DeliveryProofService(MockDio());
    });

    test('returns null for null file', () {
      final result = service.encodeImageToBase64(null);
      expect(result, isNull);
    });

    test('encodes a valid file to base64', () {
      final tempDir = Directory.systemTemp;
      final testFile = File(
        '${tempDir.path}/test_encode_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      testFile.writeAsBytesSync([72, 101, 108, 108, 111]); // "Hello"

      try {
        final result = service.encodeImageToBase64(testFile);
        expect(result, isNotNull);
        expect(result, base64Encode([72, 101, 108, 108, 111]));
        final decoded = base64Decode(result!);
        expect(decoded, [72, 101, 108, 108, 111]);
      } finally {
        testFile.deleteSync();
      }
    });

    test('returns null for non-existent file', () {
      final nonExistent = File(
        '/tmp/does_not_exist_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final result = service.encodeImageToBase64(nonExistent);
      expect(result, isNull);
    });

    test('encodes empty file to empty base64', () {
      final tempDir = Directory.systemTemp;
      final testFile = File(
        '${tempDir.path}/test_empty_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      testFile.writeAsBytesSync([]);

      try {
        final result = service.encodeImageToBase64(testFile);
        expect(result, isNotNull);
        expect(result, '');
      } finally {
        testFile.deleteSync();
      }
    });

    test('encodes binary data correctly', () {
      final tempDir = Directory.systemTemp;
      final testFile = File(
        '${tempDir.path}/test_binary_${DateTime.now().millisecondsSinceEpoch}.bin',
      );
      final bytes = List.generate(256, (i) => i);
      testFile.writeAsBytesSync(bytes);

      try {
        final result = service.encodeImageToBase64(testFile);
        expect(result, isNotNull);
        final decoded = base64Decode(result!);
        expect(decoded, bytes);
      } finally {
        testFile.deleteSync();
      }
    });
  });

  group('DeliveryProofService - decodeBase64ToFile', () {
    late DeliveryProofService service;

    setUp(() {
      service = DeliveryProofService(MockDio());
    });

    test('decodes valid base64 to file', () async {
      final originalBytes = [72, 101, 108, 108, 111]; // "Hello"
      final base64String = base64Encode(originalBytes);

      final result = await service.decodeBase64ToFile(base64String);
      expect(result, isNotNull);
      expect(result!.existsSync(), isTrue);

      final content = result.readAsBytesSync();
      expect(content, originalBytes);
      result.deleteSync();
    });

    test('returns null for invalid base64', () async {
      final result = await service.decodeBase64ToFile('not_valid_base64!!!@@@');
      expect(result, isNull);
    });

    test('decodes empty base64 to empty file', () async {
      final result = await service.decodeBase64ToFile('');
      expect(result, isNotNull);
      expect(result!.existsSync(), isTrue);
      expect(result.readAsBytesSync(), isEmpty);
      result.deleteSync();
    });

    test('decoded file has .jpg extension', () async {
      final base64String = base64Encode([1, 2, 3]);
      final result = await service.decodeBase64ToFile(base64String);
      expect(result, isNotNull);
      expect(result!.path, contains('.jpg'));
      result.deleteSync();
    });

    test('decodes large base64 data', () async {
      final largeBytes = List.generate(10000, (i) => i % 256);
      final base64String = base64Encode(largeBytes);

      final result = await service.decodeBase64ToFile(base64String);
      expect(result, isNotNull);
      expect(result!.readAsBytesSync(), largeBytes);
      result.deleteSync();
    });
  });

  group('DeliveryProofService - saveSignatureToFile', () {
    late DeliveryProofService service;

    setUp(() {
      service = DeliveryProofService(MockDio());
    });

    test('saves bytes to a file', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = await service.saveSignatureToFile(bytes);
      expect(result, isNotNull);
      expect(result!.existsSync(), isTrue);
      expect(result.readAsBytesSync(), [1, 2, 3, 4, 5]);
      expect(result.path, contains('signature_'));
      expect(result.path, contains('.png'));
      result.deleteSync();
    });

    test('saves empty bytes', () async {
      final bytes = Uint8List(0);
      final result = await service.saveSignatureToFile(bytes);
      expect(result, isNotNull);
      expect(result!.existsSync(), isTrue);
      expect(result.readAsBytesSync(), isEmpty);
      result.deleteSync();
    });

    test('saves large signature data', () async {
      final bytes = Uint8List.fromList(List.generate(50000, (i) => i % 256));
      final result = await service.saveSignatureToFile(bytes);
      expect(result, isNotNull);
      expect(result!.readAsBytesSync().length, 50000);
      result.deleteSync();
    });

    test('each save creates a unique file', () async {
      final bytes1 = Uint8List.fromList([1, 2, 3]);
      final bytes2 = Uint8List.fromList([4, 5, 6]);

      final result1 = await service.saveSignatureToFile(bytes1);
      // Small delay to ensure different millisecondsSinceEpoch
      await Future.delayed(const Duration(milliseconds: 2));
      final result2 = await service.saveSignatureToFile(bytes2);

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1!.path, isNot(result2!.path));
      expect(result1.readAsBytesSync(), [1, 2, 3]);
      expect(result2.readAsBytesSync(), [4, 5, 6]);

      result1.deleteSync();
      result2.deleteSync();
    });
  });

  group('DeliveryProofService - roundtrip encode/decode', () {
    late DeliveryProofService service;

    setUp(() {
      service = DeliveryProofService(MockDio());
    });

    test('encode then decode preserves data', () async {
      final tempDir = Directory.systemTemp;
      final originalFile = File(
        '${tempDir.path}/roundtrip_test_${DateTime.now().millisecondsSinceEpoch}.bin',
      );
      final originalBytes = List.generate(500, (i) => (i * 7) % 256);
      originalFile.writeAsBytesSync(originalBytes);

      try {
        final encoded = service.encodeImageToBase64(originalFile);
        expect(encoded, isNotNull);

        final decoded = await service.decodeBase64ToFile(encoded!);
        expect(decoded, isNotNull);

        final decodedBytes = decoded!.readAsBytesSync();
        expect(decodedBytes, originalBytes);

        decoded.deleteSync();
      } finally {
        originalFile.deleteSync();
      }
    });
  });
}
