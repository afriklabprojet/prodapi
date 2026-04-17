import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/products/data/models/product_model.dart';
import 'package:drpharma_client/features/products/data/models/pharmacy_model.dart';
import 'package:drpharma_client/features/products/data/models/category_model.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/category_entity.dart';

// ────────────────────────────────────────────────────────────────────────────
// Helper factories
// ────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _pharmacyJson({
  int id = 1,
  String name = 'Pharmacie du Centre',
  String address = 'Plateau, Abidjan',
  String? phone = '+2250700000001',
  String status = 'active',
  bool isOpen = true,
  String? latitude,
  String? longitude,
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'address': address,
  'phone': ?phone,
  'status': status,
  'is_open': isOpen,
  'latitude': ?latitude,
  'longitude': ?longitude,
};

Map<String, dynamic> _productJson({
  int id = 42,
  String name = 'Paracétamol 500mg',
  String? description = 'Analgésique',
  dynamic price = 1500.0,
  int stockQuantity = 20,
  dynamic discountPrice,
  String? manufacturer = 'Sanofi',
  String? activeIngredient = 'Paracétamol',
  bool requiresPrescription = false,
  Map<String, dynamic>? pharmacy,
  dynamic category,
  dynamic averageRating = 4.5,
  dynamic reviewsCount = 12,
  List<dynamic>? tags,
  String createdAt = '2024-01-01T00:00:00.000Z',
  String updatedAt = '2024-06-01T00:00:00.000Z',
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'description': ?description,
  'price': price,
  'stock_quantity': stockQuantity,
  'discount_price': ?discountPrice,
  'manufacturer': ?manufacturer,
  'active_ingredient': ?activeIngredient,
  'requires_prescription': requiresPrescription,
  'pharmacy': pharmacy ?? _pharmacyJson(),
  'category': ?category,
  'average_rating': ?averageRating,
  'reviews_count': ?reviewsCount,
  'tags': ?tags,
  'created_at': createdAt,
  'updated_at': updatedAt,
};

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // PharmacyModel
  // ────────────────────────────────────────────────────────────────────────────
  group('PharmacyModel', () {
    group('fromJson', () {
      test('parses all standard fields', () {
        final model = PharmacyModel.fromJson(_pharmacyJson());

        expect(model.id, 1);
        expect(model.name, 'Pharmacie du Centre');
        expect(model.address, 'Plateau, Abidjan');
        expect(model.phone, '+2250700000001');
        expect(model.status, 'active');
        expect(model.isOpen, isTrue);
      });

      test('parses id from String', () {
        final json = _pharmacyJson()..['id'] = '7';
        expect(PharmacyModel.fromJson(json).id, 7);
      });

      test('uses default empty address when absent', () {
        final json = <String, dynamic>{
          'id': 1,
          'name': 'Ph',
          'status': 'active',
          'is_open': false,
        };
        expect(PharmacyModel.fromJson(json).address, '');
      });

      test('parses latitude and longitude as double strings', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(latitude: '5.3599517', longitude: '-4.0082563'),
        );
        expect(model.latitude, closeTo(5.35, 0.01));
        expect(model.longitude, closeTo(-4.00, 0.01));
      });

      test('parses latitude and longitude as num', () {
        final json = _pharmacyJson()
          ..['latitude'] = 5.3599517
          ..['longitude'] = -4.0082563;
        final model = PharmacyModel.fromJson(json);
        expect(model.latitude, closeTo(5.35, 0.01));
      });
    });

    group('toEntity', () {
      test('converts to PharmacyEntity', () {
        final entity = PharmacyModel.fromJson(_pharmacyJson()).toEntity();

        expect(entity, isA<PharmacyEntity>());
        expect(entity.id, 1);
        expect(entity.name, 'Pharmacie du Centre');
        expect(entity.isOpen, isTrue);
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // CategoryModel
  // ────────────────────────────────────────────────────────────────────────────
  group('CategoryModel', () {
    group('fromJson', () {
      test('parses standard fields', () {
        final model = CategoryModel.fromJson(<String, dynamic>{
          'id': 3,
          'name': 'Antibiotiques',
          'description': 'Classe ATB',
        });
        expect(model.id, 3);
        expect(model.name, 'Antibiotiques');
        expect(model.description, 'Classe ATB');
      });

      test('parses id from String', () {
        final model = CategoryModel.fromJson(<String, dynamic>{
          'id': '5',
          'name': 'Vitamines',
        });
        expect(model.id, 5);
      });

      test('accepts null description', () {
        final model = CategoryModel.fromJson(<String, dynamic>{
          'id': 1,
          'name': 'Analgésiques',
        });
        expect(model.description, isNull);
      });
    });

    group('toEntity', () {
      test('converts to CategoryEntity', () {
        final entity = CategoryModel(
          id: 2,
          name: 'Vitamines',
          description: 'Vit',
        ).toEntity();
        expect(entity, isA<CategoryEntity>());
        expect(entity.id, 2);
        expect(entity.name, 'Vitamines');
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // ProductModel
  // ────────────────────────────────────────────────────────────────────────────
  group('ProductModel', () {
    group('fromJson — standard cases', () {
      test('parses all fields correctly', () {
        final model = ProductModel.fromJson(_productJson());

        expect(model.id, 42);
        expect(model.name, 'Paracétamol 500mg');
        expect(model.description, 'Analgésique');
        expect(model.price, 1500.0);
        expect(model.stockQuantity, 20);
        expect(model.manufacturer, 'Sanofi');
        expect(model.activeIngredient, 'Paracétamol');
        expect(model.requiresPrescription, isFalse);
        expect(model.averageRating, 4.5);
        expect(model.reviewsCount, 12);
      });

      test('parses id from String', () {
        final json = _productJson()..['id'] = '99';
        expect(ProductModel.fromJson(json).id, 99);
      });

      test('parses price from String', () {
        final model = ProductModel.fromJson(_productJson(price: '2500.0'));
        expect(model.price, 2500.0);
      });

      test('parses price from int (no decimal point)', () {
        final model = ProductModel.fromJson(_productJson(price: 3000));
        expect(model.price, 3000.0);
      });

      test('defaults price to 0.0 when null', () {
        final json = _productJson()..['price'] = null;
        expect(ProductModel.fromJson(json).price, 0.0);
      });

      test('parses discount_price', () {
        final model = ProductModel.fromJson(
          _productJson(discountPrice: 1200.0),
        );
        expect(model.discountPrice, 1200.0);
      });

      test('parses reviews_count from String', () {
        final json = _productJson(reviewsCount: '8');
        expect(ProductModel.fromJson(json).reviewsCount, 8);
      });

      test('parses average_rating from String', () {
        final json = _productJson(averageRating: '3.8');
        expect(ProductModel.fromJson(json).averageRating, 3.8);
      });

      test('parses requires_prescription = true', () {
        final model = ProductModel.fromJson(
          _productJson(requiresPrescription: true),
        );
        expect(model.requiresPrescription, isTrue);
      });
    });

    group('fromJson — category polymorphism', () {
      test('parses category as Map', () {
        final model = ProductModel.fromJson(
          _productJson(
            category: <String, dynamic>{'id': 3, 'name': 'Antibiotiques'},
          ),
        );
        expect(model.category?.name, 'Antibiotiques');
      });

      test('parses category as legacy String', () {
        final model = ProductModel.fromJson(
          _productJson(category: 'Vitamines'),
        );
        expect(model.category?.name, 'Vitamines');
        expect(model.category?.id, 0);
      });

      test('handles null category', () {
        final json = _productJson();
        json.remove('category');
        expect(ProductModel.fromJson(json).category, isNull);
      });
    });

    group('fromJson — tags field', () {
      test('parses tags as list of strings', () {
        final model = ProductModel.fromJson(
          _productJson(tags: ['fièvre', 'douleur']),
        );
        expect(model.tags, ['fièvre', 'douleur']);
      });

      test('parses tags as single string', () {
        final json = _productJson()..['tags'] = 'antidouleur';
        final model = ProductModel.fromJson(json);
        expect(model.tags, ['antidouleur']);
      });

      test('returns null when tags absent', () {
        final json = _productJson();
        json.remove('tags');
        expect(ProductModel.fromJson(json).tags, isNull);
      });
    });

    group('fromJson — null/missing pharmacy', () {
      test('creates placeholder pharmacy when pharmacy is null', () {
        final json = _productJson(pharmacy: null);
        json['pharmacy_id'] = 5;
        json['pharmacy'] = null;
        final model = ProductModel.fromJson(json);
        expect(model.pharmacy, isNotNull);
      });
    });

    group('fromJson — stock_quantity as String', () {
      test('parses stock_quantity from String', () {
        final json = _productJson()..['stock_quantity'] = '15';
        expect(ProductModel.fromJson(json).stockQuantity, 15);
      });
    });

    group('toEntity', () {
      test('converts to ProductEntity with all fields', () {
        final entity = ProductModel.fromJson(_productJson()).toEntity();

        expect(entity, isA<ProductEntity>());
        expect(entity.id, 42);
        expect(entity.name, 'Paracétamol 500mg');
        expect(entity.price, 1500.0);
        expect(entity.stockQuantity, 20);
        expect(entity.requiresPrescription, isFalse);
        expect(entity.pharmacy, isA<PharmacyEntity>());
      });

      test('parses createdAt date', () {
        final entity = ProductModel.fromJson(_productJson()).toEntity();
        expect(entity.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      });

      test('converts category to CategoryEntity when present', () {
        final entity = ProductModel.fromJson(
          _productJson(
            category: <String, dynamic>{'id': 1, 'name': 'Analgésiques'},
          ),
        ).toEntity();
        expect(entity.category?.name, 'Analgésiques');
      });

      test('category is null when not provided', () {
        final json = _productJson();
        json.remove('category');
        expect(ProductModel.fromJson(json).toEntity().category, isNull);
      });

      test('imageUrl falls back to image field', () {
        final json = _productJson()
          ..['image_url'] = null
          ..['image'] = 'products/paracetamol.jpg';
        final entity = ProductModel.fromJson(json).toEntity();
        expect(entity.imageUrl, 'products/paracetamol.jpg');
      });
    });
  });
}
