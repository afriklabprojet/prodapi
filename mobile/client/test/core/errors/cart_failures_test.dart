import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/errors/cart_failures.dart';
import 'package:drpharma_client/core/errors/failures.dart';

void main() {
  group('ProductUnavailableFailure', () {
    test('is a Failure', () {
      const f = ProductUnavailableFailure(
        productId: 1,
        productName: 'Paracetamol',
      );
      expect(f, isA<Failure>());
    });

    test('message includes product name', () {
      const f = ProductUnavailableFailure(
        productId: 1,
        productName: 'Doliprane',
      );
      expect(f.message, contains('Doliprane'));
    });

    test('props includes productId and productName', () {
      const f = ProductUnavailableFailure(
        productId: 42,
        productName: 'Ibuprofene',
      );
      expect(f.props, containsAll([42, 'Ibuprofene']));
    });
  });

  group('InsufficientStockFailure', () {
    test('message includes quantities', () {
      const f = InsufficientStockFailure(
        productId: 1,
        requestedQuantity: 5,
        availableStock: 2,
      );
      expect(f.message, contains('5'));
      expect(f.message, contains('2'));
    });

    test('props includes all fields', () {
      const f = InsufficientStockFailure(
        productId: 10,
        requestedQuantity: 3,
        availableStock: 1,
      );
      expect(f.props, containsAll([10, 3, 1]));
    });
  });

  group('DifferentPharmacyFailure', () {
    test('message includes pharmacy names', () {
      const f = DifferentPharmacyFailure(
        currentPharmacyId: 1,
        currentPharmacyName: 'Pharmacie A',
        newPharmacyId: 2,
        newPharmacyName: 'Pharmacie B',
      );
      expect(f.message, contains('Pharmacie A'));
    });

    test('props includes all ids and names', () {
      const f = DifferentPharmacyFailure(
        currentPharmacyId: 1,
        currentPharmacyName: 'Pharma A',
        newPharmacyId: 2,
        newPharmacyName: 'Pharma B',
      );
      expect(f.props, containsAll([1, 'Pharma A', 2, 'Pharma B']));
    });
  });

  group('ItemNotFoundFailure', () {
    test('has standard message', () {
      const f = ItemNotFoundFailure(productId: 99);
      expect(f.message, contains('non trouvé'));
    });

    test('props includes productId', () {
      const f = ItemNotFoundFailure(productId: 5);
      expect(f.props, contains(5));
    });
  });

  group('InvalidQuantityFailure', () {
    test('message includes quantity', () {
      const f = InvalidQuantityFailure(quantity: -1);
      expect(f.message, contains('-1'));
    });

    test('props includes quantity', () {
      const f = InvalidQuantityFailure(quantity: 0);
      expect(f.props, contains(0));
    });
  });

  group('CartPersistenceFailure', () {
    test('message includes operation name', () {
      const f = CartPersistenceFailure(operation: 'save');
      expect(f.message, contains('save'));
    });

    test('props includes operation', () {
      const f = CartPersistenceFailure(operation: 'load');
      expect(f.props, contains('load'));
    });
  });

  group('CartRestoreFailure', () {
    test('has default message', () {
      const f = CartRestoreFailure();
      expect(f.message, contains('restaurer'));
    });
  });

  group('CartSyncFailure', () {
    test('uses reason as message when provided', () {
      const f = CartSyncFailure(reason: 'Timeout');
      expect(f.message, 'Timeout');
    });

    test('uses default message when reason is null', () {
      const f = CartSyncFailure();
      expect(f.message, contains('synchronisation'));
    });

    test('props includes reason', () {
      const f = CartSyncFailure(reason: 'Network error');
      expect(f.props, contains('Network error'));
    });
  });

  group('CartConflictFailure', () {
    test('message includes counts', () {
      const f = CartConflictFailure(localItemCount: 3, serverItemCount: 5);
      expect(f.message, contains('3'));
      expect(f.message, contains('5'));
    });
  });

  group('CartLimitReachedFailure', () {
    test('message includes maxItems', () {
      const f = CartLimitReachedFailure(maxItems: 50, currentItems: 50);
      expect(f.message, contains('50'));
    });

    test('props includes maxItems and currentItems', () {
      const f = CartLimitReachedFailure(maxItems: 20, currentItems: 20);
      expect(f.props, containsAll([20, 20]));
    });

    test('is a Failure', () {
      const f = CartLimitReachedFailure(maxItems: 10, currentItems: 10);
      expect(f, isA<Failure>());
    });
  });

  group('CartExpiredFailure', () {
    test('has expiration message', () {
      const f = CartExpiredFailure(age: Duration(days: 10));
      expect(f.message, isNotEmpty);
    });

    test('props includes age', () {
      const age = Duration(days: 8);
      const f = CartExpiredFailure(age: age);
      expect(f.props, contains(age));
    });
  });

  group('ProductDiscontinuedFailure', () {
    test('message includes product name', () {
      const f = ProductDiscontinuedFailure(
        productId: 1,
        productName: 'Doliprane',
      );
      expect(f.message, contains('Doliprane'));
    });

    test('props includes productId and productName', () {
      const f = ProductDiscontinuedFailure(
        productId: 99,
        productName: 'Aspirine',
      );
      expect(f.props, containsAll([99, 'Aspirine']));
    });
  });

  group('PriceChangedFailure', () {
    test('message includes old and new price', () {
      final f = PriceChangedFailure(productId: 1, oldPrice: 500, newPrice: 650);
      expect(f.message, contains('500'));
      expect(f.message, contains('650'));
    });

    test('props includes productId, oldPrice, newPrice', () {
      final f = PriceChangedFailure(productId: 5, oldPrice: 100, newPrice: 200);
      expect(f.props, containsAll([5, 100.0, 200.0]));
    });
  });

  group('PharmacyClosedFailure', () {
    test('message includes pharmacy name', () {
      const f = PharmacyClosedFailure(
        pharmacyId: 1,
        pharmacyName: 'Pharmacie Centrale',
      );
      expect(f.message, contains('Pharmacie Centrale'));
    });

    test('props includes pharmacyId and pharmacyName', () {
      const f = PharmacyClosedFailure(
        pharmacyId: 42,
        pharmacyName: 'Pharma XYZ',
      );
      expect(f.props, containsAll([42, 'Pharma XYZ']));
    });
  });

  group('OperationInProgressFailure', () {
    test('has non-empty message', () {
      const f = OperationInProgressFailure();
      expect(f.message, isNotEmpty);
    });

    test('is a Failure', () {
      const f = OperationInProgressFailure();
      expect(f, isA<Failure>());
    });
  });
}
