import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/prescriptions/data/models/prescription_model.dart';
import 'package:drpharma_client/features/prescriptions/domain/entities/prescription_entity.dart';

// ────────────────────────────────────────────────────────────────────────────
// JSON helpers
// ────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _prescriptionJson({
  int id = 1,
  String status = 'pending',
  String? notes,
  List<dynamic>? images,
  String? rejectionReason,
  dynamic quoteAmount,
  String? pharmacyNotes,
  String createdAt = '2024-06-01T10:00:00.000Z',
  String? validatedAt,
  int? orderId,
  String? orderReference,
  String? source,
  String fulfillmentStatus = 'none',
  int dispensingCount = 0,
}) => <String, dynamic>{
  'id': id,
  'status': status,
  if (notes != null) 'notes': notes,
  'images': images ?? <dynamic>[],
  if (rejectionReason != null) 'rejection_reason': rejectionReason,
  if (quoteAmount != null) 'quote_amount': quoteAmount,
  if (pharmacyNotes != null) 'pharmacy_notes': pharmacyNotes,
  'created_at': createdAt,
  if (validatedAt != null) 'validated_at': validatedAt,
  if (orderId != null) 'order_id': orderId,
  if (orderReference != null) 'order_reference': orderReference,
  if (source != null) 'source': source,
  'fulfillment_status': fulfillmentStatus,
  'dispensing_count': dispensingCount,
};

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // PrescriptionModel.fromJson
  // ────────────────────────────────────────────────────────────────────────────
  group('PrescriptionModel', () {
    group('fromJson — standard cases', () {
      test('parses required fields', () {
        final model = PrescriptionModel.fromJson(_prescriptionJson());
        expect(model.id, 1);
        expect(model.status, 'pending');
        expect(model.images, isEmpty);
        expect(model.fulfillmentStatus, 'none');
        expect(model.dispensingCount, 0);
      });

      test('parses notes', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(notes: 'Ordonnance médicale'),
        );
        expect(model.notes, 'Ordonnance médicale');
      });

      test('parses rejection_reason', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(
            status: 'rejected',
            rejectionReason: 'Ordonnance illisible',
          ),
        );
        expect(model.rejectionReason, 'Ordonnance illisible');
      });

      test('parses quote_amount as double', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(quoteAmount: 7500.0),
        );
        expect(model.quoteAmount, 7500.0);
      });

      test('parses quote_amount as String', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(quoteAmount: '3500.50'),
        );
        expect(model.quoteAmount, 3500.50);
      });

      test('parses pharmacy_notes', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(pharmacyNotes: 'Disponible en stock'),
        );
        expect(model.pharmacyNotes, 'Disponible en stock');
      });

      test('parses validatedAt', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(validatedAt: '2024-06-05T12:00:00.000Z'),
        );
        expect(model.validatedAt, '2024-06-05T12:00:00.000Z');
      });

      test('parses orderId and orderReference', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(orderId: 42, orderReference: 'ORD-2024-042'),
        );
        expect(model.orderId, 42);
        expect(model.orderReference, 'ORD-2024-042');
      });

      test('parses source', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(source: 'app'),
        );
        expect(model.source, 'app');
      });

      test('parses dispensingCount', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(dispensingCount: 2),
        );
        expect(model.dispensingCount, 2);
      });
    });

    group('fromJson — images polymorphism', () {
      test('parses images as list of strings', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(
            images: [
              'https://cdn.example.com/rx1.jpg',
              'https://cdn.example.com/rx2.jpg',
            ],
          ),
        );
        expect(model.images.length, 2);
        expect(model.images.first, 'https://cdn.example.com/rx1.jpg');
      });

      test('parses images as list of maps with url key', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(
            images: [
              <String, dynamic>{
                'url': 'https://server.com/prescrip/1.jpg',
                'id': 10,
              },
              <String, dynamic>{
                'url': 'https://server.com/prescrip/2.jpg',
                'id': 11,
              },
            ],
          ),
        );
        expect(model.images.length, 2);
        expect(model.images[1], 'https://server.com/prescrip/2.jpg');
      });

      test('accepts empty images list', () {
        final model = PrescriptionModel.fromJson(_prescriptionJson(images: []));
        expect(model.images, isEmpty);
      });

      test('ignores map entries without url key', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(
            images: [
              <String, dynamic>{'path': 'no_url.jpg'},
            ],
          ),
        );
        expect(model.images, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final model = PrescriptionModel.fromJson(
          _prescriptionJson(
            notes: 'Test note',
            orderId: 5,
            quoteAmount: 1200.0,
          ),
        );
        final json = model.toJson();

        expect(json['id'], 1);
        expect(json['status'], 'pending');
        expect(json['notes'], 'Test note');
        expect(json['order_id'], 5);
        expect(json['quote_amount'], 1200.0);
        expect(json['fulfillment_status'], 'none');
      });
    });

    group('toEntity', () {
      test('converts to PrescriptionEntity', () {
        final entity = PrescriptionModel.fromJson(
          _prescriptionJson(),
        ).toEntity();
        expect(entity, isA<PrescriptionEntity>());
        expect(entity.id, 1);
        expect(entity.status, 'pending');
      });

      test('parses createdAt date', () {
        final entity = PrescriptionModel.fromJson(
          _prescriptionJson(),
        ).toEntity();
        expect(entity.createdAt, DateTime.parse('2024-06-01T10:00:00.000Z'));
      });

      test('parses validatedAt date', () {
        final entity = PrescriptionModel.fromJson(
          _prescriptionJson(validatedAt: '2024-06-05T12:00:00.000Z'),
        ).toEntity();
        expect(entity.validatedAt, DateTime.parse('2024-06-05T12:00:00.000Z'));
      });

      test('imageUrls passes through', () {
        final entity = PrescriptionModel.fromJson(
          _prescriptionJson(images: ['url1', 'url2']),
        ).toEntity();
        expect(entity.imageUrls, ['url1', 'url2']);
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // PrescriptionEntity computed properties
  // ────────────────────────────────────────────────────────────────────────────
  group('PrescriptionEntity', () {
    PrescriptionEntity _make({
      String status = 'pending',
      String fulfillmentStatus = 'none',
      double? quoteAmount,
    }) => PrescriptionEntity(
      id: 1,
      status: status,
      imageUrls: const [],
      fulfillmentStatus: fulfillmentStatus,
      quoteAmount: quoteAmount,
      createdAt: DateTime(2024),
    );

    test('isPending is true for pending status', () {
      expect(_make(status: 'pending').isPending, isTrue);
    });

    test('isValidated is true for validated status', () {
      expect(_make(status: 'validated').isValidated, isTrue);
    });

    test('isRejected is true for rejected status', () {
      expect(_make(status: 'rejected').isRejected, isTrue);
    });

    test('hasQuote is true when quoteAmount > 0', () {
      expect(_make(quoteAmount: 5000.0).hasQuote, isTrue);
    });

    test('hasQuote is false when quoteAmount is null', () {
      expect(_make().hasQuote, isFalse);
    });

    test('isLinkedToOrder requires orderId', () {
      final withOrder = PrescriptionEntity(
        id: 1,
        status: 'validated',
        imageUrls: const [],
        createdAt: DateTime(2024),
        orderId: 10,
      );
      final withoutOrder = PrescriptionEntity(
        id: 2,
        status: 'pending',
        imageUrls: const [],
        createdAt: DateTime(2024),
      );
      expect(withOrder.isLinkedToOrder, isTrue);
      expect(withoutOrder.isLinkedToOrder, isFalse);
    });

    test('isFullyDispensed', () {
      expect(_make(fulfillmentStatus: 'full').isFullyDispensed, isTrue);
    });

    test('isPartiallyDispensed', () {
      expect(_make(fulfillmentStatus: 'partial').isPartiallyDispensed, isTrue);
    });

    test('statusLabel — all values', () {
      expect(_make(status: 'pending').statusLabel, 'En attente');
      expect(_make(status: 'validated').statusLabel, 'Validée');
      expect(_make(status: 'rejected').statusLabel, 'Rejetée');
      expect(_make(status: 'quoted').statusLabel, 'Devis envoyé');
      expect(_make(status: 'custom_xyz').statusLabel, 'custom_xyz');
    });
  });
}
