import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/gamification.dart';

void main() {
  group('CourierLevel', () {
    test('fromJson creates level correctly', () {
      final json = {
        'level': 1,
        'title': 'Bronze',
        'current_xp': 250,
        'required_xp': 500,
        'total_xp': 250,
        'color': 'bronze',
        'perks': ['Bonus 5%'],
      };

      final level = CourierLevel.fromJson(json);

      expect(level.level, 1);
      expect(level.title, 'Bronze');
      expect(level.currentXP, 250);
      expect(level.requiredXP, 500);
      expect(level.totalXP, 250);
      expect(level.perks, ['Bonus 5%']);
    });

    test('progress is calculated correctly', () {
      final level = CourierLevel(
        level: 1,
        title: 'Bronze',
        currentXP: 250,
        requiredXP: 500,
        totalXP: 250,
        color: Colors.grey,
      );

      expect(level.progress, 0.5);
    });

    test('xpToNextLevel returns correct value', () {
      final level = CourierLevel(
        level: 1,
        title: 'Bronze',
        currentXP: 250,
        requiredXP: 500,
        totalXP: 250,
        color: Colors.grey,
      );

      expect(level.xpToNextLevel, 250);
    });

    test('icon returns correct icon for level', () {
      final level1 = CourierLevel(
        level: 1,
        title: 'test',
        currentXP: 0,
        requiredXP: 100,
        totalXP: 0,
        color: Colors.grey,
      );
      final level10 = CourierLevel(
        level: 10,
        title: 'test',
        currentXP: 0,
        requiredXP: 100,
        totalXP: 0,
        color: Colors.grey,
      );
      final level50 = CourierLevel(
        level: 50,
        title: 'test',
        currentXP: 0,
        requiredXP: 100,
        totalXP: 0,
        color: Colors.grey,
      );

      expect(level1.icon, Icons.star_border);
      expect(level10.icon, Icons.star);
      expect(level50.icon, Icons.diamond);
    });
  });

  group('GamificationBadge', () {
    test('fromJson creates badge correctly', () {
      final json = {
        'id': 'badge_1',
        'name': 'Premier pas',
        'description': 'Effectuer votre première livraison',
        'icon': 'star',
        'color': 'gold',
        'is_unlocked': true,
        'required_value': 1,
        'current_value': 1,
        'category': 'delivery',
      };

      final badge = GamificationBadge.fromJson(json);

      expect(badge.id, 'badge_1');
      expect(badge.name, 'Premier pas');
      expect(badge.isUnlocked, true);
      expect(badge.category, 'delivery');
    });

    test('progress is calculated correctly', () {
      const badge = GamificationBadge(
        id: 'test',
        name: 'Test',
        description: 'Test description',
        iconName: 'star',
        color: Colors.blue,
        requiredValue: 10,
        currentValue: 5,
      );

      expect(badge.progress, 0.5);
    });

    test('progress is clamped to 1.0', () {
      const badge = GamificationBadge(
        id: 'test',
        name: 'Test',
        description: 'Test description',
        iconName: 'star',
        color: Colors.blue,
        requiredValue: 10,
        currentValue: 15,
      );

      expect(badge.progress, 1.0);
    });

    test('icon returns correct icon for iconName', () {
      const badge = GamificationBadge(
        id: 'test',
        name: 'Test',
        description: 'Test',
        iconName: 'star',
        color: Colors.blue,
      );

      expect(badge.icon, Icons.star);
    });

    test('icon maps all known iconNames', () {
      final iconMap = {
        'star': Icons.star,
        'delivery': Icons.local_shipping,
        'speed': Icons.speed,
        'timer': Icons.timer,
        'fire': Icons.local_fire_department,
        'trophy': Icons.emoji_events,
        'crown': Icons.workspace_premium,
        'medal': Icons.military_tech,
        'rocket': Icons.rocket_launch,
        'lightning': Icons.bolt,
        'heart': Icons.favorite,
        'thumbup': Icons.thumb_up,
        'diamond': Icons.diamond,
        'verified': Icons.verified,
        'streak': Icons.whatshot,
      };
      for (final entry in iconMap.entries) {
        final badge = GamificationBadge(
          id: 'test',
          name: 'T',
          description: 'D',
          iconName: entry.key,
          color: Colors.blue,
        );
        expect(badge.icon, entry.value, reason: 'icon for ${entry.key}');
      }
    });

    test('icon defaults to star for unknown iconName', () {
      const badge = GamificationBadge(
        id: 'test',
        name: 'T',
        description: 'D',
        iconName: 'unknown',
        color: Colors.blue,
      );
      expect(badge.icon, Icons.star);
    });

    test('progress returns 0 when requiredValue is 0', () {
      const badge = GamificationBadge(
        id: 'test',
        name: 'T',
        description: 'D',
        iconName: 'star',
        color: Colors.blue,
        requiredValue: 0,
        currentValue: 5,
      );
      expect(badge.progress, 0.0);
    });

    test('fromJson handles defaults for missing fields', () {
      final badge = GamificationBadge.fromJson({});
      expect(badge.id, '');
      expect(badge.name, '');
      expect(badge.iconName, 'star');
      expect(badge.isUnlocked, false);
      expect(badge.requiredValue, 1);
      expect(badge.currentValue, 0);
      expect(badge.category, 'general');
      expect(badge.unlockedAt, isNull);
    });

    test('fromJson parses all color strings', () {
      final colors = [
        'gold',
        'silver',
        'bronze',
        'green',
        'blue',
        'purple',
        'red',
        'orange',
      ];
      for (final c in colors) {
        final badge = GamificationBadge.fromJson({'color': c});
        expect(badge.color, isNotNull, reason: 'color for $c');
      }
    });

    test('fromJson defaults color for null', () {
      final badge = GamificationBadge.fromJson({});
      expect(badge.color, Colors.blue);
    });

    test('fromJson defaults color for unknown string', () {
      final badge = GamificationBadge.fromJson({'color': 'neon'});
      expect(badge.color, Colors.blue);
    });
  });

  // ── LeaderboardEntry ────────────────────────────
  group('LeaderboardEntry', () {
    test('fromJson parses all fields', () {
      final entry = LeaderboardEntry.fromJson({
        'rank': 1,
        'courier_id': 42,
        'name': 'Ahmed',
        'avatar': 'https://example.com/pic.jpg',
        'deliveries_count': 150,
        'score': 9500,
        'level': 15,
      });
      expect(entry.rank, 1);
      expect(entry.courierId, 42);
      expect(entry.courierName, 'Ahmed');
      expect(entry.avatarUrl, 'https://example.com/pic.jpg');
      expect(entry.deliveriesCount, 150);
      expect(entry.score, 9500);
      expect(entry.level, 15);
      expect(entry.isCurrentUser, false);
    });

    test('fromJson uses courier_name fallback', () {
      final entry = LeaderboardEntry.fromJson({
        'courier_name': 'Fallback Name',
      });
      expect(entry.courierName, 'Fallback Name');
    });

    test('fromJson uses id fallback for courier_id', () {
      final entry = LeaderboardEntry.fromJson({'id': 99});
      expect(entry.courierId, 99);
    });

    test('fromJson uses total_deliveries fallback', () {
      final entry = LeaderboardEntry.fromJson({'total_deliveries': 200});
      expect(entry.deliveriesCount, 200);
    });

    test('fromJson uses points fallback for score', () {
      final entry = LeaderboardEntry.fromJson({'points': 3000});
      expect(entry.score, 3000);
    });

    test('fromJson uses avatar_url fallback', () {
      final entry = LeaderboardEntry.fromJson({
        'avatar_url': 'https://example.com/alt.jpg',
      });
      expect(entry.avatarUrl, 'https://example.com/alt.jpg');
    });

    test('fromJson defaults missing fields', () {
      final entry = LeaderboardEntry.fromJson({});
      expect(entry.rank, 0);
      expect(entry.courierId, 0);
      expect(entry.courierName, 'Inconnu');
      expect(entry.avatarUrl, isNull);
      expect(entry.deliveriesCount, 0);
      expect(entry.score, 0);
      expect(entry.level, 1);
    });

    test('fromJson with isCurrentUser flag', () {
      final entry = LeaderboardEntry.fromJson({'rank': 5}, isCurrentUser: true);
      expect(entry.isCurrentUser, true);
    });

    test('rankColor returns gold for rank 1', () {
      final entry = LeaderboardEntry.fromJson({'rank': 1});
      expect(entry.rankColor, const Color(0xFFFFD700));
    });

    test('rankColor returns silver for rank 2', () {
      final entry = LeaderboardEntry.fromJson({'rank': 2});
      expect(entry.rankColor, const Color(0xFFC0C0C0));
    });

    test('rankColor returns bronze for rank 3', () {
      final entry = LeaderboardEntry.fromJson({'rank': 3});
      expect(entry.rankColor, const Color(0xFFCD7F32));
    });

    test('rankColor returns grey for rank > 3', () {
      final entry = LeaderboardEntry.fromJson({'rank': 10});
      expect(entry.rankColor, Colors.grey);
    });

    test('rankIcon returns emoji_events for rank 1', () {
      final entry = LeaderboardEntry.fromJson({'rank': 1});
      expect(entry.rankIcon, Icons.emoji_events);
    });

    test('rankIcon returns workspace_premium for rank 2', () {
      final entry = LeaderboardEntry.fromJson({'rank': 2});
      expect(entry.rankIcon, Icons.workspace_premium);
    });

    test('rankIcon returns military_tech for rank 3', () {
      final entry = LeaderboardEntry.fromJson({'rank': 3});
      expect(entry.rankIcon, Icons.military_tech);
    });

    test('rankIcon returns null for rank > 3', () {
      final entry = LeaderboardEntry.fromJson({'rank': 10});
      expect(entry.rankIcon, isNull);
    });
  });

  // ── CourierLevel additional tests ───────────────
  group('CourierLevel additional', () {
    test('icon for level 20', () {
      final lvl = CourierLevel(
        level: 20,
        title: 'T',
        currentXP: 0,
        requiredXP: 100,
        totalXP: 0,
        color: Colors.grey,
      );
      expect(lvl.icon, Icons.military_tech);
    });

    test('icon for level 30', () {
      final lvl = CourierLevel(
        level: 30,
        title: 'T',
        currentXP: 0,
        requiredXP: 100,
        totalXP: 0,
        color: Colors.grey,
      );
      expect(lvl.icon, Icons.emoji_events);
    });

    test('icon for level 40', () {
      final lvl = CourierLevel(
        level: 40,
        title: 'T',
        currentXP: 0,
        requiredXP: 100,
        totalXP: 0,
        color: Colors.grey,
      );
      expect(lvl.icon, Icons.workspace_premium);
    });

    test('fromJson parses platinum color', () {
      final lvl = CourierLevel.fromJson({'color': 'platinum'});
      expect(lvl.color, const Color(0xFFE5E4E2));
    });

    test('fromJson parses diamond color', () {
      final lvl = CourierLevel.fromJson({'color': 'diamond'});
      expect(lvl.color, const Color(0xFFB9F2FF));
    });

    test('fromJson defaults missing fields', () {
      final lvl = CourierLevel.fromJson({});
      expect(lvl.level, 1);
      expect(lvl.title, 'Débutant');
      expect(lvl.currentXP, 0);
      expect(lvl.requiredXP, 100);
      expect(lvl.totalXP, 0);
      expect(lvl.perks, isEmpty);
    });

    test('progress returns 0 when requiredXP is 0', () {
      final lvl = CourierLevel(
        level: 1,
        title: 'T',
        currentXP: 50,
        requiredXP: 0,
        totalXP: 0,
        color: Colors.grey,
      );
      expect(lvl.progress, 0.0);
    });
  });

  // ── ChallengeDifficulty extension ───────────────
  group('ChallengeDifficulty', () {
    test('label returns correct strings', () {
      expect(ChallengeDifficulty.easy.label, 'Facile');
      expect(ChallengeDifficulty.medium.label, 'Moyen');
      expect(ChallengeDifficulty.hard.label, 'Difficile');
      expect(ChallengeDifficulty.legendary.label, 'Légendaire');
    });

    test('color returns correct colors', () {
      expect(ChallengeDifficulty.easy.color, Colors.green);
      expect(ChallengeDifficulty.medium.color, Colors.blue);
      expect(ChallengeDifficulty.hard.color, Colors.orange);
      expect(ChallengeDifficulty.legendary.color, Colors.purple);
    });

    test('xpMultiplier returns correct values', () {
      expect(ChallengeDifficulty.easy.xpMultiplier, 1);
      expect(ChallengeDifficulty.medium.xpMultiplier, 2);
      expect(ChallengeDifficulty.hard.xpMultiplier, 3);
      expect(ChallengeDifficulty.legendary.xpMultiplier, 5);
    });
  });

  // ── ChallengeType ───────────────────────────────
  group('ChallengeType', () {
    test('has all expected values', () {
      expect(ChallengeType.values.length, 7);
      expect(ChallengeType.deliveries.index, 0);
      expect(ChallengeType.earnings.index, 1);
      expect(ChallengeType.distance.index, 2);
      expect(ChallengeType.speed.index, 3);
      expect(ChallengeType.rating.index, 4);
      expect(ChallengeType.streak.index, 5);
      expect(ChallengeType.special.index, 6);
    });
  });

  // ── DailyChallenge ──────────────────────────────
  group('DailyChallenge', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'daily_3',
        'title': 'Trio du jour',
        'description': 'Effectuez 3 livraisons',
        'type': 'deliveries',
        'difficulty': 'easy',
        'target_value': 3,
        'current_value': 1,
        'xp_reward': 50,
        'bonus_reward': 500,
        'expires_at': '2030-12-31T23:59:59.000',
        'is_completed': false,
        'is_claimed': false,
      };
      final challenge = DailyChallenge.fromJson(json);
      expect(challenge.id, 'daily_3');
      expect(challenge.title, 'Trio du jour');
      expect(challenge.description, 'Effectuez 3 livraisons');
      expect(challenge.type, ChallengeType.deliveries);
      expect(challenge.difficulty, ChallengeDifficulty.easy);
      expect(challenge.targetValue, 3);
      expect(challenge.currentValue, 1);
      expect(challenge.xpReward, 50);
      expect(challenge.bonusReward, 500);
      expect(challenge.isCompleted, false);
      expect(challenge.isClaimed, false);
    });

    test('fromJson handles all challenge types', () {
      final types = {
        'deliveries': ChallengeType.deliveries,
        'earnings': ChallengeType.earnings,
        'distance': ChallengeType.distance,
        'speed': ChallengeType.speed,
        'rating': ChallengeType.rating,
        'streak': ChallengeType.streak,
        'special': ChallengeType.special,
      };
      for (final entry in types.entries) {
        final c = DailyChallenge.fromJson({'type': entry.key});
        expect(c.type, entry.value, reason: 'type for ${entry.key}');
      }
    });

    test('fromJson defaults unknown type to deliveries', () {
      final c = DailyChallenge.fromJson({'type': 'unknown'});
      expect(c.type, ChallengeType.deliveries);
    });

    test('fromJson handles all difficulties', () {
      final diffs = {
        'easy': ChallengeDifficulty.easy,
        'medium': ChallengeDifficulty.medium,
        'hard': ChallengeDifficulty.hard,
        'legendary': ChallengeDifficulty.legendary,
      };
      for (final entry in diffs.entries) {
        final c = DailyChallenge.fromJson({'difficulty': entry.key});
        expect(
          c.difficulty,
          entry.value,
          reason: 'difficulty for ${entry.key}',
        );
      }
    });

    test('fromJson defaults unknown difficulty to easy', () {
      final c = DailyChallenge.fromJson({'difficulty': 'impossible'});
      expect(c.difficulty, ChallengeDifficulty.easy);
    });

    test('fromJson defaults missing fields', () {
      final c = DailyChallenge.fromJson({});
      expect(c.id, '');
      expect(c.title, '');
      expect(c.targetValue, 1);
      expect(c.currentValue, 0);
      expect(c.xpReward, 50);
      expect(c.bonusReward, isNull);
      expect(c.isCompleted, false);
      expect(c.isClaimed, false);
    });

    test('progress is calculated correctly', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 10,
        currentValue: 7,
        xpReward: 50,
        expiresAt: _farFuture,
      );
      expect(c.progress, 0.7);
    });

    test('progress clamped to 1.0 when over target', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 5,
        currentValue: 10,
        xpReward: 50,
        expiresAt: _farFuture,
      );
      expect(c.progress, 1.0);
    });

    test('progress returns 0 when targetValue is 0', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 0,
        currentValue: 5,
        xpReward: 50,
        expiresAt: _farFuture,
      );
      expect(c.progress, 0.0);
    });

    test('isExpired returns true for past date', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 1,
        xpReward: 50,
        expiresAt: DateTime(2020, 1, 1),
      );
      expect(c.isExpired, true);
    });

    test('isExpired returns false for future date', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 1,
        xpReward: 50,
        expiresAt: _farFuture,
      );
      expect(c.isExpired, false);
    });

    test('timeRemainingLabel returns Expiré for past date', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 1,
        xpReward: 50,
        expiresAt: DateTime(2020, 1, 1),
      );
      expect(c.timeRemainingLabel, 'Expiré');
    });

    test('timeRemainingLabel shows hours for long remaining', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 1,
        xpReward: 50,
        expiresAt: DateTime.now().add(const Duration(hours: 5, minutes: 30)),
      );
      expect(c.timeRemainingLabel, contains('h'));
    });

    test('timeRemainingLabel shows minutes for short remaining', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 1,
        xpReward: 50,
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );
      expect(c.timeRemainingLabel, contains('m'));
    });

    test('icon maps each ChallengeType correctly', () {
      final typeIcons = {
        ChallengeType.deliveries: Icons.local_shipping,
        ChallengeType.earnings: Icons.attach_money,
        ChallengeType.distance: Icons.straighten,
        ChallengeType.speed: Icons.bolt,
        ChallengeType.rating: Icons.star,
        ChallengeType.streak: Icons.local_fire_department,
        ChallengeType.special: Icons.auto_awesome,
      };
      for (final entry in typeIcons.entries) {
        final c = DailyChallenge(
          id: 'x',
          title: 'x',
          description: 'x',
          type: entry.key,
          difficulty: ChallengeDifficulty.easy,
          targetValue: 1,
          xpReward: 50,
          expiresAt: _farFuture,
        );
        expect(c.icon, entry.value, reason: 'icon for ${entry.key}');
      }
    });
  });

  // ── DailyChallengesData ─────────────────────────
  group('DailyChallengesData', () {
    test('fromJson parses all fields', () {
      final json = {
        'challenges': [
          {
            'id': 'c1',
            'type': 'deliveries',
            'difficulty': 'easy',
            'target_value': 3,
            'xp_reward': 50,
          },
          {
            'id': 'c2',
            'type': 'earnings',
            'difficulty': 'medium',
            'target_value': 5000,
            'xp_reward': 100,
          },
        ],
        'completed_today': 1,
        'total_xp_today': 50,
        'current_streak': 5,
        'next_refresh': '2030-12-31T00:00:00.000',
      };
      final data = DailyChallengesData.fromJson(json);
      expect(data.challenges.length, 2);
      expect(data.completedToday, 1);
      expect(data.totalXpEarnedToday, 50);
      expect(data.currentStreak, 5);
      expect(data.nextRefresh, isNotNull);
    });

    test('fromJson defaults missing fields', () {
      final data = DailyChallengesData.fromJson({});
      expect(data.challenges, isEmpty);
      expect(data.completedToday, 0);
      expect(data.totalXpEarnedToday, 0);
      expect(data.currentStreak, 0);
      expect(data.nextRefresh, isNull);
    });

    test('activeChallenges filters expired and claimed', () {
      final data = DailyChallengesData(
        challenges: [
          DailyChallenge(
            id: 'active',
            title: 'Active',
            description: 'x',
            type: ChallengeType.deliveries,
            difficulty: ChallengeDifficulty.easy,
            targetValue: 3,
            xpReward: 50,
            expiresAt: _farFuture,
          ),
          DailyChallenge(
            id: 'expired',
            title: 'Expired',
            description: 'x',
            type: ChallengeType.deliveries,
            difficulty: ChallengeDifficulty.easy,
            targetValue: 3,
            xpReward: 50,
            expiresAt: DateTime(2020, 1, 1),
          ),
          DailyChallenge(
            id: 'claimed',
            title: 'Claimed',
            description: 'x',
            type: ChallengeType.deliveries,
            difficulty: ChallengeDifficulty.easy,
            targetValue: 3,
            xpReward: 50,
            expiresAt: _farFuture,
            isClaimed: true,
          ),
        ],
      );
      expect(data.activeChallenges.length, 1);
      expect(data.activeChallenges.first.id, 'active');
    });

    test('completedChallenges filters by isCompleted', () {
      final data = DailyChallengesData(
        challenges: [
          DailyChallenge(
            id: 'done',
            title: 'Done',
            description: 'x',
            type: ChallengeType.deliveries,
            difficulty: ChallengeDifficulty.easy,
            targetValue: 3,
            xpReward: 50,
            expiresAt: _farFuture,
            isCompleted: true,
          ),
          DailyChallenge(
            id: 'todo',
            title: 'Todo',
            description: 'x',
            type: ChallengeType.deliveries,
            difficulty: ChallengeDifficulty.easy,
            targetValue: 3,
            xpReward: 50,
            expiresAt: _farFuture,
          ),
        ],
      );
      expect(data.completedChallenges.length, 1);
      expect(data.completedChallenges.first.id, 'done');
    });

    test('claimableChallenges filters completed but not claimed', () {
      final data = DailyChallengesData(
        challenges: [
          DailyChallenge(
            id: 'claimable',
            title: 'Claimable',
            description: 'x',
            type: ChallengeType.deliveries,
            difficulty: ChallengeDifficulty.easy,
            targetValue: 3,
            xpReward: 50,
            expiresAt: _farFuture,
            isCompleted: true,
            isClaimed: false,
          ),
          DailyChallenge(
            id: 'already_claimed',
            title: 'Claimed',
            description: 'x',
            type: ChallengeType.deliveries,
            difficulty: ChallengeDifficulty.easy,
            targetValue: 3,
            xpReward: 50,
            expiresAt: _farFuture,
            isCompleted: true,
            isClaimed: true,
          ),
          DailyChallenge(
            id: 'not_done',
            title: 'Not done',
            description: 'x',
            type: ChallengeType.deliveries,
            difficulty: ChallengeDifficulty.easy,
            targetValue: 3,
            xpReward: 50,
            expiresAt: _farFuture,
          ),
        ],
      );
      expect(data.claimableChallenges.length, 1);
      expect(data.claimableChallenges.first.id, 'claimable');
    });
  });

  // ── GamificationData ──────────────────────────────
  group('GamificationData', () {
    test('fromJson parses complex data', () {
      final json = {
        'level': {
          'level': 5,
          'title': 'Apprenti',
          'current_xp': 400,
          'required_xp': 500,
          'total_xp': 1400,
          'color': 'silver',
        },
        'badges': [
          {'id': 'b1', 'name': 'Badge1', 'is_unlocked': true},
          {'id': 'b2', 'name': 'Badge2', 'is_unlocked': false},
        ],
        'recent_badges': [
          {'id': 'b1', 'name': 'Badge1'},
        ],
        'leaderboard': [
          {'rank': 1, 'name': 'Top', 'score': 9999},
        ],
        'my_rank': {'rank': 42, 'name': 'Me', 'score': 100},
        'stats': {'deliveries': 150, 'distance': 500},
      };
      final data = GamificationData.fromJson(json);
      expect(data.level.level, 5);
      expect(data.badges.length, 2);
      expect(data.recentBadges.length, 1);
      expect(data.leaderboard.length, 1);
      expect(data.currentUserRank, isNotNull);
      expect(data.currentUserRank!.isCurrentUser, true);
      expect(data.stats['deliveries'], 150);
    });

    test('fromJson defaults missing fields', () {
      final data = GamificationData.fromJson({});
      expect(data.badges, isEmpty);
      expect(data.recentBadges, isEmpty);
      expect(data.leaderboard, isEmpty);
      expect(data.currentUserRank, isNull);
      expect(data.stats, isEmpty);
    });

    test('unlockedBadges filters correctly', () {
      final data = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [
          const GamificationBadge(
            id: '1',
            name: 'A',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            isUnlocked: true,
          ),
          const GamificationBadge(
            id: '2',
            name: 'B',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            isUnlocked: false,
          ),
          const GamificationBadge(
            id: '3',
            name: 'C',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            isUnlocked: true,
          ),
        ],
      );
      expect(data.unlockedBadges.length, 2);
    });

    test('lockedBadges filters correctly', () {
      final data = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [
          const GamificationBadge(
            id: '1',
            name: 'A',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            isUnlocked: true,
          ),
          const GamificationBadge(
            id: '2',
            name: 'B',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            isUnlocked: false,
          ),
        ],
      );
      expect(data.lockedBadges.length, 1);
      expect(data.lockedBadges.first.id, '2');
    });

    test('badgesByCategory groups correctly', () {
      final data = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [
          const GamificationBadge(
            id: '1',
            name: 'A',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            category: 'speed',
          ),
          const GamificationBadge(
            id: '2',
            name: 'B',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            category: 'speed',
          ),
          const GamificationBadge(
            id: '3',
            name: 'C',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            category: 'delivery',
          ),
        ],
      );
      expect(data.badgesByCategory.keys, containsAll(['speed', 'delivery']));
      expect(data.badgesByCategory['speed']!.length, 2);
      expect(data.badgesByCategory['delivery']!.length, 1);
    });
  });

  // ── LevelDefinitions ─────────────────────────────
  group('LevelDefinitions', () {
    test('levels list has expected entries', () {
      expect(LevelDefinitions.levels.length, 8);
      expect(LevelDefinitions.levels.first['title'], 'Débutant');
      expect(LevelDefinitions.levels.last['title'], 'Légende');
    });

    test('getTitleForLevel returns correct titles', () {
      expect(LevelDefinitions.getTitleForLevel(1), 'Débutant');
      expect(LevelDefinitions.getTitleForLevel(5), 'Apprenti');
      expect(LevelDefinitions.getTitleForLevel(10), 'Confirmé');
      expect(LevelDefinitions.getTitleForLevel(15), 'Expert');
      expect(LevelDefinitions.getTitleForLevel(20), 'Vétéran');
      expect(LevelDefinitions.getTitleForLevel(30), 'Maître');
      expect(LevelDefinitions.getTitleForLevel(40), 'Champion');
      expect(LevelDefinitions.getTitleForLevel(50), 'Légende');
    });

    test('getTitleForLevel returns Débutant for level 0', () {
      expect(LevelDefinitions.getTitleForLevel(0), 'Débutant');
    });

    test('getTitleForLevel returns highest matching title', () {
      expect(LevelDefinitions.getTitleForLevel(99), 'Légende');
      expect(LevelDefinitions.getTitleForLevel(25), 'Vétéran');
    });
  });

  // ── BadgeDefinitions ──────────────────────────────
  group('BadgeDefinitions', () {
    test('badges list has entries', () {
      expect(BadgeDefinitions.badges.length, greaterThan(0));
    });

    test('each badge has required fields', () {
      for (final badge in BadgeDefinitions.badges) {
        expect(badge['id'], isNotNull);
        expect(badge['name'], isNotNull);
        expect(badge['icon'], isNotNull);
        expect(badge['color'], isNotNull);
        expect(badge['category'], isNotNull);
      }
    });

    test('badges have unique ids', () {
      final ids = BadgeDefinitions.badges.map((b) => b['id']).toSet();
      expect(ids.length, BadgeDefinitions.badges.length);
    });

    test('badges have known categories', () {
      final validCategories = {
        'deliveries',
        'speed',
        'rating',
        'streak',
        'general',
      };
      for (final badge in BadgeDefinitions.badges) {
        expect(
          validCategories,
          contains(badge['category']),
          reason: '${badge['id']} has unknown category ${badge['category']}',
        );
      }
    });
  });

  // ── GamificationBadge._parseColor all branches ────
  group('GamificationBadge color parsing', () {
    test('gold color', () {
      final badge = GamificationBadge.fromJson({'color': 'gold'});
      expect(badge.color, const Color(0xFFFFD700));
    });

    test('silver color', () {
      final badge = GamificationBadge.fromJson({'color': 'silver'});
      expect(badge.color, const Color(0xFFC0C0C0));
    });

    test('bronze color', () {
      final badge = GamificationBadge.fromJson({'color': 'bronze'});
      expect(badge.color, const Color(0xFFCD7F32));
    });

    test('green color', () {
      final badge = GamificationBadge.fromJson({'color': 'green'});
      expect(badge.color, Colors.green);
    });

    test('blue color', () {
      final badge = GamificationBadge.fromJson({'color': 'blue'});
      expect(badge.color, Colors.blue);
    });

    test('purple color', () {
      final badge = GamificationBadge.fromJson({'color': 'purple'});
      expect(badge.color, Colors.purple);
    });

    test('red color', () {
      final badge = GamificationBadge.fromJson({'color': 'red'});
      expect(badge.color, Colors.red);
    });

    test('orange color', () {
      final badge = GamificationBadge.fromJson({'color': 'orange'});
      expect(badge.color, Colors.orange);
    });

    test('case insensitive color parsing', () {
      final badge = GamificationBadge.fromJson({'color': 'GOLD'});
      expect(badge.color, const Color(0xFFFFD700));
    });
  });

  // ── CourierLevel._parseColor all branches ─────────
  group('CourierLevel color parsing', () {
    test('bronze color', () {
      final lvl = CourierLevel.fromJson({'color': 'bronze'});
      expect(lvl.color, const Color(0xFFCD7F32));
    });

    test('silver color', () {
      final lvl = CourierLevel.fromJson({'color': 'silver'});
      expect(lvl.color, const Color(0xFFC0C0C0));
    });

    test('gold color', () {
      final lvl = CourierLevel.fromJson({'color': 'gold'});
      expect(lvl.color, const Color(0xFFFFD700));
    });

    test('default color for unknown', () {
      final lvl = CourierLevel.fromJson({'color': 'neon'});
      expect(lvl.color, Colors.blue);
    });

    test('default color for null', () {
      final lvl = CourierLevel.fromJson({});
      expect(lvl.color, Colors.grey);
    });
  });

  // ── CourierLevel progress edge cases ──────────────
  group('CourierLevel progress edge cases', () {
    test('progress clamped to 1.0 when over max', () {
      final lvl = CourierLevel(
        level: 1,
        title: 'T',
        currentXP: 200,
        requiredXP: 100,
        totalXP: 200,
        color: Colors.grey,
      );
      expect(lvl.progress, 1.0);
    });

    test('xpToNextLevel negative when over max', () {
      final lvl = CourierLevel(
        level: 1,
        title: 'T',
        currentXP: 200,
        requiredXP: 100,
        totalXP: 200,
        color: Colors.grey,
      );
      expect(lvl.xpToNextLevel, -100);
    });

    test('xpToNextLevel zero at max', () {
      final lvl = CourierLevel(
        level: 1,
        title: 'T',
        currentXP: 100,
        requiredXP: 100,
        totalXP: 100,
        color: Colors.grey,
      );
      expect(lvl.xpToNextLevel, 0);
    });
  });

  // ── LeaderboardEntry edge cases ───────────────────
  group('LeaderboardEntry edge cases', () {
    test('rank 0 returns grey and null icon', () {
      final entry = LeaderboardEntry.fromJson({'rank': 0});
      expect(entry.rankColor, Colors.grey);
      expect(entry.rankIcon, isNull);
    });

    test('negative rank returns grey', () {
      final entry = LeaderboardEntry.fromJson({'rank': -1});
      expect(entry.rankColor, Colors.grey);
    });
  });

  // ── DailyChallenge edge cases ─────────────────────
  group('DailyChallenge edge cases', () {
    test('timeRemaining is negative for expired', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 1,
        xpReward: 50,
        expiresAt: DateTime(2020, 1, 1),
      );
      expect(c.timeRemaining.isNegative, true);
    });

    test('timeRemaining is positive for future', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 1,
        xpReward: 50,
        expiresAt: _farFuture,
      );
      expect(c.timeRemaining.isNegative, false);
    });

    test('bonusReward can be null', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 1,
        xpReward: 50,
        expiresAt: _farFuture,
      );
      expect(c.bonusReward, isNull);
    });

    test('bonusReward can be set', () {
      final c = DailyChallenge(
        id: 'x',
        title: 'x',
        description: 'x',
        type: ChallengeType.deliveries,
        difficulty: ChallengeDifficulty.easy,
        targetValue: 1,
        xpReward: 50,
        bonusReward: 1000,
        expiresAt: _farFuture,
      );
      expect(c.bonusReward, 1000);
    });
  });

  // ── ChallengeDefinitions ──────────────────────────
  group('ChallengeDefinitions', () {
    test('getDailyChallenges returns list', () {
      final challenges = ChallengeDefinitions.getDailyChallenges();
      expect(challenges, isNotEmpty);
    });

    test('each daily challenge has required fields', () {
      final challenges = ChallengeDefinitions.getDailyChallenges();
      for (final c in challenges) {
        expect(c['id'], isNotNull);
        expect(c['title'], isNotNull);
        expect(c['description'], isNotNull);
        expect(c['type'], isNotNull);
        expect(c['difficulty'], isNotNull);
        expect(c['target_value'], isNotNull);
        expect(c['xp_reward'], isNotNull);
        expect(c['expires_at'], isNotNull);
      }
    });

    test('daily challenges have unique ids', () {
      final challenges = ChallengeDefinitions.getDailyChallenges();
      final ids = challenges.map((c) => c['id']).toSet();
      expect(ids.length, challenges.length);
    });

    test('daily challenges expire at end of today', () {
      final challenges = ChallengeDefinitions.getDailyChallenges();
      final now = DateTime.now();
      for (final c in challenges) {
        final expiresAt = DateTime.parse(c['expires_at']);
        expect(expiresAt.year, now.year);
        expect(expiresAt.month, now.month);
        expect(expiresAt.day, now.day);
      }
    });

    test('daily challenges can be parsed into DailyChallenge', () {
      final challenges = ChallengeDefinitions.getDailyChallenges();
      for (final c in challenges) {
        final parsed = DailyChallenge.fromJson(c);
        expect(parsed.id, isNotEmpty);
        expect(parsed.targetValue, greaterThan(0));
      }
    });
  });

  // ── GamificationData edge cases ───────────────────
  group('GamificationData edge cases', () {
    test('empty badges gives empty categorized maps', () {
      final data = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [],
      );
      expect(data.unlockedBadges, isEmpty);
      expect(data.lockedBadges, isEmpty);
      expect(data.badgesByCategory, isEmpty);
    });

    test('all badges unlocked', () {
      final data = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [
          const GamificationBadge(
            id: '1',
            name: 'A',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            isUnlocked: true,
          ),
          const GamificationBadge(
            id: '2',
            name: 'B',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            isUnlocked: true,
          ),
        ],
      );
      expect(data.unlockedBadges.length, 2);
      expect(data.lockedBadges, isEmpty);
    });

    test('all badges locked', () {
      final data = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [
          const GamificationBadge(
            id: '1',
            name: 'A',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            isUnlocked: false,
          ),
          const GamificationBadge(
            id: '2',
            name: 'B',
            description: '',
            iconName: 'star',
            color: Colors.blue,
            isUnlocked: false,
          ),
        ],
      );
      expect(data.unlockedBadges, isEmpty);
      expect(data.lockedBadges.length, 2);
    });
  });
}

/// A far-future date for DailyChallenge tests
final _farFuture = DateTime(2099, 12, 31);
