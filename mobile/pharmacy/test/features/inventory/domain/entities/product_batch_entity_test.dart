import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/inventory/domain/entities/product_batch_entity.dart';
import 'package:drpharma_pharmacy/features/inventory/presentation/providers/batch_provider.dart';

void main() {
  ProductBatchEntity createBatch({required DateTime expiryDate}) {
    return ProductBatchEntity(
      id: 1,
      productId: 10,
      productName: 'Paracétamol 500mg',
      batchNumber: 'BATCH-001',
      lotNumber: 'LOT-A1',
      expiryDate: expiryDate,
      quantity: 100,
      receivedAt: DateTime(2024, 1, 1),
      supplier: 'Fournisseur Test',
    );
  }

  group('ProductBatchEntity - expiry status', () {
    test('isExpired should be true for past dates', () {
      final batch = createBatch(
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(batch.isExpired, true);
      expect(batch.alertSeverity, ExpiryAlertSeverity.expired);
    });

    test('isCritical should be true when expiry <= 7 days', () {
      final batch = createBatch(
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      );
      expect(batch.isExpired, false);
      expect(batch.isCritical, true);
      expect(batch.isExpiringSoon, true); // <= 30 days includes critical
      expect(batch.alertSeverity, ExpiryAlertSeverity.critical);
    });

    test('isExpiringSoon should be true when expiry <= 30 days', () {
      final batch = createBatch(
        expiryDate: DateTime.now().add(const Duration(days: 20)),
      );
      expect(batch.isExpired, false);
      expect(batch.isCritical, false);
      expect(batch.isExpiringSoon, true);
      expect(batch.alertSeverity, ExpiryAlertSeverity.warning);
    });

    test('isWarning should be true when expiry <= 90 days', () {
      final batch = createBatch(
        expiryDate: DateTime.now().add(const Duration(days: 60)),
      );
      expect(batch.isExpired, false);
      expect(batch.isCritical, false);
      expect(batch.isExpiringSoon, false);
      expect(batch.isWarning, true);
      expect(batch.alertSeverity, ExpiryAlertSeverity.info);
    });

    test('should have no alert for dates > 90 days', () {
      final batch = createBatch(
        expiryDate: DateTime.now().add(const Duration(days: 180)),
      );
      expect(batch.isExpired, false);
      expect(batch.isCritical, false);
      expect(batch.isExpiringSoon, false);
      expect(batch.isWarning, false);
      expect(batch.alertSeverity, ExpiryAlertSeverity.none);
    });

    test('daysUntilExpiry should be negative for expired batches', () {
      final batch = createBatch(
        expiryDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(batch.daysUntilExpiry, lessThan(0));
    });

    test('daysUntilExpiry should be positive for future dates', () {
      final batch = createBatch(
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(batch.daysUntilExpiry, greaterThan(0));
    });
  });

  group('ProductBatchEntity - copyWith', () {
    test('should create copy with updated fields', () {
      final batch = createBatch(
        expiryDate: DateTime.now().add(const Duration(days: 60)),
      );
      final updated = batch.copyWith(batchNumber: 'BATCH-002', quantity: 50);

      expect(updated.batchNumber, 'BATCH-002');
      expect(updated.quantity, 50);
      expect(updated.id, batch.id); // unchanged
      expect(updated.productName, batch.productName); // unchanged
    });

    test('should preserve all original fields when no params passed', () {
      final batch = createBatch(
        expiryDate: DateTime.now().add(const Duration(days: 60)),
      );
      final copy = batch.copyWith();

      expect(copy.id, batch.id);
      expect(copy.productId, batch.productId);
      expect(copy.productName, batch.productName);
      expect(copy.batchNumber, batch.batchNumber);
      expect(copy.lotNumber, batch.lotNumber);
      expect(copy.expiryDate, batch.expiryDate);
      expect(copy.quantity, batch.quantity);
      expect(copy.supplier, batch.supplier);
    });
  });

  group('ExpiryAlertSummary', () {
    test('should calculate totalAlertCount correctly', () {
      const summary = ExpiryAlertSummary(
        expiredCount: 2,
        criticalCount: 3,
        warningCount: 5,
      );
      expect(summary.totalAlertCount, 10);
      expect(summary.hasAlerts, true);
    });

    test('should return hasAlerts false when all counts are zero', () {
      const summary = ExpiryAlertSummary(
        expiredCount: 0,
        criticalCount: 0,
        warningCount: 0,
      );
      expect(summary.totalAlertCount, 0);
      expect(summary.hasAlerts, false);
    });

    test('should detect alerts with only expired count', () {
      const summary = ExpiryAlertSummary(
        expiredCount: 1,
        criticalCount: 0,
        warningCount: 0,
      );
      expect(summary.hasAlerts, true);
    });
  });
}
