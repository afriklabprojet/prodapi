import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/widgets/order_card.dart';
import '../../../../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr', null);
  });

  group('OrderCard Widget', () {
    testWidgets('should display order reference', (tester) async {
      final order = TestDataFactory.createOrder(reference: 'DR-TEST123');
      // ignore: unused_local_variable
      bool tapped = false;

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('#DR-TEST123'), findsOneWidget);
    });

    testWidgets('should display customer name', (tester) async {
      final order = TestDataFactory.createOrder(customerName: 'Jean Dupont');

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Jean Dupont'), findsOneWidget);
    });

    testWidgets('should display formatted date', (tester) async {
      final date = DateTime(2024, 3, 15, 14, 30);
      final order = TestDataFactory.createOrder(createdAt: date);

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      // The date format used in the widget
      final expectedDate = DateFormat('dd MMM yyyy • HH:mm', 'fr').format(date);
      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('should display total amount with FCFA', (tester) async {
      final order = TestDataFactory.createOrder(totalAmount: 15000.0);

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      // Should show formatted currency - using textContaining to be flexible
      expect(find.textContaining('15'), findsWidgets);
      expect(find.textContaining('FCFA'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      final order = TestDataFactory.createOrder();
      bool tapped = false;

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should display items count', (tester) async {
      final items = [
        TestDataFactory.createOrderItem(name: 'Item 1'),
        TestDataFactory.createOrderItem(name: 'Item 2'),
        TestDataFactory.createOrderItem(name: 'Item 3'),
      ];
      final order = TestDataFactory.createOrder(items: items);

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('article'), findsOneWidget);
    });

    testWidgets('should display person icon for customer', (tester) async {
      final order = TestDataFactory.createOrder();

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should display time icon', (tester) async {
      final order = TestDataFactory.createOrder();

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    });

    testWidgets('should display shopping bag icon', (tester) async {
      final order = TestDataFactory.createOrder();

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    });
  });

  group('OrderCard Status Badge', () {
    testWidgets('should display pending status as "En attente"', (tester) async {
      final order = TestDataFactory.createOrder(status: 'pending');

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('En attente'), findsOneWidget);
    });

    testWidgets('should display confirmed status as "Confirmé"', (tester) async {
      final order = TestDataFactory.createOrder(status: 'confirmed');

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Confirmé'), findsOneWidget);
    });

    testWidgets('should display ready status as "Prêt"', (tester) async {
      final order = TestDataFactory.createOrder(status: 'ready');

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Prêt'), findsOneWidget);
    });

    testWidgets('should display picked_up status as "Récupéré"', (tester) async {
      final order = TestDataFactory.createOrder(status: 'picked_up');

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Récupéré'), findsOneWidget);
    });

    testWidgets('should display delivered status as "Livré"', (tester) async {
      final order = TestDataFactory.createOrder(status: 'delivered');

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Livré'), findsOneWidget);
    });

    testWidgets('should display cancelled status as "Annulé"', (tester) async {
      final order = TestDataFactory.createOrder(status: 'cancelled');

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Annulé'), findsOneWidget);
    });

    testWidgets('should display unknown status as-is', (tester) async {
      final order = TestDataFactory.createOrder(status: 'custom_status');

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('custom_status'), findsOneWidget);
    });
  });

  group('OrderCard Layout', () {
    testWidgets('should have proper card container', (tester) async {
      final order = TestDataFactory.createOrder();

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      // Find the OrderCard widget
      expect(find.byType(OrderCard), findsOneWidget);
    });

    testWidgets('should have InkWell for tap effect', (tester) async {
      final order = TestDataFactory.createOrder();

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('should have divider between content sections', (tester) async {
      final order = TestDataFactory.createOrder();

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('OrderCard Singular/Plural articles', () {
    testWidgets('should show singular "article" for 1 item', (tester) async {
      final order = TestDataFactory.createOrder(
        items: [TestDataFactory.createOrderItem()],
        itemsCount: 1,
      );

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('1 article'), findsOneWidget);
    });

    testWidgets('should show plural "articles" for multiple items', (tester) async {
      final items = [
        TestDataFactory.createOrderItem(name: 'Item 1'),
        TestDataFactory.createOrderItem(name: 'Item 2'),
      ];
      final order = TestDataFactory.createOrder(items: items, itemsCount: 2);

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('2 articles'), findsOneWidget);
    });

    testWidgets('should show "0 article" for zero items count', (tester) async {
      final order = TestDataFactory.createOrder(items: [], itemsCount: 0);

      await tester.pumpWidget(
        createTestableWidget(
          OrderCard(
            order: order,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('0 article'), findsOneWidget);
    });
  });
}
