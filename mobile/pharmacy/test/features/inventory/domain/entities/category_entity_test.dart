import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/inventory/domain/entities/category_entity.dart';

void main() {
  group('CategoryEntity', () {
    test('should create category with required fields', () {
      const category = CategoryEntity(
        id: 1,
        name: 'Médicaments',
        slug: 'medicaments',
      );

      expect(category.id, 1);
      expect(category.name, 'Médicaments');
      expect(category.slug, 'medicaments');
      expect(category.description, isNull);
    });

    test('should create category with description', () {
      const category = CategoryEntity(
        id: 1,
        name: 'Médicaments',
        slug: 'medicaments',
        description: 'Tous les médicaments disponibles',
      );

      expect(category.description, 'Tous les médicaments disponibles');
    });

    test('should handle different category types', () {
      final categories = [
        const CategoryEntity(id: 1, name: 'Médicaments', slug: 'medicaments'),
        const CategoryEntity(id: 2, name: 'Parapharmacie', slug: 'parapharmacie'),
        const CategoryEntity(id: 3, name: 'Cosmétiques', slug: 'cosmetiques'),
        const CategoryEntity(id: 4, name: 'Hygiène', slug: 'hygiene'),
        const CategoryEntity(id: 5, name: 'Bébé & Enfant', slug: 'bebe-enfant'),
      ];

      expect(categories.length, 5);
      expect(categories[0].name, 'Médicaments');
      expect(categories[4].name, 'Bébé & Enfant');
      expect(categories[4].slug, 'bebe-enfant');
    });
  });
}
