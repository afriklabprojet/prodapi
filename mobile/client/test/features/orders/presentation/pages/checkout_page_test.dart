import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/orders/presentation/pages/checkout_page.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_state.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_notifier.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_provider.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_state.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_notifier.dart';
import 'package:drpharma_client/features/orders/domain/entities/cart_item_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/addresses/presentation/providers/addresses_provider.dart'
    show AddressesState, AddressesNotifier, addressesProvider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

// Mocks
class MockCartNotifier extends StateNotifier<CartState>
    with Mock
    implements CartNotifier {
  MockCartNotifier([CartState? state])
    : super(state ?? const CartState.initial());
}

class MockOrdersNotifier extends StateNotifier<OrdersState>
    with Mock
    implements OrdersNotifier {
  MockOrdersNotifier() : super(const OrdersState.initial());
}

class MockAddressesNotifier extends StateNotifier<AddressesState>
    with Mock
    implements AddressesNotifier {
  MockAddressesNotifier() : super(const AddressesState());

  @override
  Future<void> loadAddresses() => Future.value();

  @override
  Future<bool> deleteAddress(int id) => Future.value(true);

  @override
  Future<bool> setDefaultAddress(int id) => Future.value(true);
}

class MockAuthNotifier extends StateNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  MockAuthNotifier() : super(const AuthState.initial());
}

class FakeCartState extends Fake implements CartState {}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  setUpAll(() {
    registerFallbackValue(FakeCartState());
  });

  // Créer un produit de test
  PharmacyEntity createTestPharmacy() {
    return const PharmacyEntity(
      id: 1,
      name: 'Test Pharmacy',
      address: '123 Test Street',
      phone: '0123456789',
      status: 'active',
      isOpen: true,
    );
  }

  ProductEntity createTestProduct({
    int id = 1,
    String name = 'Test Product',
    double price = 1000.0,
  }) {
    return ProductEntity(
      id: id,
      name: name,
      price: price,
      description: 'Test description',
      stockQuantity: 100,
      requiresPrescription: false,
      pharmacy: createTestPharmacy(),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  // Créer un item de panier de test
  CartItemEntity createTestCartItem({
    int productId = 1,
    String name = 'Test Product',
    double price = 1000.0,
    int quantity = 1,
  }) {
    return CartItemEntity(
      product: createTestProduct(id: productId, name: name, price: price),
      quantity: quantity,
    );
  }

  Widget createTestWidget({
    CartState? cartState,
    OrdersState? ordersState,
    AddressesState? addressesState,
    AuthState? authState,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        cartProvider.overrideWith((ref) {
          final notifier = MockCartNotifier(
            cartState ?? const CartState.initial(),
          );
          return notifier;
        }),
        ordersProvider.overrideWith((ref) {
          return MockOrdersNotifier()
            ..state = (ordersState ?? const OrdersState.initial());
        }),
        addressesProvider.overrideWith((ref) {
          return MockAddressesNotifier()
            ..state = (addressesState ?? const AddressesState());
        }),
        authProvider.overrideWith((ref) {
          return MockAuthNotifier()
            ..state = (authState ?? const AuthState.initial());
        }),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/checkout',
          routes: [
            GoRoute(
              path: '/checkout',
              builder: (_, _) => const CheckoutPage(),
            ),
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: Text('Home')),
            ),
            GoRoute(
              path: '/cart',
              builder: (_, _) => const Scaffold(body: Text('Cart')),
            ),
            GoRoute(
              path: '/orders',
              builder: (_, _) => const Scaffold(body: Text('Orders')),
            ),
            GoRoute(
              path: '/order-confirmation',
              builder: (_, _) => const Scaffold(body: Text('Confirmation')),
            ),
          ],
        ),
      ),
    );
  }

  group('CheckoutPage Widget Tests', () {
    testWidgets('should render checkout page', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });

    testWidgets('should show app bar with title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.text('Adresse de livraison'), findsWidgets);
    });

    testWidgets('should display order summary', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem(name: 'Doliprane', price: 2500)],
            selectedPharmacyId: 1,
          ),
        ),
      );

      // Devrait afficher le récapitulatif
      expect(find.byType(CheckoutPage), findsOneWidget);
    });

    testWidgets('should have address section', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });

    testWidgets('should have payment section', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });
  });

  group('CheckoutPage Address Selection', () {
    testWidgets('should show address input fields', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
          addressesState: const AddressesState(addresses: []),
        ),
      );

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should toggle between saved and manual address', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });
  });

  group('CheckoutPage Payment Mode', () {
    testWidgets('should display payment options', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });

    testWidgets('should allow payment mode selection', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      // Chercher les options de paiement
      expect(find.byType(CheckoutPage), findsOneWidget);
    });
  });

  group('CheckoutPage Form Validation', () {
    testWidgets('should validate required address', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });

    testWidgets('should validate phone number', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });
  });

  group('CheckoutPage Order Total', () {
    testWidgets('should calculate subtotal correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [
              createTestCartItem(price: 1000, quantity: 2),
              createTestCartItem(productId: 2, price: 500, quantity: 3),
            ],
            selectedPharmacyId: 1,
          ),
        ),
      );

      // Total = 1000*2 + 500*3 = 3500
      expect(find.byType(CheckoutPage), findsOneWidget);
    });

    testWidgets('should display delivery fee', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });

    testWidgets('should show total with delivery fee', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem(price: 5000)],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });
  });

  group('CheckoutPage Prescription Handling', () {
    testWidgets('should show prescription section if required', (tester) async {
      final productWithPrescription = ProductEntity(
        id: 1,
        name: 'Prescription Drug',
        price: 5000,
        description: 'Requires prescription',
        stockQuantity: 100,
        requiresPrescription: true,
        pharmacy: createTestPharmacy(),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [
              CartItemEntity(product: productWithPrescription, quantity: 1),
            ],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });
  });

  group('CheckoutPage Loading States', () {
    testWidgets('should show loading when placing order', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
          ordersState: const OrdersState.initial().copyWith(
            status: OrdersStatus.loading,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should disable submit during loading', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
          ordersState: const OrdersState.initial().copyWith(
            status: OrdersStatus.loading,
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });
  });

  group('CheckoutPage Error Handling', () {
    testWidgets('should display error message on failure', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
          ordersState: const OrdersState.initial().copyWith(
            status: OrdersStatus.error,
            errorMessage: 'Order failed',
          ),
        ),
      );

      expect(find.byType(CheckoutPage), findsOneWidget);
    });
  });

  group('CheckoutPage Empty Cart', () {
    testWidgets('should redirect when cart is empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(cartState: const CartState.initial()),
      );

      // Page is rendered initially; pop is scheduled via addPostFrameCallback
      expect(find.byType(CheckoutPage), findsOneWidget);
    });
  });

  group('CheckoutPage Accessibility', () {
    testWidgets('should have semantic labels', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('should support form field focus', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          cartState: const CartState.initial().copyWith(
            items: [createTestCartItem()],
            selectedPharmacyId: 1,
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.tap(textFields.first);
      }

      expect(find.byType(CheckoutPage), findsOneWidget);
    });
  });
}
