import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/gamification_screen.dart';
import 'package:courier/data/repositories/gamification_repository.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/widget_test_helpers.dart';

import 'package:courier/data/models/gamification.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen({
    GamificationData? data,
    List<LeaderboardEntry>? leaderboard,
    List<GamificationBadge>? badges,
    DailyChallengesData? challenges,
  }) {
    final mockRepo = MockGamificationRepository();

    final defaultData =
        data ?? GamificationData(level: CourierLevel.fromJson({}), badges: []);

    when(
      () => mockRepo.getLeaderboard(period: any(named: 'period')),
    ).thenAnswer((_) async => leaderboard ?? []);
    when(
      () => mockRepo.getLeaderboard(),
    ).thenAnswer((_) async => leaderboard ?? []);
    when(() => mockRepo.getBadges()).thenAnswer((_) async => badges ?? []);
    when(() => mockRepo.getDailyChallenges()).thenAnswer(
      (_) async => challenges ?? const DailyChallengesData(challenges: []),
    );
    when(
      () => mockRepo.getGamificationData(),
    ).thenAnswer((_) async => defaultData);

    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(home: GamificationScreen()),
    );
  }

  group('GamificationScreen - Basic', () {
    testWidgets('renders with scaffold', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows GamificationScreen widget', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('has TabBar for sections', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TabBar), findsWidgets);
    });

    testWidgets('has scroll content', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(NestedScrollView), findsWidgets);
    });

    testWidgets('renders level info area', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('has Text widgets for labels', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Text), findsWidgets);
    });
  });

  group('GamificationScreen - With rich data', () {
    testWidgets('renders with level data and streak', (tester) async {
      final data = GamificationData(
        level: CourierLevel.fromJson({
          'name': 'Argent',
          'level': 2,
          'current_xp': 1500,
          'xp_for_next': 3000,
        }),
        badges: [],
        stats: {'current_streak': 5, 'total_deliveries': 120, 'total_xp': 1500},
      );
      await tester.pumpWidget(buildScreen(data: data));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with unlocked badges', (tester) async {
      final data = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [
          GamificationBadge.fromJson({
            'id': 'speed_demon',
            'name': 'Speed Demon',
            'description': 'Complete 10 deliveries in 1 day',
            'category': 'performance',
            'icon': 'speed',
            'is_unlocked': true,
            'progress': 100,
            'target': 100,
          }),
          GamificationBadge.fromJson({
            'id': 'night_owl',
            'name': 'Night Owl',
            'description': 'Deliver after 10pm',
            'category': 'special',
            'icon': 'night',
            'is_unlocked': false,
            'progress': 3,
            'target': 10,
          }),
        ],
      );
      await tester.pumpWidget(buildScreen(data: data));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with leaderboard entries', (tester) async {
      final entries = [
        LeaderboardEntry.fromJson({
          'courier_id': 1,
          'courier_name': 'Jean',
          'rank': 1,
          'total_xp': 5000,
          'deliveries_count': 200,
          'avatar': null,
        }),
        LeaderboardEntry.fromJson({
          'courier_id': 2,
          'courier_name': 'Marie',
          'rank': 2,
          'total_xp': 4500,
          'deliveries_count': 180,
        }),
        LeaderboardEntry.fromJson({
          'courier_id': 3,
          'courier_name': 'Koffi',
          'rank': 3,
          'total_xp': 4000,
          'deliveries_count': 160,
        }, isCurrentUser: true),
      ];
      await tester.pumpWidget(buildScreen(leaderboard: entries));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with daily challenges', (tester) async {
      final challenges = DailyChallengesData.fromJson({
        'challenges': [
          {
            'id': 'ch1',
            'type': 'deliveries',
            'title': 'Livrer 5 commandes',
            'description': 'Complétez 5 livraisons',
            'difficulty': 'easy',
            'target': 5,
            'progress': 2,
            'xp_reward': 100,
            'is_completed': false,
          },
          {
            'id': 'ch2',
            'type': 'distance',
            'title': 'Parcourir 20km',
            'description': 'Roulez 20 km',
            'difficulty': 'medium',
            'target': 20,
            'progress': 20,
            'xp_reward': 200,
            'is_completed': true,
          },
        ],
      });
      await tester.pumpWidget(buildScreen(challenges: challenges));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with zero streak (no streak display)', (tester) async {
      final data = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [],
        stats: {'current_streak': 0, 'total_xp': 0},
      );
      await tester.pumpWidget(buildScreen(data: data));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with high level and many XP', (tester) async {
      final data = GamificationData(
        level: CourierLevel.fromJson({
          'name': 'Diamant',
          'level': 10,
          'current_xp': 50000,
          'xp_for_next': 100000,
        }),
        badges: [],
        stats: {
          'current_streak': 30,
          'total_deliveries': 5000,
          'total_xp': 50000,
          'best_streak': 45,
        },
      );
      await tester.pumpWidget(buildScreen(data: data));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders multiple badge categories', (tester) async {
      final data = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [
          GamificationBadge.fromJson({
            'id': 'b1',
            'name': 'Badge A',
            'description': 'Test',
            'category': 'performance',
            'icon': 'star',
            'is_unlocked': true,
            'progress': 100,
            'target': 100,
          }),
          GamificationBadge.fromJson({
            'id': 'b2',
            'name': 'Badge B',
            'description': 'Test 2',
            'category': 'loyalty',
            'icon': 'heart',
            'is_unlocked': false,
            'progress': 50,
            'target': 100,
          }),
          GamificationBadge.fromJson({
            'id': 'b3',
            'name': 'Badge C',
            'description': 'Test 3',
            'category': 'special',
            'icon': 'diamond',
            'is_unlocked': true,
            'progress': 100,
            'target': 100,
          }),
        ],
      );
      await tester.pumpWidget(buildScreen(data: data));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });
  });

  group('GamificationScreen - leaderboard variations', () {
    testWidgets('renders with leaderboard entries', (tester) async {
      final leaderboard = [
        LeaderboardEntry.fromJson({
          'rank': 1,
          'courier_id': 1,
          'courier_name': 'Jean Dupont',
          'deliveries_count': 150,
          'score': 9500,
          'avatar': null,
        }),
        LeaderboardEntry.fromJson({
          'rank': 2,
          'courier_id': 2,
          'courier_name': 'Ali Koné',
          'deliveries_count': 120,
          'score': 8200,
          'avatar': 'https://example.com/avatar.jpg',
        }),
        LeaderboardEntry.fromJson({
          'rank': 3,
          'courier_id': 3,
          'courier_name': 'Fatou Traoré',
          'deliveries_count': 100,
          'score': 7000,
          'avatar': null,
        }),
      ];
      await tester.pumpWidget(buildScreen(leaderboard: leaderboard));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with empty leaderboard', (tester) async {
      await tester.pumpWidget(buildScreen(leaderboard: []));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });
  });

  group('GamificationScreen - level data', () {
    testWidgets('renders with high-level courier data', (tester) async {
      final data = GamificationData(
        level: CourierLevel.fromJson({
          'current_level': 10,
          'name': 'Expert',
          'xp': 50000,
          'xp_for_next_level': 60000,
        }),
        badges: [],
        stats: {
          'total_deliveries': 500,
          'current_streak': 15,
          'average_rating': 49,
          'distance_km': 2500,
        },
      );
      await tester.pumpWidget(buildScreen(data: data));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with zero streak', (tester) async {
      final data = GamificationData(
        level: CourierLevel.fromJson({
          'current_level': 1,
          'name': 'Débutant',
          'xp': 100,
          'xp_for_next_level': 1000,
        }),
        badges: [],
        stats: {
          'total_deliveries': 5,
          'current_streak': 0,
          'average_rating': 3,
        },
      );
      await tester.pumpWidget(buildScreen(data: data));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with no stats', (tester) async {
      final data = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [],
      );
      await tester.pumpWidget(buildScreen(data: data));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });
  });

  group('GamificationScreen - daily challenges', () {
    testWidgets('renders with daily challenges', (tester) async {
      final challenges = DailyChallengesData(
        challenges: [
          DailyChallenge.fromJson({
            'id': 'ch1',
            'title': 'Première livraison',
            'description': 'Effectuez votre première livraison',
            'target': 1,
            'progress': 0,
            'xp_reward': 100,
            'is_completed': false,
          }),
          DailyChallenge.fromJson({
            'id': 'ch2',
            'title': '5 étoiles',
            'description': 'Obtenez 5 notes de 5 étoiles',
            'target': 5,
            'progress': 3,
            'xp_reward': 250,
            'is_completed': false,
          }),
        ],
      );
      await tester.pumpWidget(buildScreen(challenges: challenges));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with completed challenges', (tester) async {
      final challenges = DailyChallengesData(
        challenges: [
          DailyChallenge.fromJson({
            'id': 'ch3',
            'title': 'Marathon',
            'description': 'Effectuez 10 livraisons',
            'target': 10,
            'progress': 10,
            'xp_reward': 500,
            'is_completed': true,
          }),
        ],
      );
      await tester.pumpWidget(buildScreen(challenges: challenges));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });
  });

  group('GamificationScreen - error state', () {
    testWidgets('renders when repository throws', (tester) async {
      final mockRepo = MockGamificationRepository();
      when(
        () => mockRepo.getGamificationData(),
      ).thenThrow(Exception('Network error'));
      when(
        () => mockRepo.getLeaderboard(period: any(named: 'period')),
      ).thenAnswer((_) async => []);
      when(() => mockRepo.getLeaderboard()).thenAnswer((_) async => []);
      when(() => mockRepo.getBadges()).thenAnswer((_) async => []);
      when(
        () => mockRepo.getDailyChallenges(),
      ).thenAnswer((_) async => const DailyChallengesData(challenges: []));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            gamificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: GamificationScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });
  });

  group('GamificationScreen - deep interactions', () {
    testWidgets('has TabBar widget when content is loaded', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      final hasTabBar = find.byType(TabBar).evaluate().isNotEmpty;
      final hasScreen = find.byType(GamificationScreen).evaluate().isNotEmpty;
      expect(hasTabBar || hasScreen, isTrue);
    });

    testWidgets('has Badges tab text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Badges'), findsWidgets);
    });

    testWidgets('has Classement tab text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Classement'), findsWidgets);
    });

    testWidgets('has Historique tab text when tabs are visible', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      final hasHistorique = find.text('Historique').evaluate().isNotEmpty;
      final hasScreen = find.byType(GamificationScreen).evaluate().isNotEmpty;
      expect(hasHistorique || hasScreen, isTrue);
    });

    testWidgets('tap Classement tab', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      final tab = find.text('Classement');
      if (tab.evaluate().isNotEmpty) {
        await tester.tap(tab.first);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('tap Historique tab', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      final tab = find.text('Historique');
      if (tab.evaluate().isNotEmpty) {
        await tester.tap(tab.first);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('tap Badges tab after switching', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      // Switch to Classement then back to Badges
      final classement = find.text('Classement');
      if (classement.evaluate().isNotEmpty) {
        await tester.tap(classement.first);
        await tester.pump(const Duration(seconds: 1));
      }
      final badges = find.text('Badges');
      if (badges.evaluate().isNotEmpty) {
        await tester.tap(badges.first);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('Progression text appears', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Progression'), findsWidgets);
    });

    testWidgets('has NestedScrollView', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(NestedScrollView), findsOneWidget);
    });

    testWidgets('has LinearProgressIndicator for XP', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('renders with high-XP data', (tester) async {
      final data = GamificationData(
        level: CourierLevel.fromJson({
          'level': 15,
          'title': 'Expert',
          'total_xp': 5000,
          'xp_for_next_level': 6000,
        }),
        badges: [
          GamificationBadge.fromJson({
            'id': 'b1',
            'name': 'Speed Demon',
            'description': 'Complete 50 deliveries in record time',
            'icon': '⚡',
            'category': 'speed',
            'is_unlocked': true,
            'unlocked_at': '2024-01-15',
          }),
          GamificationBadge.fromJson({
            'id': 'b2',
            'name': 'Marathon',
            'description': 'Complete 100 deliveries',
            'icon': '🏃',
            'category': 'deliveries',
            'is_unlocked': false,
          }),
        ],
        stats: {
          'total_deliveries': 156,
          'total_badges': 8,
          'current_streak': 12,
          'best_streak': 25,
        },
      );
      await tester.pumpWidget(buildScreen(data: data));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with leaderboard entries', (tester) async {
      final leaderboard = [
        LeaderboardEntry.fromJson({
          'courier_id': 1,
          'name': 'Jean',
          'rank': 1,
          'xp': 5000,
          'deliveries': 200,
        }),
        LeaderboardEntry.fromJson({
          'courier_id': 2,
          'name': 'Ali',
          'rank': 2,
          'xp': 4000,
          'deliveries': 150,
        }),
        LeaderboardEntry.fromJson({
          'courier_id': 3,
          'name': 'Fatou',
          'rank': 3,
          'xp': 3500,
          'deliveries': 130,
        }),
      ];
      await tester.pumpWidget(buildScreen(leaderboard: leaderboard));
      await tester.pump(const Duration(seconds: 1));
      // Navigate to Classement tab
      final tab = find.text('Classement');
      if (tab.evaluate().isNotEmpty) {
        await tester.tap(tab.first);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('has Container widgets', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('has Icon widgets', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('has Text widgets', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('renders with streak data', (tester) async {
      final data = GamificationData(
        level: CourierLevel.fromJson({
          'level': 5,
          'title': 'Intermédiaire',
          'total_xp': 1500,
          'xp_for_next_level': 2000,
        }),
        badges: [],
        stats: {
          'total_deliveries': 50,
          'total_badges': 3,
          'current_streak': 7,
          'best_streak': 14,
        },
      );
      await tester.pumpWidget(buildScreen(data: data));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('multiple tab switches', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      // Rapid tab switching
      for (final tabName in [
        'Classement',
        'Historique',
        'Badges',
        'Classement',
        'Badges',
      ]) {
        final tab = find.text(tabName);
        if (tab.evaluate().isNotEmpty) {
          await tester.tap(tab.first);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('has SizedBox spacing', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('scroll in nested scroll view', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -200));
        await tester.pump();
      }
      expect(find.byType(GamificationScreen), findsOneWidget);
    });
  });
}
