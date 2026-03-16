import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/orders/presentation/providers/delivery_fee_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {

  setUp(() async {
  SharedPreferences.setMockInitialValues({});
  });

  group('DeliveryFeeProvider Tests', () {
    test('deliveryFeeProvider should be defined', () {
      expect(deliveryFeeProvider, isNotNull);
    });

    test('deliveryFeeProvider should be a StateNotifierProvider', () {
      expect(deliveryFeeProvider, isA<AutoDisposeStateNotifierProvider>());
    });
  });
}
