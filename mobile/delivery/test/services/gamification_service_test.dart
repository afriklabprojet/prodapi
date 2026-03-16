import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/gamification_service.dart';

void main() {
  group('BadgeType', () {
    test('should have all expected values', () {
      expect(BadgeType.values.length, 7);
      expect(BadgeType.deliveries.index, 0);
      expect(BadgeType.distance.index, 1);
      expect(BadgeType.speed.index, 2);
      expect(BadgeType.rating.index, 3);
      expect(BadgeType.streak.index, 4);
      expect(BadgeType.earnings.index, 5);
      expect(BadgeType.special.index, 6);
    });
  });

  group('BadgeRarity', () {
    test('should have all expected values', () {
      expect(BadgeRarity.values.length, 5);
      expect(BadgeRarity.common.index, 0);
      expect(BadgeRarity.uncommon.index, 1);
      expect(BadgeRarity.rare.index, 2);
      expect(BadgeRarity.epic.index, 3);
      expect(BadgeRarity.legendary.index, 4);
    });
  });

  group('Badge', () {
    test('should create with required properties', () {
      const badge = Badge(
        id: 'test_badge',
        name: 'Test Badge',
        description: 'A test badge',
        iconAsset: 'assets/test.png',
        type: BadgeType.deliveries,
        rarity: BadgeRarity.rare,
        requirement: 100,
      );

      expect(badge.id, 'test_badge');
      expect(badge.name, 'Test Badge');
      expect(badge.description, 'A test badge');
      expect(badge.iconAsset, 'assets/test.png');
      expect(badge.type, BadgeType.deliveries);
      expect(badge.rarity, BadgeRarity.rare);
      expect(badge.requirement, 100);
      expect(badge.xpReward, 100);
      expect(badge.isUnlocked, false);
      expect(badge.progress, 0);
    });

    test('isUnlocked should return true when unlockedAt is set', () {
      final badge = const Badge(
        id: 'unlocked',
        name: 'Unlocked',
        description: 'Test',
        iconAsset: 'test.png',
        type: BadgeType.special,
        rarity: BadgeRarity.common,
        requirement: 1,
      ).copyWith(unlockedAt: DateTime.now());

      expect(badge.isUnlocked, true);
    });

    test('rarityColor should return correct colors', () {
      const commonBadge = Badge(
        id: 'common',
        name: 'Common',
        description: '',
        iconAsset: '',
        type: BadgeType.deliveries,
        rarity: BadgeRarity.common,
        requirement: 10,
      );
      expect(commonBadge.rarityColor, Colors.grey);

      const uncommonBadge = Badge(
        id: 'uncommon',
        name: 'Uncommon',
        description: '',
        iconAsset: '',
        type: BadgeType.deliveries,
        rarity: BadgeRarity.uncommon,
        requirement: 50,
      );
      expect(uncommonBadge.rarityColor, Colors.green);

      const rareBadge = Badge(
        id: 'rare',
        name: 'Rare',
        description: '',
        iconAsset: '',
        type: BadgeType.deliveries,
        rarity: BadgeRarity.rare,
        requirement: 100,
      );
      expect(rareBadge.rarityColor, Colors.blue);

      const epicBadge = Badge(
        id: 'epic',
        name: 'Epic',
        description: '',
        iconAsset: '',
        type: BadgeType.deliveries,
        rarity: BadgeRarity.epic,
        requirement: 500,
      );
      expect(epicBadge.rarityColor, Colors.purple);

      const legendaryBadge = Badge(
        id: 'legendary',
        name: 'Legendary',
        description: '',
        iconAsset: '',
        type: BadgeType.deliveries,
        rarity: BadgeRarity.legendary,
        requirement: 1000,
      );
      expect(legendaryBadge.rarityColor, Colors.orange);
    });

    test('rarityName should return correct French names', () {
      const common = Badge(
        id: '1', name: '', description: '', iconAsset: '',
        type: BadgeType.deliveries, rarity: BadgeRarity.common, requirement: 1,
      );
      expect(common.rarityName, 'Commun');

      const uncommon = Badge(
        id: '2', name: '', description: '', iconAsset: '',
        type: BadgeType.deliveries, rarity: BadgeRarity.uncommon, requirement: 1,
      );
      expect(uncommon.rarityName, 'Peu commun');

      const rare = Badge(
        id: '3', name: '', description: '', iconAsset: '',
        type: BadgeType.deliveries, rarity: BadgeRarity.rare, requirement: 1,
      );
      expect(rare.rarityName, 'Rare');

      const epic = Badge(
        id: '4', name: '', description: '', iconAsset: '',
        type: BadgeType.deliveries, rarity: BadgeRarity.epic, requirement: 1,
      );
      expect(epic.rarityName, 'Épique');

      const legendary = Badge(
        id: '5', name: '', description: '', iconAsset: '',
        type: BadgeType.deliveries, rarity: BadgeRarity.legendary, requirement: 1,
      );
      expect(legendary.rarityName, 'Légendaire');
    });

    test('copyWith should update specified fields', () {
      const badge = Badge(
        id: 'test',
        name: 'Test',
        description: 'Test',
        iconAsset: 'test.png',
        type: BadgeType.deliveries,
        rarity: BadgeRarity.common,
        requirement: 10,
      );

      final now = DateTime.now();
      final updated = badge.copyWith(
        unlockedAt: now,
        progress: 0.5,
      );

      expect(updated.unlockedAt, now);
      expect(updated.progress, 0.5);
      expect(updated.id, 'test');
    });
  });

  group('CourierLevel', () {
    test('should create with all properties', () {
      const level = CourierLevel(
        level: 5,
        title: 'Expert',
        minXp: 1000,
        maxXp: 1500,
        perks: ['Perk 1', 'Perk 2'],
      );

      expect(level.level, 5);
      expect(level.title, 'Expert');
      expect(level.minXp, 1000);
      expect(level.maxXp, 1500);
      expect(level.perks.length, 2);
    });

    test('progressToNext should calculate correctly', () {
      const level = CourierLevel(
        level: 1,
        title: 'Débutant',
        minXp: 0,
        maxXp: 100,
        perks: [],
      );

      expect(level.progressToNext(0), 0.0);
      expect(level.progressToNext(50), 0.5);
      expect(level.progressToNext(100), 1.0);
      expect(level.progressToNext(150), 1.0); // Capped at 1.0
    });

    test('xpToNext should calculate correctly', () {
      const level = CourierLevel(
        level: 1,
        title: 'Débutant',
        minXp: 0,
        maxXp: 100,
        perks: [],
      );

      expect(level.xpToNext(0), 100);
      expect(level.xpToNext(50), 50);
      expect(level.xpToNext(100), 0);
    });
  });

  group('DailyChallenge', () {
    test('should create with required properties', () {
      final challenge = DailyChallenge(
        id: 'daily_1',
        title: 'Coursier Actif',
        description: 'Effectuer 5 livraisons',
        icon: Icons.delivery_dining,
        target: 5,
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );

      expect(challenge.id, 'daily_1');
      expect(challenge.title, 'Coursier Actif');
      expect(challenge.target, 5);
      expect(challenge.current, 0);
      expect(challenge.xpReward, 50);
      expect(challenge.bonusReward, 500);
      expect(challenge.isCompleted, false);
    });

    test('progress should calculate correctly', () {
      final challenge = DailyChallenge(
        id: 'test',
        title: 'Test',
        description: 'Test',
        icon: Icons.star,
        target: 10,
        current: 5,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(challenge.progress, 0.5);
    });

    test('progress should be capped at 1.0', () {
      final challenge = DailyChallenge(
        id: 'test',
        title: 'Test',
        description: 'Test',
        icon: Icons.star,
        target: 5,
        current: 10,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(challenge.progress, 1.0);
    });

    test('timeRemaining should show hours when > 1 hour', () {
      final challenge = DailyChallenge(
        id: 'test',
        title: 'Test',
        description: 'Test',
        icon: Icons.star,
        target: 5,
        expiresAt: DateTime.now().add(const Duration(hours: 3)),
      );

      expect(challenge.timeRemaining, contains('h restantes'));
    });

    test('timeRemaining should show minutes when < 1 hour', () {
      final challenge = DailyChallenge(
        id: 'test',
        title: 'Test',
        description: 'Test',
        icon: Icons.star,
        target: 5,
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );

      expect(challenge.timeRemaining, contains('min restantes'));
    });

    test('timeRemaining should show Expiré when past', () {
      final challenge = DailyChallenge(
        id: 'test',
        title: 'Test',
        description: 'Test',
        icon: Icons.star,
        target: 5,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(challenge.timeRemaining, 'Expiré');
    });

    test('copyWith should update specified fields', () {
      final challenge = DailyChallenge(
        id: 'test',
        title: 'Test',
        description: 'Test',
        icon: Icons.star,
        target: 5,
        expiresAt: DateTime.now(),
      );

      final updated = challenge.copyWith(current: 3, isCompleted: true);

      expect(updated.current, 3);
      expect(updated.isCompleted, true);
      expect(updated.id, 'test');
    });
  });

  group('DailyStreak', () {
    test('should create with default values', () {
      const streak = DailyStreak();

      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.lastDeliveryDate, isNull);
      expect(streak.weekHistory, isEmpty);
    });

    test('isActiveToday should return false when no delivery', () {
      const streak = DailyStreak();
      expect(streak.isActiveToday, false);
    });

    test('isActiveToday should return true for today delivery', () {
      final today = DateTime.now();
      final streak = DailyStreak(lastDeliveryDate: today);
      expect(streak.isActiveToday, true);
    });

    test('isActiveToday should return false for yesterday delivery', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final streak = DailyStreak(lastDeliveryDate: yesterday);
      expect(streak.isActiveToday, false);
    });

    test('streakMultiplier should return correct values', () {
      const streak0 = DailyStreak(currentStreak: 0);
      expect(streak0.streakMultiplier, 0);

      const streak5 = DailyStreak(currentStreak: 5);
      expect(streak5.streakMultiplier, 0);

      const streak7 = DailyStreak(currentStreak: 7);
      expect(streak7.streakMultiplier, 1);

      const streak14 = DailyStreak(currentStreak: 14);
      expect(streak14.streakMultiplier, 2);

      const streak30 = DailyStreak(currentStreak: 30);
      expect(streak30.streakMultiplier, 3);
    });
  });

  group('courierLevels', () {
    test('should have 10 levels', () {
      expect(courierLevels.length, 10);
    });

    test('levels should be in order', () {
      for (int i = 0; i < courierLevels.length - 1; i++) {
        expect(courierLevels[i].level, lessThan(courierLevels[i + 1].level));
        expect(courierLevels[i].maxXp, courierLevels[i + 1].minXp);
      }
    });

    test('first level should start at 0 XP', () {
      expect(courierLevels.first.minXp, 0);
    });

    test('each level should have a title', () {
      for (final level in courierLevels) {
        expect(level.title, isNotEmpty);
      }
    });
  });

  group('allBadges', () {
    test('should have multiple badges', () {
      expect(allBadges.length, greaterThan(10));
    });

    test('each badge should have unique id', () {
      final ids = allBadges.map((b) => b.id).toSet();
      expect(ids.length, allBadges.length);
    });

    test('should have badges for each type', () {
      final types = allBadges.map((b) => b.type).toSet();
      expect(types, contains(BadgeType.deliveries));
      expect(types, contains(BadgeType.distance));
      expect(types, contains(BadgeType.streak));
      expect(types, contains(BadgeType.special));
    });

    test('should have badges for each rarity', () {
      final rarities = allBadges.map((b) => b.rarity).toSet();
      expect(rarities, contains(BadgeRarity.common));
      expect(rarities, contains(BadgeRarity.uncommon));
      expect(rarities, contains(BadgeRarity.rare));
      expect(rarities, contains(BadgeRarity.epic));
      expect(rarities, contains(BadgeRarity.legendary));
    });
  });

  group('GamificationState', () {
    test('should create with default values', () {
      final state = GamificationState(currentLevel: courierLevels.first);

      expect(state.totalXp, 0);
      expect(state.currentLevel.level, 1);
      expect(state.badges, isEmpty);
      expect(state.dailyChallenges, isEmpty);
      expect(state.streak.currentStreak, 0);
      expect(state.totalDeliveries, 0);
      expect(state.totalDistance, 0);
      expect(state.averageRating, 0);
      expect(state.totalEarnings, 0);
    });

    test('copyWith should update specified fields', () {
      final state = GamificationState(currentLevel: courierLevels.first);

      final updated = state.copyWith(
        totalXp: 500,
        totalDeliveries: 50,
        totalDistance: 100.5,
      );

      expect(updated.totalXp, 500);
      expect(updated.totalDeliveries, 50);
      expect(updated.totalDistance, 100.5);
      expect(updated.currentLevel.level, 1);
    });
  });
}
