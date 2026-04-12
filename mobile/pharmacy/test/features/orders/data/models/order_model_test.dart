import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/orders/data/models/order_model.dart';
import 'package:drpharma_pharmacy/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_pharmacy/features/orders/domain/enums/order_status.dart';

void main() {
  group('OrderModel', () {
    const tOrderModel = OrderModel(
      id: 1,
      reference: 'ORD-001',
      status: 'pending',
      paymentMode: 'cash',
      totalAmount: 15000.0,
      createdAt: '2024-01-15T10:30:00.000Z',
      customer: {'name': 'Client Test', 'phone': '0123456789'},
      deliveryAddress: '123 Rue Test',
      customerNotes: 'Note client',
      pharmacyNotes: null,
      prescriptionImage: 'https://example.com/prescription.jpg',
      itemsCount: 3,
      items: [
        OrderItemModel(
          name: 'Paracétamol',
          quantity: 2,
          unitPrice: 500.0,
          totalPrice: 1000.0,
        ),
      ],
      deliveryFee: 1000.0,
      subtotal: 14000.0,
    );

    final tOrderJson = {
      'id': 1,
      'reference': 'ORD-001',
      'status': 'pending',
      'payment_mode': 'cash',
      'total_amount': 15000.0,
      'created_at': '2024-01-15T10:30:00.000Z',
      'customer': {'name': 'Client Test', 'phone': '0123456789'},
      'delivery_address': '123 Rue Test',
      'customer_notes': 'Note client',
      'pharmacy_notes': null,
      'prescription_image': 'https://example.com/prescription.jpg',
      'items_count': 3,
      'items': [
        {
          'name': 'Paracétamol',
          'quantity': 2,
          'unit_price': 500.0,
          'total_price': 1000.0,
        },
      ],
      'delivery_fee': 1000.0,
      'subtotal': 14000.0,
    };

    group('fromJson', () {
      test('should return a valid model from JSON', () {
        // act
        final result = OrderModel.fromJson(tOrderJson);

        // assert
        expect(result.id, tOrderModel.id);
        expect(result.reference, tOrderModel.reference);
        expect(
          result.status,
          tOrderModel.status,
        ); // String comparison OK for model
        expect(result.paymentMode, tOrderModel.paymentMode);
        expect(result.totalAmount, tOrderModel.totalAmount);
        expect(result.createdAt, tOrderModel.createdAt);
        expect(result.customer, tOrderModel.customer);
        expect(result.deliveryAddress, tOrderModel.deliveryAddress);
        expect(result.customerNotes, tOrderModel.customerNotes);
        expect(result.prescriptionImage, tOrderModel.prescriptionImage);
        expect(result.itemsCount, tOrderModel.itemsCount);
        expect(result.deliveryFee, tOrderModel.deliveryFee);
        expect(result.subtotal, tOrderModel.subtotal);
      });

      test('should handle null optional fields', () {
        // arrange
        final json = {
          'id': 1,
          'reference': 'ORD-001',
          'status': 'pending',
          'payment_mode': 'cash',
          'total_amount': 15000.0,
          'created_at': '2024-01-15T10:30:00.000Z',
          'customer': {'name': 'Client Test', 'phone': '0123456789'},
        };

        // act
        final result = OrderModel.fromJson(json);

        // assert
        expect(result.deliveryAddress, isNull);
        expect(result.customerNotes, isNull);
        expect(result.pharmacyNotes, isNull);
        expect(result.prescriptionImage, isNull);
        expect(result.itemsCount, isNull);
        expect(result.items, isNull);
        expect(result.deliveryFee, isNull);
        expect(result.subtotal, isNull);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        // act
        final result = tOrderModel.toJson();

        // assert
        expect(result['id'], tOrderModel.id);
        expect(result['reference'], tOrderModel.reference);
        expect(result['status'], tOrderModel.status);
        expect(result['payment_mode'], tOrderModel.paymentMode);
        expect(result['total_amount'], tOrderModel.totalAmount);
        expect(result['created_at'], tOrderModel.createdAt);
      });
    });

    group('toEntity', () {
      test('should return an OrderEntity with the same values', () {
        // act
        final result = tOrderModel.toEntity();

        // assert
        expect(result, isA<OrderEntity>());
        expect(result.id, tOrderModel.id);
        expect(result.reference, tOrderModel.reference);
        expect(
          result.status,
          OrderStatus.pending,
        ); // Entity uses enum, not string
        expect(result.paymentMode, tOrderModel.paymentMode);
        expect(result.totalAmount, tOrderModel.totalAmount);
        expect(result.customerName, tOrderModel.customer['name']);
        expect(result.customerPhone, tOrderModel.customer['phone']);
        expect(result.deliveryAddress, tOrderModel.deliveryAddress);
        expect(result.customerNotes, tOrderModel.customerNotes);
        expect(result.prescriptionImage, tOrderModel.prescriptionImage);
        expect(result.createdAt, isA<DateTime>());
      });

      test('should convert items to OrderItemEntity list', () {
        // act
        final result = tOrderModel.toEntity();

        // assert
        expect(result.items, isNotNull);
        expect(result.items!.length, 1);
        expect(result.items!.first, isA<OrderItemEntity>());
        expect(result.items!.first.name, 'Paracétamol');
        expect(result.items!.first.quantity, 2);
      });

      test('should handle missing customer name', () {
        // arrange
        const model = OrderModel(
          id: 1,
          reference: 'ORD-001',
          status: 'pending',
          paymentMode: 'cash',
          totalAmount: 15000.0,
          createdAt: '2024-01-15T10:30:00.000Z',
          customer: {}, // Empty customer
        );

        // act
        final result = model.toEntity();

        // assert
        expect(result.customerName, 'Inconnu');
        expect(result.customerPhone, '');
      });
    });
  });

  group('OrderItemModel', () {
    const tOrderItemModel = OrderItemModel(
      name: 'Paracétamol',
      quantity: 2,
      unitPrice: 500.0,
      totalPrice: 1000.0,
    );

    final tOrderItemJson = {
      'name': 'Paracétamol',
      'quantity': 2,
      'unit_price': 500.0,
      'total_price': 1000.0,
    };

    group('fromJson', () {
      test('should return a valid model from JSON', () {
        // act
        final result = OrderItemModel.fromJson(tOrderItemJson);

        // assert
        expect(result.name, tOrderItemModel.name);
        expect(result.quantity, tOrderItemModel.quantity);
        expect(result.unitPrice, tOrderItemModel.unitPrice);
        expect(result.totalPrice, tOrderItemModel.totalPrice);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        // act
        final result = tOrderItemModel.toJson();

        // assert
        expect(result['name'], tOrderItemModel.name);
        expect(result['quantity'], tOrderItemModel.quantity);
        expect(result['unit_price'], tOrderItemModel.unitPrice);
        expect(result['total_price'], tOrderItemModel.totalPrice);
      });
    });

    group('toEntity', () {
      test('should return an OrderItemEntity with the same values', () {
        // act
        final result = tOrderItemModel.toEntity();

        // assert
        expect(result, isA<OrderItemEntity>());
        expect(result.name, tOrderItemModel.name);
        expect(result.quantity, tOrderItemModel.quantity);
        expect(result.unitPrice, tOrderItemModel.unitPrice);
        expect(result.totalPrice, tOrderItemModel.totalPrice);
      });
    });
  });
}
