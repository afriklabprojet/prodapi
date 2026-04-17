import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/delivery_proof_service.dart';

void main() {
  group('DeliveryProof', () {
    test('default timestamp is set when null', () {
      final before = DateTime.now();
      final proof = DeliveryProof();
      final after = DateTime.now();
      expect(
        proof.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        proof.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('custom timestamp is preserved', () {
      final ts = DateTime(2024, 1, 15, 10, 30);
      final proof = DeliveryProof(timestamp: ts);
      expect(proof.timestamp, ts);
    });

    test('hasPhoto is false when photo is null', () {
      final proof = DeliveryProof();
      expect(proof.hasPhoto, false);
    });

    test('hasSignature is false when signatureBytes is null', () {
      final proof = DeliveryProof();
      expect(proof.hasSignature, false);
    });

    test('hasSignature is false when signatureBytes is empty', () {
      final proof = DeliveryProof(signatureBytes: Uint8List(0));
      expect(proof.hasSignature, false);
    });

    test('hasSignature is true when signatureBytes has data', () {
      final proof = DeliveryProof(
        signatureBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(proof.hasSignature, true);
    });

    test('isValid is false when no photo and no signature', () {
      final proof = DeliveryProof();
      expect(proof.isValid, false);
    });

    test('isValid is true when has signature only', () {
      final proof = DeliveryProof(
        signatureBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(proof.isValid, true);
    });

    test('notes are stored', () {
      final proof = DeliveryProof(notes: 'Left at door');
      expect(proof.notes, 'Left at door');
    });

    test('latitude and longitude are stored', () {
      final proof = DeliveryProof(latitude: 5.3364, longitude: -4.0267);
      expect(proof.latitude, 5.3364);
      expect(proof.longitude, -4.0267);
    });

    test('latitude and longitude default to null', () {
      final proof = DeliveryProof();
      expect(proof.latitude, isNull);
      expect(proof.longitude, isNull);
    });

    test('notes default to null', () {
      final proof = DeliveryProof();
      expect(proof.notes, isNull);
    });
  });
}
