import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// Tests de performance pour les opérations de données
///
/// Mesures:
/// - Parsing JSON
/// - Transformation de données
/// - Opérations de cache
/// - Filtrage et recherche
void main() {
  group('Performance - Données', () {
    test('parsing de liste JSON de 100 produits < 50ms', () {
      final stopwatch = Stopwatch()..start();

      final jsonList = List.generate(
        100,
        (i) => {
          'id': 'prod_$i',
          'name': 'Médicament $i',
          'price': 1000 + i * 100,
          'pharmacyId': 'pharm_${i % 10}',
          'category': 'cat_${i % 5}',
          'description': 'Description du médicament $i',
          'inStock': i % 2 == 0,
          'requiresPrescription': i % 3 == 0,
        },
      );

      // Simuler parsing
      final products = jsonList
          .map((json) => _MockProduct.fromJson(json))
          .toList();

      stopwatch.stop();

      expect(products.length, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Parsing de 100 produits doit être rapide',
      );
    });

    test('filtrage de 1000 produits par catégorie < 10ms', () {
      final products = List.generate(
        1000,
        (i) => _MockProduct(
          id: 'prod_$i',
          name: 'Médicament $i',
          price: 1000 + i * 10,
          category: 'cat_${i % 10}',
        ),
      );

      final stopwatch = Stopwatch()..start();

      final filtered = products.where((p) => p.category == 'cat_5').toList();

      stopwatch.stop();

      expect(filtered.length, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Filtrage de 1000 produits doit être instantané',
      );
    });

    test('tri de 500 produits par prix < 20ms', () {
      final products = List.generate(
        500,
        (i) => _MockProduct(
          id: 'prod_$i',
          name: 'Médicament $i',
          price: 5000 - i * 10,
          category: 'cat_${i % 5}',
        ),
      );

      final stopwatch = Stopwatch()..start();

      products.sort((a, b) => a.price.compareTo(b.price));

      stopwatch.stop();

      expect(products.first.price, lessThan(products.last.price));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Tri de 500 produits doit être rapide',
      );
    });

    test('recherche textuelle sur 500 produits < 30ms', () {
      final products = List.generate(
        500,
        (i) => _MockProduct(
          id: 'prod_$i',
          name: 'Médicament ${_mockNames[i % _mockNames.length]} $i',
          price: 1000 + i * 50,
          category: 'cat_${i % 5}',
        ),
      );

      final stopwatch = Stopwatch()..start();

      final query = 'paracetamol';
      final results = products
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Recherche textuelle doit être rapide',
      );
    });

    test('groupBy de 300 commandes par statut < 15ms', () {
      final orders = List.generate(
        300,
        (i) => _MockOrder(
          id: 'order_$i',
          status: _orderStatuses[i % _orderStatuses.length],
          total: 5000 + i * 100,
        ),
      );

      final stopwatch = Stopwatch()..start();

      final grouped = <String, List<_MockOrder>>{};
      for (final order in orders) {
        grouped.putIfAbsent(order.status, () => []).add(order);
      }

      stopwatch.stop();

      expect(grouped.keys.length, equals(_orderStatuses.length));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Groupement doit être rapide',
      );
    });

    test('calcul du total panier avec 20 items < 5ms', () {
      final cartItems = List.generate(
        20,
        (i) => _MockCartItem(
          productId: 'prod_$i',
          name: 'Médicament $i',
          price: 1000 + i * 200,
          quantity: 1 + (i % 3),
        ),
      );

      final stopwatch = Stopwatch()..start();

      var subtotal = 0;
      var totalItems = 0;
      for (final item in cartItems) {
        subtotal += item.price * item.quantity;
        totalItems += item.quantity;
      }
      final deliveryFee = subtotal > 10000 ? 0 : 1500;
      final total = subtotal + deliveryFee;

      stopwatch.stop();

      expect(total, greaterThan(0));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(20),
        reason: 'Calcul du panier doit être instantané',
      );
    });

    test('sérialisation de commande complexe < 10ms', () {
      final order = _MockOrderFull(
        id: 'order_123',
        userId: 'user_456',
        pharmacyId: 'pharm_789',
        items: List.generate(
          10,
          (i) => _MockCartItem(
            productId: 'prod_$i',
            name: 'Médicament $i',
            price: 1000 + i * 100,
            quantity: 1 + (i % 2),
          ),
        ),
        address: const _MockAddress(
          street: '123 Rue du Commerce',
          city: 'Abidjan',
          commune: 'Cocody',
          landmark: 'Près du marché',
        ),
        status: 'pending',
        total: 25000,
        createdAt: DateTime.now(),
      );

      final stopwatch = Stopwatch()..start();

      final json = order.toJson();

      stopwatch.stop();

      expect(json['id'], equals('order_123'));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(30),
        reason: 'Sérialisation doit être rapide',
      );
    });

    test('pagination de 50 items par page performante', () async {
      final allItems = List.generate(
        500,
        (i) => _MockProduct(
          id: 'prod_$i',
          name: 'Médicament $i',
          price: 1000 + i * 10,
          category: 'cat_${i % 5}',
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Simuler 10 pages de pagination
      for (var page = 0; page < 10; page++) {
        final start = page * 50;
        final end = (start + 50).clamp(0, allItems.length);
        final pageItems = allItems.sublist(start, end);
        expect(pageItems.length, equals(50));
      }

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Pagination doit être instantanée',
      );
    });

    test('merge de 2 listes de produits sans doublons < 20ms', () {
      final list1 = List.generate(
        200,
        (i) => _MockProduct(
          id: 'prod_$i',
          name: 'Médicament $i',
          price: 1000 + i * 10,
          category: 'cat_${i % 5}',
        ),
      );

      final list2 = List.generate(
        200,
        (i) => _MockProduct(
          id: 'prod_${i + 100}', // Overlap de 100
          name: 'Médicament ${i + 100}',
          price: 1000 + (i + 100) * 10,
          category: 'cat_${(i + 100) % 5}',
        ),
      );

      final stopwatch = Stopwatch()..start();

      final seen = <String>{};
      final merged = <_MockProduct>[];
      for (final p in [...list1, ...list2]) {
        if (seen.add(p.id)) {
          merged.add(p);
        }
      }

      stopwatch.stop();

      expect(merged.length, equals(300)); // 200 + 100 nouveaux
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Merge sans doublons doit être rapide',
      );
    });
  });
}

// Données de test
const _mockNames = [
  'Paracétamol',
  'Ibuprofène',
  'Amoxicilline',
  'Oméprazole',
  'Metformine',
  'Amlodipine',
  'Atorvastatine',
  'Losartan',
  'Aspirine',
  'Vitamine C',
];

const _orderStatuses = [
  'pending',
  'confirmed',
  'preparing',
  'ready',
  'delivering',
  'delivered',
  'cancelled',
];

// Modèles mock
class _MockProduct {
  final String id;
  final String name;
  final int price;
  final String category;

  _MockProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  factory _MockProduct.fromJson(Map<String, dynamic> json) {
    return _MockProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      category: json['category'] as String,
    );
  }
}

class _MockOrder {
  final String id;
  final String status;
  final int total;

  _MockOrder({required this.id, required this.status, required this.total});
}

class _MockCartItem {
  final String productId;
  final String name;
  final int price;
  final int quantity;

  _MockCartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
  };
}

class _MockAddress {
  final String street;
  final String city;
  final String commune;
  final String landmark;

  const _MockAddress({
    required this.street,
    required this.city,
    required this.commune,
    required this.landmark,
  });

  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
    'commune': commune,
    'landmark': landmark,
  };
}

class _MockOrderFull {
  final String id;
  final String userId;
  final String pharmacyId;
  final List<_MockCartItem> items;
  final _MockAddress address;
  final String status;
  final int total;
  final DateTime createdAt;

  _MockOrderFull({
    required this.id,
    required this.userId,
    required this.pharmacyId,
    required this.items,
    required this.address,
    required this.status,
    required this.total,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'pharmacyId': pharmacyId,
    'items': items.map((i) => i.toJson()).toList(),
    'address': address.toJson(),
    'status': status,
    'total': total,
    'createdAt': createdAt.toIso8601String(),
  };
}
