import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/core/widgets/empty_state.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      home: Scaffold(body: child),
    );
  }

  group('EmptyState', () {
    testWidgets('should display icon', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          const EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Test Title',
            message: 'Test Message',
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('should display title', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          const EmptyState(
            icon: Icons.inbox,
            title: 'Panier vide',
            message: 'Votre panier est vide',
          ),
        ),
      );

      // Assert
      expect(find.text('Panier vide'), findsOneWidget);
    });

    testWidgets('should display message', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          const EmptyState(
            icon: Icons.inbox,
            title: 'Title',
            message: 'Ajoutez des produits pour commencer',
          ),
        ),
      );

      // Assert
      expect(find.text('Ajoutez des produits pour commencer'), findsOneWidget);
    });

    testWidgets('should not display action button when no callback', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          const EmptyState(
            icon: Icons.inbox,
            title: 'Title',
            message: 'Message',
          ),
        ),
      );

      // Assert - no refresh icon when onAction is null
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('should display action button when provided', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          EmptyState(
            icon: Icons.inbox,
            title: 'Title',
            message: 'Message',
            actionLabel: 'Réessayer',
            onAction: () {},
          ),
        ),
      );

      // Assert - ElevatedButton.icon is rendered as ElevatedButton
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should call onAction when button tapped', (tester) async {
      // Arrange
      bool actionCalled = false;
      await tester.pumpWidget(
        createTestWidget(
          EmptyState(
            icon: Icons.inbox,
            title: 'Title',
            message: 'Message',
            actionLabel: 'Réessayer',
            onAction: () => actionCalled = true,
          ),
        ),
      );

      // Act - tap on the button text
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      // Assert
      expect(actionCalled, true);
    });

    testWidgets('should display refresh icon in action button', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          EmptyState(
            icon: Icons.inbox,
            title: 'Title',
            message: 'Message',
            actionLabel: 'Refresh',
            onAction: () {},
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should use custom icon color when provided', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          const EmptyState(
            icon: Icons.error_outline,
            title: 'Erreur',
            message: 'Une erreur est survenue',
            iconColor: Colors.red,
          ),
        ),
      );

      // Assert - widget should render with custom color
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, Colors.red);
    });

    testWidgets('should have Center widget in tree', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          const EmptyState(
            icon: Icons.inbox,
            title: 'Title',
            message: 'Message',
          ),
        ),
      );

      // Assert - at least one Center widget
      expect(find.byType(Center), findsWidgets);
    });
  });

  group('EmptyProductsState', () {
    testWidgets('should display products empty state', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(const EmptyProductsState()));

      // Assert
      expect(find.text('Aucun produit'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('should show refresh button when callback provided', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(EmptyProductsState(onRefresh: () {})),
      );

      // Assert
      expect(find.text('Actualiser'), findsOneWidget);
    });
  });

  group('EmptyOrdersState', () {
    testWidgets('should display orders empty state', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(const EmptyOrdersState()));

      // Assert
      expect(find.text('Aucune commande'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });
  });

  group('EmptyCartState', () {
    testWidgets('should display cart empty state', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(const EmptyCartState()));

      // Assert
      expect(find.text('Panier vide'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });
  });
}
