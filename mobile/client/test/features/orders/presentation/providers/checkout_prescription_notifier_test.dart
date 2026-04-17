import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:drpharma_client/features/orders/presentation/providers/checkout_prescription_notifier.dart';

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

XFile _xfile(String path) => XFile(path);

void main() {
  // ─────────────────────────────────────────────────────────
  // CheckoutPrescriptionState model
  // ─────────────────────────────────────────────────────────
  group('CheckoutPrescriptionState', () {
    test('default constructor → empty images, no notes, no error', () {
      const state = CheckoutPrescriptionState();
      expect(state.images, isEmpty);
      expect(state.notes, isNull);
      expect(state.errorMessage, isNull);
      expect(state.uploadedPrescriptionId, isNull);
      expect(state.uploadedPrescriptionImage, isNull);
    });

    test('hasImages is false when images is empty', () {
      const state = CheckoutPrescriptionState();
      expect(state.hasImages, isFalse);
    });

    test('hasImages is true when images is non-empty', () {
      final state = CheckoutPrescriptionState(images: [_xfile('/a/b.jpg')]);
      expect(state.hasImages, isTrue);
    });

    test('hasValidPrescription is false when no images and no uploadedId', () {
      const state = CheckoutPrescriptionState();
      expect(state.hasValidPrescription, isFalse);
    });

    test('hasValidPrescription is true when images present', () {
      final state = CheckoutPrescriptionState(images: [_xfile('/a/b.jpg')]);
      expect(state.hasValidPrescription, isTrue);
    });

    test('hasValidPrescription is true when uploadedPrescriptionId set', () {
      const state = CheckoutPrescriptionState(uploadedPrescriptionId: 42);
      expect(state.hasValidPrescription, isTrue);
    });

    test('isAlreadyUploaded is false when uploadedPrescriptionId is null', () {
      const state = CheckoutPrescriptionState();
      expect(state.isAlreadyUploaded, isFalse);
    });

    test('isAlreadyUploaded is true when uploadedPrescriptionId is set', () {
      const state = CheckoutPrescriptionState(uploadedPrescriptionId: 99);
      expect(state.isAlreadyUploaded, isTrue);
    });

    test('copyWith images → replaces images list', () {
      const state = CheckoutPrescriptionState();
      final f = _xfile('/a.jpg');
      final next = state.copyWith(images: [f]);
      expect(next.images.length, 1);
      expect(next.images.first.path, '/a.jpg');
    });

    test('copyWith notes → sets notes', () {
      const state = CheckoutPrescriptionState();
      final next = state.copyWith(notes: 'some notes');
      expect(next.notes, 'some notes');
    });

    test('copyWith clearNotes → clears notes', () {
      const state = CheckoutPrescriptionState(notes: 'notes');
      final next = state.copyWith(clearNotes: true);
      expect(next.notes, isNull);
    });

    test('copyWith errorMessage → sets error', () {
      const state = CheckoutPrescriptionState();
      final next = state.copyWith(errorMessage: 'Upload failed');
      expect(next.errorMessage, 'Upload failed');
    });

    test('copyWith clearError → clears errorMessage', () {
      const state = CheckoutPrescriptionState(errorMessage: 'err');
      final next = state.copyWith(clearError: true);
      expect(next.errorMessage, isNull);
    });

    test('copyWith uploadedPrescriptionId/Image → sets them', () {
      const state = CheckoutPrescriptionState();
      final next = state.copyWith(
        uploadedPrescriptionId: 7,
        uploadedPrescriptionImage: 'http://img.url/1.jpg',
      );
      expect(next.uploadedPrescriptionId, 7);
      expect(next.uploadedPrescriptionImage, 'http://img.url/1.jpg');
    });

    test('copyWith clearUploaded → clears both uploadedFields', () {
      const state = CheckoutPrescriptionState(
        uploadedPrescriptionId: 7,
        uploadedPrescriptionImage: 'http://img.url/1.jpg',
      );
      final next = state.copyWith(clearUploaded: true);
      expect(next.uploadedPrescriptionId, isNull);
      expect(next.uploadedPrescriptionImage, isNull);
    });

    test('copyWith preserves unset fields', () {
      final f = _xfile('/x.jpg');
      final state = CheckoutPrescriptionState(
        images: [f],
        notes: 'n',
        uploadedPrescriptionId: 3,
      );
      final next = state.copyWith(errorMessage: 'e');
      expect(next.images.length, 1);
      expect(next.notes, 'n');
      expect(next.uploadedPrescriptionId, 3);
    });
  });

  // ─────────────────────────────────────────────────────────
  // CheckoutPrescriptionNotifier
  // ─────────────────────────────────────────────────────────
  group('CheckoutPrescriptionNotifier', () {
    late CheckoutPrescriptionNotifier notifier;

    setUp(() {
      notifier = CheckoutPrescriptionNotifier();
    });

    test('initial state is empty', () {
      expect(notifier.state.images, isEmpty);
      expect(notifier.state.notes, isNull);
      expect(notifier.state.errorMessage, isNull);
    });

    test('addImage appends one image', () {
      final f = _xfile('/a.jpg');
      notifier.addImage(f);
      expect(notifier.state.images.length, 1);
      expect(notifier.state.images.first.path, '/a.jpg');
    });

    test('addImage multiple times appends all', () {
      notifier.addImage(_xfile('/a.jpg'));
      notifier.addImage(_xfile('/b.jpg'));
      notifier.addImage(_xfile('/c.jpg'));
      expect(notifier.state.images.length, 3);
    });

    test('addImages appends a list of images', () {
      notifier.addImages([_xfile('/a.jpg'), _xfile('/b.jpg')]);
      expect(notifier.state.images.length, 2);
    });

    test('addImages preserves existing images', () {
      notifier.addImage(_xfile('/first.jpg'));
      notifier.addImages([_xfile('/a.jpg'), _xfile('/b.jpg')]);
      expect(notifier.state.images.length, 3);
    });

    test('removeImage removes by index', () {
      notifier.addImage(_xfile('/a.jpg'));
      notifier.addImage(_xfile('/b.jpg'));
      notifier.addImage(_xfile('/c.jpg'));
      notifier.removeImage(1); // removes /b.jpg
      expect(notifier.state.images.length, 2);
      expect(notifier.state.images[0].path, '/a.jpg');
      expect(notifier.state.images[1].path, '/c.jpg');
    });

    test('removeImage first element', () {
      notifier.addImage(_xfile('/a.jpg'));
      notifier.addImage(_xfile('/b.jpg'));
      notifier.removeImage(0);
      expect(notifier.state.images.length, 1);
      expect(notifier.state.images.first.path, '/b.jpg');
    });

    test('markAsUploaded sets uploadedPrescriptionId and image', () {
      notifier.markAsUploaded(42, 'http://img.url/42.jpg');
      expect(notifier.state.uploadedPrescriptionId, 42);
      expect(notifier.state.uploadedPrescriptionImage, 'http://img.url/42.jpg');
      expect(notifier.state.isAlreadyUploaded, isTrue);
    });

    test('markAsUploaded with null imageUrl sets id only', () {
      notifier.markAsUploaded(5, null);
      expect(notifier.state.uploadedPrescriptionId, 5);
      expect(notifier.state.uploadedPrescriptionImage, isNull);
    });

    test('reset clears all state back to initial', () {
      notifier.addImage(_xfile('/a.jpg'));
      notifier.markAsUploaded(1, 'http://img.url/1.jpg');
      notifier.reset();
      expect(notifier.state.images, isEmpty);
      expect(notifier.state.uploadedPrescriptionId, isNull);
      expect(notifier.state.uploadedPrescriptionImage, isNull);
      expect(notifier.state.notes, isNull);
    });

    test('hasImages becomes true after addImage', () {
      expect(notifier.state.hasImages, isFalse);
      notifier.addImage(_xfile('/a.jpg'));
      expect(notifier.state.hasImages, isTrue);
    });

    test('hasValidPrescription is true after markAsUploaded', () {
      expect(notifier.state.hasValidPrescription, isFalse);
      notifier.markAsUploaded(3, null);
      expect(notifier.state.hasValidPrescription, isTrue);
    });

    test('hasValidPrescription becomes false after reset', () {
      notifier.addImage(_xfile('/a.jpg'));
      expect(notifier.state.hasValidPrescription, isTrue);
      notifier.reset();
      expect(notifier.state.hasValidPrescription, isFalse);
    });
  });
}
