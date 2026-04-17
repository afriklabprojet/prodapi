import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/products/data/datasources/products_local_datasource.dart';
import 'package:drpharma_client/features/products/data/datasources/products_remote_datasource.dart';
import 'package:drpharma_client/features/products/data/models/product_model.dart';
import 'package:drpharma_client/features/products/data/models/pharmacy_model.dart';
import 'package:drpharma_client/features/products/data/repositories/products_repository_impl.dart';

@GenerateMocks([ProductsRemoteDataSource, ProductsLocalDataSource])
import 'products_repository_impl_test.mocks.dart';

void main() {
  late ProductsRepositoryImpl repository;
  late MockProductsRemoteDataSource mockRemoteDataSource;
  late MockProductsLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockProductsRemoteDataSource();
    mockLocalDataSource = MockProductsLocalDataSource();
    repository = ProductsRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  // Helper pour créer un PharmacyModel de test
  PharmacyModel createTestPharmacyModel() {
    return PharmacyModel(
      id: 1,
      name: 'Pharmacie Test',
      address: '123 Rue Test, Abidjan',
      phone: '+2250700000000',
      status: 'active',
      isOpen: true,
    );
  }

  // Helper pour créer un ProductModel de test
  ProductModel createTestProductModel({
    int id = 1,
    String name = 'Doliprane 500mg',
    double price = 1500,
    bool requiresPrescription = false,
  }) {
    return ProductModel(
      id: id,
      name: name,
      price: price,
      description: 'Test description',
      imageUrl: 'https://example.com/image.jpg',
      requiresPrescription: requiresPrescription,
      stockQuantity: 100,
      pharmacy: createTestPharmacyModel(),
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
    );
  }

  group('ProductsRepositoryImpl', () {
    group('getProducts', () {
      test('should return list of products and cache first page', () async {
        // Arrange
        final products = [
          createTestProductModel(id: 1, name: 'Doliprane'),
          createTestProductModel(id: 2, name: 'Aspirine'),
        ];
        when(mockRemoteDataSource.getProducts(page: 1, perPage: 20))
            .thenAnswer((_) async => products);
        when(mockLocalDataSource.cacheProducts(products))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getProducts(page: 1, perPage: 20);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) {
            expect(r.length, 2);
            expect(r[0].name, 'Doliprane');
          },
        );
        verify(mockRemoteDataSource.getProducts(page: 1, perPage: 20)).called(1);
        verify(mockLocalDataSource.cacheProducts(products)).called(1);
      });

      test('should not cache pages other than first', () async {
        // Arrange
        final products = [createTestProductModel(id: 3)];
        when(mockRemoteDataSource.getProducts(page: 2, perPage: 20))
            .thenAnswer((_) async => products);

        // Act
        final result = await repository.getProducts(page: 2, perPage: 20);

        // Assert
        expect(result.isRight(), true);
        verifyNever(mockLocalDataSource.cacheProducts(any));
      });

      test('should return cached products on NetworkException for first page', () async {
        // Arrange
        final cachedProducts = [
          createTestProductModel(id: 1, name: 'Cached Product'),
        ];
        when(mockRemoteDataSource.getProducts(page: 1, perPage: 20)).thenThrow(
          NetworkException(message: 'No connection'),
        );
        when(mockLocalDataSource.getCachedProducts())
            .thenAnswer((_) async => cachedProducts);

        // Act
        final result = await repository.getProducts(page: 1, perPage: 20);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) {
            expect(r.length, 1);
            expect(r[0].name, 'Cached Product');
          },
        );
      });

      test('should return NetworkFailure if no cached products', () async {
        // Arrange
        when(mockRemoteDataSource.getProducts(page: 1, perPage: 20)).thenThrow(
          NetworkException(message: 'No connection'),
        );
        when(mockLocalDataSource.getCachedProducts())
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getProducts(page: 1, perPage: 20);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return NetworkFailure for pages other than first on network error', () async {
        // Arrange
        when(mockRemoteDataSource.getProducts(page: 2, perPage: 20)).thenThrow(
          NetworkException(message: 'No connection'),
        );

        // Act
        final result = await repository.getProducts(page: 2, perPage: 20);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
        verifyNever(mockLocalDataSource.getCachedProducts());
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.getProducts(page: 1, perPage: 20)).thenThrow(
          ServerException(message: 'Server error', statusCode: 500),
        );

        // Act
        final result = await repository.getProducts(page: 1, perPage: 20);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(l, isA<ServerFailure>());
            expect((l as ServerFailure).statusCode, 500);
          },
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(mockRemoteDataSource.getProducts(page: 1, perPage: 20)).thenThrow(
          Exception('Unknown error'),
        );

        // Act
        final result = await repository.getProducts(page: 1, perPage: 20);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('searchProducts', () {
      test('should return search results when successful', () async {
        // Arrange
        final products = [
          createTestProductModel(id: 1, name: 'Doliprane 500mg'),
          createTestProductModel(id: 2, name: 'Doliprane 1000mg'),
        ];
        when(mockRemoteDataSource.searchProducts(
          query: 'Doliprane',
          page: 1,
          perPage: 20,
        )).thenAnswer((_) async => products);

        // Act
        final result = await repository.searchProducts(
          query: 'Doliprane',
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) {
            expect(r.length, 2);
            expect(r[0].name.contains('Doliprane'), true);
          },
        );
      });

      test('should return empty list when no results', () async {
        // Arrange
        when(mockRemoteDataSource.searchProducts(
          query: 'NonExistent',
          page: 1,
          perPage: 20,
        )).thenAnswer((_) async => []);

        // Act
        final result = await repository.searchProducts(
          query: 'NonExistent',
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) => expect(r.isEmpty, true),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.searchProducts(
          query: 'test',
          page: 1,
          perPage: 20,
        )).thenThrow(
          ServerException(message: 'Server error', statusCode: 500),
        );

        // Act
        final result = await repository.searchProducts(
          query: 'test',
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockRemoteDataSource.searchProducts(
          query: 'test',
          page: 1,
          perPage: 20,
        )).thenThrow(
          NetworkException(message: 'No connection'),
        );

        // Act
        final result = await repository.searchProducts(
          query: 'test',
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('getProductDetails', () {
      test('should return product details and cache them', () async {
        // Arrange
        final product = createTestProductModel(id: 1, name: 'Doliprane');
        when(mockRemoteDataSource.getProductDetails(1))
            .thenAnswer((_) async => product);
        when(mockLocalDataSource.cacheProductDetails(product))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getProductDetails(1);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) {
            expect(r.id, 1);
            expect(r.name, 'Doliprane');
          },
        );
        verify(mockLocalDataSource.cacheProductDetails(product)).called(1);
      });

      test('should return cached product on NetworkException', () async {
        // Arrange
        final cachedProduct = createTestProductModel(id: 1, name: 'Cached');
        when(mockRemoteDataSource.getProductDetails(1)).thenThrow(
          NetworkException(message: 'No connection'),
        );
        when(mockLocalDataSource.getCachedProductDetails(1))
            .thenAnswer((_) async => cachedProduct);

        // Act
        final result = await repository.getProductDetails(1);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) => expect(r.name, 'Cached'),
        );
      });

      test('should return NetworkFailure if no cached product', () async {
        // Arrange
        when(mockRemoteDataSource.getProductDetails(1)).thenThrow(
          NetworkException(message: 'No connection'),
        );
        when(mockLocalDataSource.getCachedProductDetails(1))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getProductDetails(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.getProductDetails(1)).thenThrow(
          ServerException(message: 'Not found', statusCode: 404),
        );

        // Act
        final result = await repository.getProductDetails(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(l, isA<ServerFailure>());
            expect((l as ServerFailure).statusCode, 404);
          },
          (r) => fail('Should not return success'),
        );
      });
    });

    group('getProductsByPharmacy', () {
      test('should return products for pharmacy when successful', () async {
        // Arrange
        final products = [
          createTestProductModel(id: 1),
          createTestProductModel(id: 2),
        ];
        when(mockRemoteDataSource.getProductsByPharmacy(
          pharmacyId: 1,
          page: 1,
          perPage: 20,
        )).thenAnswer((_) async => products);

        // Act
        final result = await repository.getProductsByPharmacy(
          pharmacyId: 1,
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) => expect(r.length, 2),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.getProductsByPharmacy(
          pharmacyId: 1,
          page: 1,
          perPage: 20,
        )).thenThrow(
          ServerException(message: 'Server error', statusCode: 500),
        );

        // Act
        final result = await repository.getProductsByPharmacy(
          pharmacyId: 1,
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockRemoteDataSource.getProductsByPharmacy(
          pharmacyId: 1,
          page: 1,
          perPage: 20,
        )).thenThrow(
          NetworkException(message: 'No connection'),
        );

        // Act
        final result = await repository.getProductsByPharmacy(
          pharmacyId: 1,
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });

    group('getProductsByCategory', () {
      test('should return products for category when successful', () async {
        // Arrange
        final products = [
          createTestProductModel(id: 1),
          createTestProductModel(id: 2),
        ];
        when(mockRemoteDataSource.getProductsByCategory(
          category: 'Médicaments',
          page: 1,
          perPage: 20,
        )).thenAnswer((_) async => products);

        // Act
        final result = await repository.getProductsByCategory(
          category: 'Médicaments',
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) => expect(r.length, 2),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        // Arrange
        when(mockRemoteDataSource.getProductsByCategory(
          category: 'Test',
          page: 1,
          perPage: 20,
        )).thenThrow(
          ServerException(message: 'Server error', statusCode: 500),
        );

        // Act
        final result = await repository.getProductsByCategory(
          category: 'Test',
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockRemoteDataSource.getProductsByCategory(
          category: 'Test',
          page: 1,
          perPage: 20,
        )).thenThrow(
          NetworkException(message: 'No connection'),
        );

        // Act
        final result = await repository.getProductsByCategory(
          category: 'Test',
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NetworkFailure>()),
          (r) => fail('Should not return success'),
        );
      });

      test('should return ServerFailure on unknown exception', () async {
        // Arrange
        when(mockRemoteDataSource.getProductsByCategory(
          category: 'Test',
          page: 1,
          perPage: 20,
        )).thenThrow(
          Exception('Unknown error'),
        );

        // Act
        final result = await repository.getProductsByCategory(
          category: 'Test',
          page: 1,
          perPage: 20,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should not return success'),
        );
      });
    });
  });
}
