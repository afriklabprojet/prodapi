import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:drpharma_client/features/orders/presentation/widgets/order_summary_card.dart';
import 'package:drpharma_client/features/orders/domain/entities/cart_item_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';

const _testPharmacy = PharmacyEntity(
  id: 1,
  name: 'Pharmacie Test',
  address: '1 rue Test',
  phone: '0102030405',
  status: 'active',
  isOpen: true,
);

ProductEntity _makeProduct({
  int id = 1,
  String name = 'Doliprane 500mg',
  double price = 3500,
  int stock = 10,
}) {
  return ProductEntity(
    id: id,
    name: name,
    price: price,
    stockQuantity: stock,
    requiresPrescription: false,
    pharmacy: _testPharmacy,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

final _currencyFormat = NumberFormat('#,##0', 'fr_FR');

Widget _buildCard({
  List<CartItemEntity>? items,
  double subtotal = 3500,
  double deliveryFee = 500,
  double serviceFee = 0,
  double paymentFee = 0,
  double total = 4000,
  double? distanceKm,
  bool isLoadingDeliveryFee = false,
  String paymentMode = 'cash',
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: OrderSummaryCard(
          items:
              items ?? [CartItemEntity(product: _makeProduct(), quantity: 1)],
          subtotal: subtotal,
          deliveryFee: deliveryFee,
          serviceFee: serviceFee,
          paymentFee: paymentFee,
          total: total,
          currencyFormat: _currencyFormat,
          distanceKm: distanceKm,
          isLoadingDeliveryFee: isLoadingDeliveryFee,
          paymentMode: paymentMode,
        ),
      ),
    ),
  );
}

void main() {
  group('OrderSummaryCard Widget Tests', () {
    testWidgets('renders OrderSummaryCard', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();
      expect(find.byType(OrderSummaryCard), findsOneWidget);
    });

    testWidgets('shows Résumé de la commande title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();
      expect(find.text('Résumé de la commande'), findsOneWidget);
    });

    testWidgets('shows product name and quantity', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();
      expect(find.textContaining('Doliprane 500mg'), findsOneWidget);
      expect(find.textContaining('x1'), findsOneWidget);
    });

    testWidgets('shows Sous-total médicaments label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();
      expect(find.textContaining('Sous-total'), findsOneWidget);
    });

    testWidgets('shows Frais de livraison label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();
      expect(find.textContaining('Frais de livraison'), findsOneWidget);
    });

    testWidgets('shows Total label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when loading delivery fee', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard(isLoadingDeliveryFee: true));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows distance in km when provided', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard(distanceKm: 3.5));
      await tester.pumpAndSettle();
      expect(find.textContaining('3.5 km'), findsOneWidget);
    });

    testWidgets('shows Frais de service when serviceFee > 0', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard(serviceFee: 200));
      await tester.pumpAndSettle();
      expect(find.textContaining('Frais de service'), findsOneWidget);
    });

    testWidgets('does not show Frais de service when serviceFee is 0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard(serviceFee: 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Frais de service'), findsNothing);
    });

    testWidgets('shows Frais de paiement when paymentFee > 0', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard(paymentFee: 150));
      await tester.pumpAndSettle();
      expect(find.textContaining('Frais de paiement'), findsOneWidget);
    });

    testWidgets('does not show Frais de paiement when paymentFee is 0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard(paymentFee: 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Frais de paiement'), findsNothing);
    });

    testWidgets('shows multiple items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final items = [
        CartItemEntity(
          product: _makeProduct(id: 1, name: 'Doliprane'),
          quantity: 2,
        ),
        CartItemEntity(
          product: _makeProduct(id: 2, name: 'Ibuprofen'),
          quantity: 1,
        ),
      ];
      await tester.pumpWidget(
        _buildCard(items: items, subtotal: 10500, total: 11000),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Doliprane'), findsOneWidget);
      expect(find.textContaining('Ibuprofen'), findsOneWidget);
    });

    testWidgets('shows info_outline icon for service fee tooltip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard(serviceFee: 200));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.info_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('shows info_outline icon for payment fee tooltip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard(paymentFee: 150));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.info_outline), findsAtLeastNWidgets(1));
    });
  });
}
