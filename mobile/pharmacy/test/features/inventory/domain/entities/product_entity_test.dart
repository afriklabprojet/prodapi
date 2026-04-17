import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/inventory/domain/entities/product_entity.dart';

import '../../../../test_helpers.dart';

void main() {
  group('ProductEntity', () {
    test('should create ProductEntity with required fields', () {
      const product = ProductEntity(
        id: 1,
        name: 'Paracétamol 500mg',
        description: 'Antalgique et antipyrétique',
        price: 500.0,
        stockQuantity: 100,
        category: 'Médicaments',
        requiresPrescription: false,
        isAvailable: true,
      );

      expect(product.id, 1);
      expect(product.name, 'Paracétamol 500mg');
      expect(product.description, 'Antalgique et antipyrétique');
      expect(product.price, 500.0);
      expect(product.stockQuantity, 100);
      expect(product.category, 'Médicaments');
      expect(product.requiresPrescription, false);
      expect(product.isAvailable, true);
    });

    test('should create ProductEntity with all fields', () {
      final expiryDate = DateTime(2027, 12, 31);
      
      final product = ProductEntity(
        id: 1,
        name: 'Amoxicilline 500mg',
        description: 'Antibiotique à large spectre',
        price: 2500.0,
        stockQuantity: 50,
        category: 'Antibiotiques',
        barcode: '3760012345678',
        requiresPrescription: true,
        isAvailable: true,
        brand: 'Generic',
        manufacturer: 'PharmaCorp',
        activeIngredient: 'Amoxicilline trihydratée',
        unit: 'boîte de 12',
        expiryDate: expiryDate,
        usageInstructions: '1 comprimé 3 fois par jour',
        sideEffects: 'Nausées, diarrhée possible',
      );

      expect(product.barcode, '3760012345678');
      expect(product.requiresPrescription, true);
      expect(product.brand, 'Generic');
      expect(product.manufacturer, 'PharmaCorp');
      expect(product.activeIngredient, 'Amoxicilline trihydratée');
      expect(product.unit, 'boîte de 12');
      expect(product.expiryDate, expiryDate);
      expect(product.usageInstructions, '1 comprimé 3 fois par jour');
      expect(product.sideEffects, 'Nausées, diarrhée possible');
    });

    test('should copy ProductEntity with new values', () {
      final original = TestDataFactory.createProduct(
        name: 'Doliprane',
        price: 500.0,
        stockQuantity: 100,
      );

      final updated = original.copyWith(
        price: 600.0,
        stockQuantity: 50,
      );

      expect(updated.id, original.id);
      expect(updated.name, original.name);
      expect(updated.price, 600.0);
      expect(updated.stockQuantity, 50);
    });
  });

  group('ProductEntity Stock Status', () {
    test('should identify product as in stock', () {
      final product = TestDataFactory.createProduct(stockQuantity: 100);

      expect(product.isLowStock, false);
      expect(product.isOutOfStock, false);
    });

    test('should identify product as low stock (1-5)', () {
      final product1 = TestDataFactory.createProduct(stockQuantity: 1);
      final product5 = TestDataFactory.createProduct(stockQuantity: 5);

      expect(product1.isLowStock, true);
      expect(product1.isOutOfStock, false);
      
      expect(product5.isLowStock, true);
      expect(product5.isOutOfStock, false);
    });

    test('should identify product as out of stock', () {
      final product = TestDataFactory.createProduct(stockQuantity: 0);

      expect(product.isLowStock, false);
      expect(product.isOutOfStock, true);
    });

    test('should not be low stock when quantity is 6 or more', () {
      final product = TestDataFactory.createProduct(stockQuantity: 6);

      expect(product.isLowStock, false);
      expect(product.isOutOfStock, false);
    });
  });

  group('ProductEntity Prescription Requirement', () {
    test('should identify products requiring prescription', () {
      final otcProduct = TestDataFactory.createProduct(requiresPrescription: false);
      final rxProduct = TestDataFactory.createProduct(requiresPrescription: true);

      expect(otcProduct.requiresPrescription, false);
      expect(rxProduct.requiresPrescription, true);
    });
  });

  group('ProductEntity Availability', () {
    test('should handle product availability status', () {
      final availableProduct = TestDataFactory.createProduct(isAvailable: true);
      final unavailableProduct = TestDataFactory.createProduct(isAvailable: false);

      expect(availableProduct.isAvailable, true);
      expect(unavailableProduct.isAvailable, false);
    });
  });

  group('ProductEntity List Factory', () {
    test('should create list of products', () {
      final products = TestDataFactory.createProductList(count: 10);

      expect(products.length, 10);
      expect(products[0].id, 1);
      expect(products[9].id, 10);
      
      // Each product should have incrementing stock
      expect(products[0].stockQuantity, 20);
      expect(products[1].stockQuantity, 40);
    });
  });

  group('ProductEntity Category Tests', () {
    test('should handle different product categories', () {
      final medication = TestDataFactory.createProduct(category: 'Médicaments');
      final parapharmacie = TestDataFactory.createProduct(category: 'Parapharmacie');
      final cosmetics = TestDataFactory.createProduct(category: 'Cosmétiques');

      expect(medication.category, 'Médicaments');
      expect(parapharmacie.category, 'Parapharmacie');
      expect(cosmetics.category, 'Cosmétiques');
    });
  });

  group('ProductEntity Barcode Tests', () {
    test('should handle products with barcode', () {
      final productWithBarcode = TestDataFactory.createProduct(
        barcode: '3760012345678',
      );
      final productWithoutBarcode = ProductEntity(
        id: 1,
        name: 'Test',
        description: 'Test',
        price: 100,
        stockQuantity: 10,
        category: 'Test',
        requiresPrescription: false,
        isAvailable: true,
        barcode: null,
      );

      expect(productWithBarcode.barcode, '3760012345678');
      expect(productWithoutBarcode.barcode, isNull);
    });
  });
}
