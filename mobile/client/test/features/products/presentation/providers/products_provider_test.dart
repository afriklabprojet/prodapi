import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/products/presentation/providers/products_provider.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_state.dart';

void main() {
  group('ProductsProvider Tests', () {
    test('productsProvider should be defined', () {
      expect(productsProvider, isNotNull);
    });

    test('productsProvider should be a StateNotifierProvider', () {
      expect(productsProvider, isA<StateNotifierProvider>());
    });

    test('ProductsState should have initial state', () {
      const state = ProductsState.initial();
      expect(state.status, ProductsStatus.initial);
      expect(state.products, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('ProductsState should have loading state', () {
      const state = ProductsState.loading();
      expect(state.status, ProductsStatus.loading);
    });

    test('ProductsState should support copyWith for error', () {
      final state = const ProductsState.initial().copyWith(
        status: ProductsStatus.error,
        errorMessage: 'Test error',
      );
      expect(state.errorMessage, 'Test error');
    });
  });
}
