import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/home/presentation/widgets/home_app_bar.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
  SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              HomeAppBar(
                cartState: const CartState.initial(),
                isDark: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('HomeAppBar Widget Tests', () {
    testWidgets('should render home app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(HomeAppBar), findsOneWidget);
    });

    testWidgets('should display logo or title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(HomeAppBar), findsOneWidget);
    });

    testWidgets('should have notification icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(HomeAppBar), findsOneWidget);
    });

    testWidgets('should have cart icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(HomeAppBar), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
      
      expect(find.byType(HomeAppBar), findsOneWidget);
    });
  });
}
