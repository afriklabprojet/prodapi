import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/loyalty/domain/entities/loyalty_entity.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // LoyaltyTier enum
  // ────────────────────────────────────────────────────────────────────────────
  group('LoyaltyTier', () {
    group('displayName', () {
      test(
        'bronze → Bronze',
        () => expect(LoyaltyTier.bronze.displayName, 'Bronze'),
      );
      test(
        'silver → Silver',
        () => expect(LoyaltyTier.silver.displayName, 'Silver'),
      );
      test('gold → Gold', () => expect(LoyaltyTier.gold.displayName, 'Gold'));
      test(
        'platinum → Platinum',
        () => expect(LoyaltyTier.platinum.displayName, 'Platinum'),
      );
    });

    group('requiredPoints', () {
      test('bronze = 0', () => expect(LoyaltyTier.bronze.requiredPoints, 0));
      test(
        'silver = 500',
        () => expect(LoyaltyTier.silver.requiredPoints, 500),
      );
      test('gold = 2000', () => expect(LoyaltyTier.gold.requiredPoints, 2000));
      test(
        'platinum = 5000',
        () => expect(LoyaltyTier.platinum.requiredPoints, 5000),
      );
    });

    group('nextTierPoints', () {
      test(
        'bronze → 500',
        () => expect(LoyaltyTier.bronze.nextTierPoints, 500),
      );
      test(
        'silver → 2000',
        () => expect(LoyaltyTier.silver.nextTierPoints, 2000),
      );
      test('gold → 5000', () => expect(LoyaltyTier.gold.nextTierPoints, 5000));
      test(
        'platinum → null',
        () => expect(LoyaltyTier.platinum.nextTierPoints, isNull),
      );
    });

    group('discountPercent', () {
      test('bronze = 0%', () => expect(LoyaltyTier.bronze.discountPercent, 0));
      test('silver = 5%', () => expect(LoyaltyTier.silver.discountPercent, 5));
      test('gold = 10%', () => expect(LoyaltyTier.gold.discountPercent, 10));
      test(
        'platinum = 15%',
        () => expect(LoyaltyTier.platinum.discountPercent, 15),
      );
    });

    group('benefits', () {
      test(
        'bronze has 2 benefits',
        () => expect(LoyaltyTier.bronze.benefits.length, 2),
      );
      test(
        'silver has 3 benefits',
        () => expect(LoyaltyTier.silver.benefits.length, 3),
      );
      test(
        'gold has 4 benefits',
        () => expect(LoyaltyTier.gold.benefits.length, 4),
      );
      test(
        'platinum has 6 benefits',
        () => expect(LoyaltyTier.platinum.benefits.length, 6),
      );
    });

    group('fromPoints', () {
      test(
        '0 points → bronze',
        () => expect(LoyaltyTier.fromPoints(0), LoyaltyTier.bronze),
      );
      test(
        '499 points → bronze',
        () => expect(LoyaltyTier.fromPoints(499), LoyaltyTier.bronze),
      );
      test(
        '500 points → silver',
        () => expect(LoyaltyTier.fromPoints(500), LoyaltyTier.silver),
      );
      test(
        '1999 points → silver',
        () => expect(LoyaltyTier.fromPoints(1999), LoyaltyTier.silver),
      );
      test(
        '2000 points → gold',
        () => expect(LoyaltyTier.fromPoints(2000), LoyaltyTier.gold),
      );
      test(
        '4999 points → gold',
        () => expect(LoyaltyTier.fromPoints(4999), LoyaltyTier.gold),
      );
      test(
        '5000 points → platinum',
        () => expect(LoyaltyTier.fromPoints(5000), LoyaltyTier.platinum),
      );
      test(
        '10000 points → platinum',
        () => expect(LoyaltyTier.fromPoints(10000), LoyaltyTier.platinum),
      );
    });

    group('fromString', () {
      test(
        '"silver" → silver',
        () => expect(LoyaltyTier.fromString('silver'), LoyaltyTier.silver),
      );
      test(
        '"gold" → gold',
        () => expect(LoyaltyTier.fromString('gold'), LoyaltyTier.gold),
      );
      test(
        '"platinum" → platinum',
        () => expect(LoyaltyTier.fromString('platinum'), LoyaltyTier.platinum),
      );
      test(
        '"bronze" → bronze',
        () => expect(LoyaltyTier.fromString('bronze'), LoyaltyTier.bronze),
      );
      test(
        'null → bronze',
        () => expect(LoyaltyTier.fromString(null), LoyaltyTier.bronze),
      );
      test(
        'unknown → bronze',
        () => expect(LoyaltyTier.fromString('diamond'), LoyaltyTier.bronze),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // LoyaltyReward
  // ────────────────────────────────────────────────────────────────────────────
  group('LoyaltyReward', () {
    final rewardJson = <String, dynamic>{
      'id': 'reward-1',
      'title': 'Livraison offerte',
      'description': 'Une livraison gratuite',
      'points_cost': 200,
      'type': 'free_delivery',
    };

    test('fromJson parses all fields', () {
      final reward = LoyaltyReward.fromJson(rewardJson);
      expect(reward.id, 'reward-1');
      expect(reward.title, 'Livraison offerte');
      expect(reward.description, 'Une livraison gratuite');
      expect(reward.pointsCost, 200);
      expect(reward.type, 'free_delivery');
    });

    test('defaults when keys absent', () {
      final reward = LoyaltyReward.fromJson(<String, dynamic>{});
      expect(reward.id, '');
      expect(reward.pointsCost, 0);
      expect(reward.type, 'discount');
    });

    test('props include id, title, pointsCost, type', () {
      final reward = LoyaltyReward.fromJson(rewardJson);
      expect(
        reward.props,
        containsAll(['reward-1', 'Livraison offerte', 200, 'free_delivery']),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // LoyaltyEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('LoyaltyEntity', () {
    Map<String, dynamic> _entityJson({
      int totalPoints = 600,
      int availablePoints = 500,
      String tier = 'silver',
      int totalOrders = 8,
      double totalSpent = 15000.0,
      int pointsToNextTier = 1400,
      List<dynamic>? availableRewards,
    }) => <String, dynamic>{
      'total_points': totalPoints,
      'available_points': availablePoints,
      'tier': tier,
      'total_orders': totalOrders,
      'total_spent': totalSpent,
      'points_to_next_tier': pointsToNextTier,
      if (availableRewards != null) 'available_rewards': availableRewards,
    };

    test('fromJson parses all fields', () {
      final entity = LoyaltyEntity.fromJson(_entityJson());
      expect(entity.totalPoints, 600);
      expect(entity.availablePoints, 500);
      expect(entity.tier, LoyaltyTier.silver);
      expect(entity.totalOrders, 8);
      expect(entity.totalSpent, 15000.0);
      expect(entity.pointsToNextTier, 1400);
    });

    test('fromJson defaults for missing fields', () {
      final entity = LoyaltyEntity.fromJson(<String, dynamic>{});
      expect(entity.totalPoints, 0);
      expect(entity.availablePoints, 0);
      expect(entity.tier, LoyaltyTier.bronze);
      expect(entity.totalOrders, 0);
      expect(entity.totalSpent, 0.0);
      expect(entity.availableRewards, isEmpty);
    });

    test('fromJson parses available_rewards', () {
      final entity = LoyaltyEntity.fromJson(
        _entityJson(
          availableRewards: [
            <String, dynamic>{
              'id': 'r1',
              'title': 'R',
              'description': 'D',
              'points_cost': 100,
              'type': 'gift',
            },
          ],
        ),
      );
      expect(entity.availableRewards.length, 1);
      expect(entity.availableRewards[0].id, 'r1');
    });

    group('progressToNextTier', () {
      test('platinum tier → 1.0', () {
        final entity = LoyaltyEntity.fromJson(
          _entityJson(tier: 'platinum', totalPoints: 6000),
        );
        expect(entity.progressToNextTier, 1.0);
      });

      test('silver: 600/500..2000 → 100/1500 ≈ 0.0667', () {
        final entity = LoyaltyEntity.fromJson(
          _entityJson(tier: 'silver', totalPoints: 600),
        );
        // progress = (600 - 500) / (2000 - 500) = 100/1500 ≈ 0.0667
        expect(entity.progressToNextTier, closeTo(100 / 1500, 0.001));
      });

      test('bronze: 200 points → 200/500 = 0.4', () {
        final entity = LoyaltyEntity.fromJson(
          _entityJson(tier: 'bronze', totalPoints: 200),
        );
        expect(entity.progressToNextTier, closeTo(0.4, 0.001));
      });

      test('clamped to 0.0 when below tier min', () {
        final entity = LoyaltyEntity.fromJson(
          _entityJson(tier: 'silver', totalPoints: 400),
        );
        expect(entity.progressToNextTier, 0.0);
      });
    });

    test(
      'props contains totalPoints, availablePoints, tier, totalOrders, totalSpent',
      () {
        final entity = LoyaltyEntity.fromJson(_entityJson());
        expect(
          entity.props,
          containsAll([600, 500, LoyaltyTier.silver, 8, 15000.0]),
        );
      },
    );
  });
}
