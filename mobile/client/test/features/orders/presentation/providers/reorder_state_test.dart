import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/orders/presentation/providers/reorder_provider.dart';

void main() {
  group('ReorderState — defaults', () {
    test('status is idle', () {
      const s = ReorderState();
      expect(s.status, ReorderStatus.idle);
    });

    test('message is null', () {
      const s = ReorderState();
      expect(s.message, isNull);
    });

    test('addedCount is 0', () {
      const s = ReorderState();
      expect(s.addedCount, 0);
    });

    test('totalCount is 0', () {
      const s = ReorderState();
      expect(s.totalCount, 0);
    });

    test('failedProducts is empty', () {
      const s = ReorderState();
      expect(s.failedProducts, isEmpty);
    });
  });

  group('ReorderState — copyWith', () {
    test('updates status', () {
      const s = ReorderState();
      expect(
        s.copyWith(status: ReorderStatus.loading).status,
        ReorderStatus.loading,
      );
    });

    test('updates message', () {
      const s = ReorderState();
      final copy = s.copyWith(message: '3 articles ajoutés');
      expect(copy.message, '3 articles ajoutés');
    });

    test('updates addedCount', () {
      const s = ReorderState();
      expect(s.copyWith(addedCount: 5).addedCount, 5);
    });

    test('updates totalCount', () {
      const s = ReorderState();
      expect(s.copyWith(totalCount: 10).totalCount, 10);
    });

    test('updates failedProducts', () {
      const s = ReorderState();
      final copy = s.copyWith(failedProducts: ['Paracétamol', 'Ibuprofène']);
      expect(copy.failedProducts.length, 2);
    });

    test('preserves existing fields when not specified', () {
      const s = ReorderState(
        status: ReorderStatus.loading,
        addedCount: 2,
        totalCount: 5,
      );
      final copy = s.copyWith(message: 'ok');
      expect(copy.status, ReorderStatus.loading);
      expect(copy.addedCount, 2);
      expect(copy.totalCount, 5);
    });
  });

  group('ReorderState — value objects (success scenarios)', () {
    test('success state has addedCount == totalCount', () {
      const s = ReorderState(
        status: ReorderStatus.success,
        message: '3 articles ajoutés au panier',
        addedCount: 3,
        totalCount: 3,
      );
      expect(s.addedCount, equals(s.totalCount));
    });

    test('partialSuccess state has failedProducts', () {
      const s = ReorderState(
        status: ReorderStatus.partialSuccess,
        addedCount: 2,
        totalCount: 3,
        failedProducts: ['Article indisponible'],
      );
      expect(s.failedProducts.isNotEmpty, isTrue);
      expect(s.addedCount, lessThan(s.totalCount));
    });

    test('error state has addedCount 0', () {
      const s = ReorderState(
        status: ReorderStatus.error,
        message: 'Impossible d\'ajouter les articles',
        addedCount: 0,
        totalCount: 2,
      );
      expect(s.addedCount, 0);
    });
  });
}
