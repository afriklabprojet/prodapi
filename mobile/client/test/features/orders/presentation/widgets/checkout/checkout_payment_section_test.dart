import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/features/orders/presentation/widgets/checkout/checkout_payment_section.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/orders/presentation/providers/pricing_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/pricing_notifier.dart';
import 'package:drpharma_client/features/orders/domain/entities/pricing_entity.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../../helpers/fake_api_client.dart';

class MockPricingNotifier extends StateNotifier<PricingState>
    with Mock
    implements PricingNotifier {
  MockPricingNotifier([PricingState? state])
    : super(state ?? const PricingState());
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

  Widget createTestWidget({PricingState? pricingState}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        pricingProvider.overrideWith((_) => MockPricingNotifier(pricingState)),
        cartProvider.overrideWith((_) => MockCartNotifier()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CheckoutPaymentSection()),
        ),
      ),
    );
  }

  group('CheckoutPaymentSection Widget Tests', () {
    testWidgets('renders widget', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutPaymentSection), findsOneWidget);
    });

    testWidgets('shows Mode de paiement title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Mode de paiement'), findsOneWidget);
    });

    testWidgets('shows Paiement en ligne option by default', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Paiement en ligne'), findsOneWidget);
    });

    testWidgets('shows phone_android icon for platform payment', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
    });

    testWidgets('shows mobile money subtitle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(
        find.textContaining('mobile money', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('shows Portefeuille option when wallet enabled', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          pricingState: PricingState(
            paymentModes: const PaymentModesEntity(
              platformEnabled: true,
              walletEnabled: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Portefeuille DR-Pharma'), findsOneWidget);
    });

    testWidgets('shows wallet icon when wallet enabled', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          pricingState: PricingState(
            paymentModes: const PaymentModesEntity(
              platformEnabled: true,
              walletEnabled: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });

    testWidgets('shows both cards when multiple payment modes available', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          pricingState: PricingState(
            paymentModes: const PaymentModesEntity(
              platformEnabled: true,
              walletEnabled: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Both modes are shown as Cards
      expect(find.text('Paiement en ligne'), findsOneWidget);
      expect(find.text('Portefeuille DR-Pharma'), findsOneWidget);
    });

    testWidgets('shows check_circle when single payment mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          pricingState: PricingState(
            paymentModes: const PaymentModesEntity(
              platformEnabled: true,
              walletEnabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Single mode shows check_circle instead of custom radio
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows fallback when no modes configured', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          pricingState: PricingState(
            paymentModes: const PaymentModesEntity(
              platformEnabled: false,
              walletEnabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Fallback adds platform mode
      expect(find.text('Paiement en ligne'), findsOneWidget);
    });

    testWidgets('tap wallet option selects it when multiple modes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          pricingState: PricingState(
            paymentModes: const PaymentModesEntity(
              platformEnabled: true,
              walletEnabled: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portefeuille DR-Pharma'));
      await tester.pump();
      expect(find.byType(CheckoutPaymentSection), findsOneWidget);
    });
  });
}
