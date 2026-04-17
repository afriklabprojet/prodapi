import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/inventory/data/models/product_batch_model.dart';

void main() {
  group('ProductBatchModel.fromJson', () {
    test('should parse complete JSON correctly', () {
      final model = ProductBatchModel.fromJson({
        'id': 1,
        'product_id': 10,
        'product_name': 'Paracétamol 500mg',
        'batch_number': 'BATCH-001',
        'lot_number': 'LOT-A1',
        'expiry_date': '2025-06-15',
        'quantity': 200,
        'received_at': '2024-12-01',
        'supplier': 'Pharmacien CI',
      });

      expect(model.id, 1);
      expect(model.productId, 10);
      expect(model.productName, 'Paracétamol 500mg');
      expect(model.batchNumber, 'BATCH-001');
      expect(model.lotNumber, 'LOT-A1');
      expect(model.expiryDate, DateTime(2025, 6, 15));
      expect(model.quantity, 200);
      expect(model.receivedAt, DateTime(2024, 12, 1));
      expect(model.supplier, 'Pharmacien CI');
    });

    test('should extract product name from nested product object', () {
      final model = ProductBatchModel.fromJson({
        'id': 2,
        'product_id': 20,
        'product': {'name': 'Amoxicilline 250mg'},
        'batch_number': 'B-002',
        'expiry_date': '2025-12-31',
        'quantity': 50,
      });

      expect(model.productName, 'Amoxicilline 250mg');
    });

    test('should handle missing optional fields', () {
      final model = ProductBatchModel.fromJson({
        'id': 3,
        'product_id': 30,
        'batch_number': 'B-003',
        'expiry_date': '2025-03-01',
        'quantity': 10,
      });

      expect(model.productName, isNull);
      expect(model.lotNumber, isNull);
      expect(model.receivedAt, isNull);
      expect(model.supplier, isNull);
    });

    test('should handle empty JSON with defaults', () {
      final model = ProductBatchModel.fromJson({});

      expect(model.id, 0);
      expect(model.productId, 0);
      expect(model.batchNumber, '');
      expect(model.quantity, 0);
    });
  });

  group('ProductBatchModel.toJson', () {
    test('should serialize to JSON correctly', () {
      final model = ProductBatchModel(
        id: 1,
        productId: 10,
        productName: 'Test',
        batchNumber: 'BATCH-001',
        lotNumber: 'LOT-01',
        expiryDate: DateTime(2025, 6, 15),
        quantity: 100,
        receivedAt: DateTime(2024, 12, 1),
        supplier: 'Test Supplier',
      );

      final json = model.toJson();
      expect(json['product_id'], 10);
      expect(json['batch_number'], 'BATCH-001');
      expect(json['lot_number'], 'LOT-01');
      expect(json['expiry_date'], '2025-06-15');
      expect(json['quantity'], 100);
      expect(json['received_at'], '2024-12-01');
      expect(json['supplier'], 'Test Supplier');
    });

    test('should handle null optional fields in toJson', () {
      final model = ProductBatchModel(
        id: 1,
        productId: 10,
        batchNumber: 'B-001',
        expiryDate: DateTime(2025, 1, 1),
        quantity: 50,
      );

      final json = model.toJson();
      expect(json['lot_number'], isNull);
      expect(json['received_at'], isNull);
      expect(json['supplier'], isNull);
    });
  });

  group('ProductBatchModel.toEntity', () {
    test('should convert to entity correctly', () {
      final model = ProductBatchModel(
        id: 5,
        productId: 50,
        productName: 'Doliprane',
        batchNumber: 'BATCH-005',
        lotNumber: 'LOT-X',
        expiryDate: DateTime(2025, 9, 30),
        quantity: 75,
        receivedAt: DateTime(2024, 6, 1),
        supplier: 'Sanofi',
      );

      final entity = model.toEntity();
      expect(entity.id, 5);
      expect(entity.productId, 50);
      expect(entity.productName, 'Doliprane');
      expect(entity.batchNumber, 'BATCH-005');
      expect(entity.lotNumber, 'LOT-X');
      expect(entity.expiryDate, DateTime(2025, 9, 30));
      expect(entity.quantity, 75);
      expect(entity.supplier, 'Sanofi');
    });
  });

  group('ProductBatchModel.toEntityList', () {
    test('should convert list of models to entities', () {
      final models = [
        ProductBatchModel(
          id: 1,
          productId: 1,
          batchNumber: 'B-1',
          expiryDate: DateTime(2025, 1, 1),
          quantity: 10,
        ),
        ProductBatchModel(
          id: 2,
          productId: 2,
          batchNumber: 'B-2',
          expiryDate: DateTime(2025, 6, 1),
          quantity: 20,
        ),
      ];

      final entities = ProductBatchModel.toEntityList(models);
      expect(entities.length, 2);
      expect(entities[0].id, 1);
      expect(entities[1].id, 2);
    });

    test('should return empty list for empty input', () {
      final entities = ProductBatchModel.toEntityList([]);
      expect(entities, isEmpty);
    });
  });
}
