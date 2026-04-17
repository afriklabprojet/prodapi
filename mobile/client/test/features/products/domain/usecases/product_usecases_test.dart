import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/products/domain/repositories/products_repository.dart';
import 'package:drpharma_client/features/products/domain/usecases/get_products_usecase.dart';
import 'package:drpharma_client/features/products/domain/usecases/search_products_usecase.dart';
import 'package:drpharma_client/features/products/domain/usecases/get_product_details_usecase.dart';
import 'package:drpharma_client/features/products/domain/usecases/get_products_by_category_usecase.dart';

@GenerateMocks([ProductsRepository])
import 'product_usecases_test.mocks.dart';

// Helper
PharmacyEntity _pharmacy() => const PharmacyEntity(
  id: 1,
  name: 'Pharmacie Test',
  address: 'Abidjan',
  phone: '+225',
  status: 'active',
  isOpen: true,
);

ProductEntity _product({int id = 1, String name = 'Doliprane'}) =>
    ProductEntity(
      id: id,
      name: name,
      price: 1500,
      stockQuantity: 10,
      requiresPrescription: false,
      pharmacy: _pharmacy(),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  late MockProductsRepository mockRepo;

  setUp(() {
    mockRepo = MockProductsRepository();
  });

  // ────────────────────────────────────────────────────────────────────────────
  // GetProductsUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetProductsUseCase', () {
    late GetProductsUseCase useCase;

    setUp(() => useCase = GetProductsUseCase(mockRepo));

    test('returns list of products on success', () async {
      final products = [_product(id: 1), _product(id: 2)];
      when(
        mockRepo.getProducts(page: 1),
      ).thenAnswer((_) async => Right(products));

      final result = await useCase(page: 1);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (p) => expect(p.length, 2));
      verify(mockRepo.getProducts(page: 1)).called(1);
    });

    test('delegates page parameter to repository', () async {
      when(
        mockRepo.getProducts(page: 3),
      ).thenAnswer((_) async => const Right([]));
      await useCase(page: 3);
      verify(mockRepo.getProducts(page: 3)).called(1);
    });

    test('returns failure on repository error', () async {
      when(mockRepo.getProducts(page: 1)).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Server down')),
      );

      final result = await useCase(page: 1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns NetworkFailure when network error', () async {
      when(
        mockRepo.getProducts(page: 1),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(page: 1);

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // SearchProductsUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('SearchProductsUseCase', () {
    late SearchProductsUseCase useCase;

    setUp(() => useCase = SearchProductsUseCase(mockRepo));

    test('returns matching products', () async {
      final products = [_product(name: 'Doliprane 500mg')];
      when(
        mockRepo.searchProducts(query: 'doliprane', page: 1, perPage: 20),
      ).thenAnswer((_) async => Right(products));

      final result = await useCase(query: 'doliprane', page: 1, perPage: 20);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (p) => expect(p.first.name, contains('Doliprane')),
      );
    });

    test('defaults page to 1 and perPage to 20', () async {
      when(
        mockRepo.searchProducts(query: 'test', page: 1, perPage: 20),
      ).thenAnswer((_) async => const Right([]));

      await useCase(query: 'test');

      verify(
        mockRepo.searchProducts(query: 'test', page: 1, perPage: 20),
      ).called(1);
    });

    test('returns failure when no results', () async {
      when(
        mockRepo.searchProducts(query: 'xyz', page: 1, perPage: 20),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found')),
      );

      final result = await useCase(query: 'xyz');

      expect(result.isLeft(), isTrue);
    });

    test('passes custom page and perPage', () async {
      when(
        mockRepo.searchProducts(query: 'med', page: 2, perPage: 10),
      ).thenAnswer((_) async => const Right([]));

      await useCase(query: 'med', page: 2, perPage: 10);

      verify(
        mockRepo.searchProducts(query: 'med', page: 2, perPage: 10),
      ).called(1);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // GetProductDetailsUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetProductDetailsUseCase', () {
    late GetProductDetailsUseCase useCase;

    setUp(() => useCase = GetProductDetailsUseCase(mockRepo));

    test('returns product details on success', () async {
      final product = _product(id: 42, name: 'Aspirine');
      when(
        mockRepo.getProductDetails(42),
      ).thenAnswer((_) async => Right(product));

      final result = await useCase(42);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (p) {
        expect(p.id, 42);
        expect(p.name, 'Aspirine');
      });
    });

    test('returns failure for unknown product id', () async {
      when(mockRepo.getProductDetails(999)).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: 'Not found', statusCode: 404)),
      );

      final result = await useCase(999);

      expect(result.isLeft(), isTrue);
    });

    test('calls repository with exact product id', () async {
      when(
        mockRepo.getProductDetails(7),
      ).thenAnswer((_) async => Right(_product(id: 7)));
      await useCase(7);
      verify(mockRepo.getProductDetails(7)).called(1);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // GetProductsByCategoryUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetProductsByCategoryUseCase', () {
    late GetProductsByCategoryUseCase useCase;

    setUp(() => useCase = GetProductsByCategoryUseCase(mockRepo));

    test('calls getProductsByCategory when category provided', () async {
      when(
        mockRepo.getProductsByCategory(
          category: 'medicaments',
          page: 1,
          perPage: 20,
        ),
      ).thenAnswer((_) async => Right([_product()]));

      final result = await useCase(category: 'medicaments');

      expect(result.isRight(), isTrue);
      verify(
        mockRepo.getProductsByCategory(
          category: 'medicaments',
          page: 1,
          perPage: 20,
        ),
      ).called(1);
    });

    test('calls getProducts when category is null', () async {
      when(
        mockRepo.getProducts(page: 1, perPage: 20),
      ).thenAnswer((_) async => Right([_product()]));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      verify(mockRepo.getProducts(page: 1, perPage: 20)).called(1);
    });

    test('passes custom page and perPage', () async {
      when(
        mockRepo.getProductsByCategory(category: 'para', page: 2, perPage: 10),
      ).thenAnswer((_) async => const Right([]));

      await useCase(category: 'para', page: 2, perPage: 10);

      verify(
        mockRepo.getProductsByCategory(category: 'para', page: 2, perPage: 10),
      ).called(1);
    });

    test('returns failure when repository fails', () async {
      when(
        mockRepo.getProductsByCategory(
          category: anyNamed('category'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await useCase(category: 'bad');

      expect(result.isLeft(), isTrue);
    });
  });
}
