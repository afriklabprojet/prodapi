import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_pharmacy/core/errors/failure.dart';
import 'package:drpharma_pharmacy/features/inventory/domain/entities/category_entity.dart';
import 'package:drpharma_pharmacy/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drpharma_pharmacy/features/inventory/presentation/providers/inventory_di_providers.dart';
import 'package:drpharma_pharmacy/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:drpharma_pharmacy/features/inventory/presentation/providers/state/inventory_state.dart';

import '../../../../test_helpers.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;

  setUp(() {
    mockRepository = MockInventoryRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  }

  group('InventoryNotifier', () {
    test('loads products successfully on build', () async {
      final products = TestDataFactory.createProductList(count: 3);
      final categories = [
        const CategoryEntity(id: 1, name: 'Médicaments'),
        const CategoryEntity(id: 2, name: 'Cosmétiques'),
      ];

      when(() => mockRepository.getProducts())
          .thenAnswer((_) async => Right(products));
      when(() => mockRepository.getCategories())
          .thenAnswer((_) async => Right(categories));

      final container = createContainer();
      addTearDown(container.dispose);

      // Trigger build
      container.read(inventoryProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(inventoryProvider);
      expect(state.status, InventoryStatus.loaded);
      expect(state.products, hasLength(3));
      expect(state.categories, hasLength(2));
    });

    test('handles error when products fail to load', () async {
      when(() => mockRepository.getProducts())
          .thenAnswer((_) async => const Left(ServerFailure('Erreur réseau')));
      when(() => mockRepository.getCategories())
          .thenAnswer((_) async => const Right([]));

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(inventoryProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(inventoryProvider);
      expect(state.status, InventoryStatus.error);
      expect(state.errorMessage, 'Erreur réseau');
    });

    test('logs warning when categories fail to load (does not crash)', () async {
      final products = TestDataFactory.createProductList(count: 2);

      when(() => mockRepository.getProducts())
          .thenAnswer((_) async => Right(products));
      when(() => mockRepository.getCategories())
          .thenAnswer((_) async => const Left(ServerFailure('catégories indisponibles')));

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(inventoryProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(inventoryProvider);
      // Products should load fine even if categories fail
      expect(state.status, InventoryStatus.loaded);
      expect(state.products, hasLength(2));
      expect(state.categories, isEmpty);
    });

    test('updates stock optimistically', () async {
      final products = [
        TestDataFactory.createProduct(id: 1, stockQuantity: 50),
      ];

      when(() => mockRepository.getProducts())
          .thenAnswer((_) async => Right(products));
      when(() => mockRepository.getCategories())
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.updateStock(1, 75))
          .thenAnswer((_) async => const Right(null));

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(inventoryProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      await container.read(inventoryProvider.notifier).updateStock(1, 75);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(inventoryProvider);
      final product = state.products.firstWhere((p) => p.id == 1);
      expect(product.stockQuantity, 75);
    });
  });
}
