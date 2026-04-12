import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/features/orders/presentation/widgets/checkout/checkout_promo_section.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/orders/presentation/providers/promo_code_provider.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../../helpers/fake_api_client.dart';

class MockPromoCodeNotifier extends StateNotifier<PromoCodeState>
    with Mock
    implements PromoCodeNotifier {
  MockPromoCodeNotifier([PromoCodeState? state])
    : super(state ?? const PromoCodeState());

  @override
  Future<void> validate(String code, double orderAmount) async {}

  @override
  void clear() {
    state = const PromoCodeState();
  }
}

class MockCartNotifier extends StateNotifier<CartState>
    with Mock
    implements CartNotifier {
  MockCartNotifier([CartState? state])
    : super(state ?? const CartState.initial());
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({PromoCodeState? promoState}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        promoCodeProvider.overrideWith(
          (_) => MockPromoCodeNotifier(promoState),
        ),
        cartProvider.overrideWith((_) => MockCartNotifier()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CheckoutPromoSection()),
        ),
      ),
    );
  }

  group('CheckoutPromoSection Widget Tests', () {
    testWidgets('renders widget', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutPromoSection), findsOneWidget);
    });

    testWidgets('shows "Code promo" title when no discount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Code promo'), findsOneWidget);
    });

    testWidgets('shows discount_outlined icon when no discount', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.discount_outlined), findsOneWidget);
    });

    testWidgets('shows input field with hint text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows Appliquer button when no discount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Appliquer'), findsOneWidget);
    });

    testWidgets('shows spinner when isValidating', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(promoState: const PromoCodeState(isValidating: true)),
      );
      await tester
          .pump(); // don't use pumpAndSettle — CircularProgressIndicator animates forever
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Appliquer'), findsNothing);
    });

    testWidgets('shows error text when error in state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          promoState: const PromoCodeState(error: 'Code invalide'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Code invalide'), findsOneWidget);
    });

    testWidgets('shows "Code promo appliqué" when has discount', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          promoState: const PromoCodeState(code: 'PROMO10', discount: 1000),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Code promo appliqué'), findsOneWidget);
    });

    testWidgets('shows check_circle icon when has discount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          promoState: const PromoCodeState(code: 'PROMO10', discount: 1000),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows code text when has discount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          promoState: const PromoCodeState(code: 'PROMO10', discount: 1000),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PROMO10'), findsOneWidget);
    });

    testWidgets('shows description when available', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          promoState: const PromoCodeState(
            code: 'PROMO10',
            discount: 1000,
            description: 'Réduction de 10%',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Réduction de 10%'), findsOneWidget);
    });

    testWidgets('shows Retirer button when has discount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          promoState: const PromoCodeState(code: 'PROMO10', discount: 1000),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retirer'), findsOneWidget);
    });

    testWidgets('hides input and Appliquer when has discount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          promoState: const PromoCodeState(code: 'PROMO10', discount: 1000),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Appliquer'), findsNothing);
    });

    testWidgets('tap Retirer clears discount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          promoState: const PromoCodeState(code: 'PROMO10', discount: 1000),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();
      // After clearing, input field should reappear
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
