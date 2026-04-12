import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_item_entity.dart';
import 'package:drpharma_client/features/orders/domain/repositories/orders_repository.dart';
import 'package:drpharma_client/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:drpharma_client/features/orders/domain/usecases/get_order_details_usecase.dart';
import 'package:drpharma_client/features/orders/domain/usecases/create_order_usecase.dart';
import 'package:drpharma_client/features/orders/domain/usecases/cancel_order_usecase.dart';

@GenerateMocks([OrdersRepository])
import 'orders_usecases_test.mocks.dart';

// ────────────────────────────────────────────────────────────────────────────
// Fixtures
// ────────────────────────────────────────────────────────────────────────────

const _address = DeliveryAddressEntity(
  address: 'Plateau, Abidjan',
  city: 'Abidjan',
  phone: '+2250700000001',
);

const _item = OrderItemEntity(
  id: 1,
  productId: 10,
  name: 'Doliprane',
  quantity: 2,
  unitPrice: 1500.0,
  totalPrice: 3000.0,
);

OrderEntity _makeOrder({
  int id = 1001,
  OrderStatus status = OrderStatus.pending,
}) => OrderEntity(
  id: id,
  reference: 'ORD-2024-00$id',
  status: status,
  paymentStatus: 'pending',
  paymentMode: PaymentMode.platform,
  pharmacyId: 1,
  pharmacyName: 'Pharmacie du Centre',
  items: const [_item],
  subtotal: 3000.0,
  deliveryFee: 500.0,
  totalAmount: 3500.0,
  deliveryAddress: _address,
  createdAt: DateTime(2024, 6, 1),
);

const _serverFailure = ServerFailure(message: 'Erreur serveur');
const _networkFailure = NetworkFailure(message: 'Pas de connexion');

void main() {
  late MockOrdersRepository mockRepo;

  setUp(() => mockRepo = MockOrdersRepository());

  // ────────────────────────────────────────────────────────────────────────────
  // GetOrdersUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetOrdersUseCase', () {
    late GetOrdersUseCase useCase;
    setUp(() => useCase = GetOrdersUseCase(mockRepo));

    test('returns list of orders on success', () async {
      when(
        mockRepo.getOrders(status: anyNamed('status'), page: anyNamed('page')),
      ).thenAnswer((_) async => Right([_makeOrder(), _makeOrder(id: 1002)]));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (orders) => expect(orders.length, 2),
      );
      verify(mockRepo.getOrders(status: null, page: 1)).called(1);
    });

    test('filters by status when provided', () async {
      when(mockRepo.getOrders(status: 'delivered', page: 1)).thenAnswer(
        (_) async => Right([_makeOrder(status: OrderStatus.delivered)]),
      );

      final result = await useCase(status: 'delivered');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) {},
        (orders) => expect(orders.first.status, OrderStatus.delivered),
      );
    });

    test('returns empty list when no orders exist', () async {
      when(
        mockRepo.getOrders(status: anyNamed('status'), page: anyNamed('page')),
      ).thenAnswer((_) async => const Right([]));

      final result = await useCase();
      result.fold(
        (_) => fail('expected Right'),
        (orders) => expect(orders, isEmpty),
      );
    });

    test('returns ServerFailure on error', () async {
      when(
        mockRepo.getOrders(status: anyNamed('status'), page: anyNamed('page')),
      ).thenAnswer((_) async => const Left(_serverFailure));

      final result = await useCase();
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns NetworkFailure when offline', () async {
      when(
        mockRepo.getOrders(status: anyNamed('status'), page: anyNamed('page')),
      ).thenAnswer((_) async => const Left(_networkFailure));

      final result = await useCase();
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // GetOrderDetailsUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetOrderDetailsUseCase', () {
    late GetOrderDetailsUseCase useCase;
    setUp(() => useCase = GetOrderDetailsUseCase(mockRepo));

    test('returns OrderEntity on success', () async {
      when(
        mockRepo.getOrderDetails(any),
      ).thenAnswer((_) async => Right(_makeOrder()));

      final result = await useCase(1001);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (o) => expect(o.id, 1001));
      verify(mockRepo.getOrderDetails(1001)).called(1);
    });

    test('returns ServerFailure when order not found', () async {
      when(
        mockRepo.getOrderDetails(any),
      ).thenAnswer((_) async => const Left(_serverFailure));

      final result = await useCase(9999);
      expect(result.isLeft(), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // CreateOrderUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('CreateOrderUseCase', () {
    late CreateOrderUseCase useCase;
    setUp(() => useCase = CreateOrderUseCase(mockRepo));

    test('creates order and returns OrderEntity', () async {
      when(
        mockRepo.createOrder(
          pharmacyId: anyNamed('pharmacyId'),
          items: anyNamed('items'),
          deliveryAddress: anyNamed('deliveryAddress'),
          paymentMode: anyNamed('paymentMode'),
          prescriptionImage: anyNamed('prescriptionImage'),
          customerNotes: anyNamed('customerNotes'),
          prescriptionId: anyNamed('prescriptionId'),
          promoCode: anyNamed('promoCode'),
        ),
      ).thenAnswer((_) async => Right(_makeOrder()));

      final result = await useCase(
        pharmacyId: 1,
        items: const [_item],
        deliveryAddress: _address,
        paymentMode: 'platform',
      );

      expect(result.isRight(), isTrue);
      verify(
        mockRepo.createOrder(
          pharmacyId: 1,
          items: const [_item],
          deliveryAddress: _address,
          paymentMode: 'platform',
          prescriptionImage: null,
          customerNotes: null,
          prescriptionId: null,
          promoCode: null,
        ),
      ).called(1);
    });

    test('passes optional fields to repository', () async {
      when(
        mockRepo.createOrder(
          pharmacyId: anyNamed('pharmacyId'),
          items: anyNamed('items'),
          deliveryAddress: anyNamed('deliveryAddress'),
          paymentMode: anyNamed('paymentMode'),
          prescriptionImage: anyNamed('prescriptionImage'),
          customerNotes: anyNamed('customerNotes'),
          prescriptionId: anyNamed('prescriptionId'),
          promoCode: anyNamed('promoCode'),
        ),
      ).thenAnswer((_) async => Right(_makeOrder()));

      await useCase(
        pharmacyId: 1,
        items: const [_item],
        deliveryAddress: _address,
        paymentMode: 'platform',
        prescriptionImage: 'prescriptions/rx.jpg',
        customerNotes: 'Sonnez deux fois',
        prescriptionId: 5,
        promoCode: 'PROMO10',
      );

      verify(
        mockRepo.createOrder(
          pharmacyId: 1,
          items: const [_item],
          deliveryAddress: _address,
          paymentMode: 'platform',
          prescriptionImage: 'prescriptions/rx.jpg',
          customerNotes: 'Sonnez deux fois',
          prescriptionId: 5,
          promoCode: 'PROMO10',
        ),
      ).called(1);
    });

    test('returns ServerFailure on creation failure', () async {
      when(
        mockRepo.createOrder(
          pharmacyId: anyNamed('pharmacyId'),
          items: anyNamed('items'),
          deliveryAddress: anyNamed('deliveryAddress'),
          paymentMode: anyNamed('paymentMode'),
          prescriptionImage: anyNamed('prescriptionImage'),
          customerNotes: anyNamed('customerNotes'),
          prescriptionId: anyNamed('prescriptionId'),
          promoCode: anyNamed('promoCode'),
        ),
      ).thenAnswer((_) async => const Left(_serverFailure));

      final result = await useCase(
        pharmacyId: 1,
        items: const [_item],
        deliveryAddress: _address,
        paymentMode: 'cash',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // CancelOrderUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('CancelOrderUseCase', () {
    late CancelOrderUseCase useCase;
    setUp(() => useCase = CancelOrderUseCase(mockRepo));

    test('cancels order and returns Right(null)', () async {
      when(
        mockRepo.cancelOrder(any, any),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(1001, 'Commande en double');

      expect(result.isRight(), isTrue);
      verify(mockRepo.cancelOrder(1001, 'Commande en double')).called(1);
    });

    test('returns ServerFailure when cancellation fails', () async {
      when(
        mockRepo.cancelOrder(any, any),
      ).thenAnswer((_) async => const Left(_serverFailure));

      final result = await useCase(9999, 'Erreur');
      expect(result.isLeft(), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // DeliveryAddressEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('DeliveryAddressEntity', () {
    test('fullAddress includes city when present', () {
      const addr = DeliveryAddressEntity(address: 'Plateau', city: 'Abidjan');
      expect(addr.fullAddress, 'Plateau, Abidjan');
    });

    test('fullAddress is just address when city absent', () {
      const addr = DeliveryAddressEntity(address: 'Plateau');
      expect(addr.fullAddress, 'Plateau');
    });

    test('copyWith preserves unchanged fields', () {
      const original = DeliveryAddressEntity(
        address: 'Plateau',
        city: 'Abidjan',
      );
      final copy = original.copyWith(phone: '+225');
      expect(copy.address, 'Plateau');
      expect(copy.city, 'Abidjan');
      expect(copy.phone, '+225');
    });

    test('toJson serializes all non-null fields', () {
      const addr = DeliveryAddressEntity(
        address: 'Plateau',
        city: 'Abidjan',
        latitude: 5.35,
        longitude: -4.00,
        phone: '+225',
      );
      final json = addr.toJson();
      expect(json['delivery_address'], 'Plateau');
      expect(json['delivery_city'], 'Abidjan');
      expect(json['delivery_latitude'], 5.35);
      expect(json['delivery_longitude'], -4.00);
      expect(json['customer_phone'], '+225');
    });

    test('toJson omits null optional fields', () {
      const addr = DeliveryAddressEntity(address: 'Plateau');
      final json = addr.toJson();
      expect(json.containsKey('delivery_city'), isFalse);
      expect(json.containsKey('delivery_latitude'), isFalse);
    });

    test('Equatable works', () {
      const a = DeliveryAddressEntity(address: 'X');
      const b = DeliveryAddressEntity(address: 'X');
      expect(a, b);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // OrderItemEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('OrderItemEntity', () {
    test('copyWith updates fields', () {
      const item = OrderItemEntity(
        name: 'Doliprane',
        quantity: 1,
        unitPrice: 1000.0,
        totalPrice: 1000.0,
      );
      final updated = item.copyWith(quantity: 3, totalPrice: 3000.0);
      expect(updated.quantity, 3);
      expect(updated.totalPrice, 3000.0);
      expect(updated.name, 'Doliprane');
    });

    test('Equatable works', () {
      const a = OrderItemEntity(
        name: 'X',
        quantity: 1,
        unitPrice: 100.0,
        totalPrice: 100.0,
      );
      const b = OrderItemEntity(
        name: 'X',
        quantity: 1,
        unitPrice: 100.0,
        totalPrice: 100.0,
      );
      expect(a, b);
    });
  });
}
