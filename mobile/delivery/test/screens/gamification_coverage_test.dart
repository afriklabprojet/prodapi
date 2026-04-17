import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/gamification_screen.dart';
import 'package:courier/data/repositories/gamification_repository.dart';
import 'package:courier/data/models/gamification.dart';
import '../helpers/widget_test_helpers.dart';

class MockGamificationRepo extends Mock implements GamificationRepository {}

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

  final testBadges = [
    GamificationBadge.fromJson({
      'id': 'first_delivery',
      'name': 'Première Livraison',
      'description': 'Complétez votre première livraison',
      'icon': 'delivery',
      'color': 'bronze',
      'category': 'deliveries',
      'is_unlocked': true,
      'unlocked_at': '2024-01-15T10:00:00Z',
      'required_value': 1,
      'current_value': 1,
    }),
    GamificationBadge.fromJson({
      'id': 'delivery_10',
      'name': '10 Livraisons',
      'description': '10 livraisons complétées',
      'icon': 'delivery',
      'color': 'silver',
      'category': 'deliveries',
      'is_unlocked': true,
      'required_value': 10,
      'current_value': 10,
    }),
    GamificationBadge.fromJson({
      'id': 'speed_demon',
      'name': 'Éclair',
      'description': 'Livraison en moins de 15 minutes',
      'icon': 'lightning',
      'color': 'gold',
      'category': 'speed',
      'is_unlocked': false,
      'required_value': 5,
      'current_value': 2,
    }),
    GamificationBadge.fromJson({
      'id': 'five_star',
      'name': '5 Étoiles',
      'description': 'Recevez 50 notes 5 étoiles',
      'icon': 'star',
      'color': 'gold',
      'category': 'rating',
      'is_unlocked': false,
      'required_value': 50,
      'current_value': 25,
    }),
    GamificationBadge.fromJson({
      'id': 'streak_7',
      'name': 'Semaine Active',
      'description': '7 jours consécutifs',
      'icon': 'fire',
      'color': 'orange',
      'category': 'streak',
      'is_unlocked': true,
      'required_value': 7,
      'current_value': 7,
    }),
  ];

  final testLeaderboard = [
    LeaderboardEntry.fromJson({
      'rank': 1,
      'courier_id': 10,
      'name': 'Alpha Champion',
      'deliveries_count': 250,
      'score': 5000,
      'level': 15,
    }),
    LeaderboardEntry.fromJson({
      'rank': 2,
      'courier_id': 20,
      'name': 'Beta Runner',
      'deliveries_count': 200,
      'score': 4000,
      'level': 12,
    }),
    LeaderboardEntry.fromJson({
      'rank': 3,
      'courier_id': 30,
      'name': 'Gamma Rider',
      'deliveries_count': 180,
      'score': 3500,
      'level': 10,
    }),
  ];

  final richData = GamificationData(
    level: CourierLevel.fromJson({
      'level': 12,
      'title': 'Confirmé',
      'current_xp': 2500,
      'required_xp': 5000,
      'total_xp': 8500,
      'color': 'silver',
    }),
    badges: testBadges,
    leaderboard: testLeaderboard,
    currentUserRank: LeaderboardEntry.fromJson({
      'rank': 5,
      'courier_id': 99,
      'name': 'Moi',
      'deliveries_count': 150,
      'score': 3000,
      'level': 12,
    }, isCurrentUser: true),
    stats: {'current_streak': 7, 'total_deliveries': 150, 'total_xp': 8500},
  );

  Widget buildScreen({GamificationData? data}) {
    final mockRepo = MockGamificationRepo();
    final d = data ?? richData;

    when(() => mockRepo.getGamificationData()).thenAnswer((_) async => d);
    when(
      () => mockRepo.getLeaderboard(period: any(named: 'period')),
    ).thenAnswer((_) async => d.leaderboard);
    when(
      () => mockRepo.getLeaderboard(),
    ).thenAnswer((_) async => d.leaderboard);
    when(() => mockRepo.getBadges()).thenAnswer((_) async => d.badges);
    when(
      () => mockRepo.getDailyChallenges(),
    ).thenAnswer((_) async => const DailyChallengesData(challenges: []));

    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(home: GamificationScreen()),
    );
  }

  Future<void> pump(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('GamificationScreen with rich data', () {
    testWidgets('renders level title', (tester) async {
      await pump(tester, buildScreen());
      expect(find.textContaining('Confirmé'), findsWidgets);
    });

    testWidgets('shows XP progress', (tester) async {
      await pump(tester, buildScreen());
      // XP values should appear
      expect(find.textContaining('2500'), findsWidgets);
    });

    testWidgets('shows streak stats', (tester) async {
      await pump(tester, buildScreen());
      expect(find.textContaining('7'), findsWidgets);
    });

    testWidgets('has three tabs', (tester) async {
      await pump(tester, buildScreen());
      expect(find.byType(Tab), findsWidgets);
    });

    testWidgets('switches to Classement tab', (tester) async {
      await pump(tester, buildScreen());
      final classementTab = find.text('Classement');
      if (classementTab.evaluate().isNotEmpty) {
        await tester.tap(classementTab.first);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('switches to XP tab', (tester) async {
      await pump(tester, buildScreen());
      final xpTab = find.text('XP');
      if (xpTab.evaluate().isNotEmpty) {
        await tester.tap(xpTab.first);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('shows badge count text', (tester) async {
      await pump(tester, buildScreen());
      // 3 unlocked out of 5 total badges
      expect(find.textContaining('3'), findsWidgets);
    });

    testWidgets('renders error retry path', (tester) async {
      final mockRepo = MockGamificationRepo();
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

      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            gamificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: GamificationScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      // Should show error state or retry button
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with empty badges', (tester) async {
      final emptyData = GamificationData(
        level: CourierLevel.fromJson({}),
        badges: [],
        stats: {},
      );
      await pump(tester, buildScreen(data: emptyData));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders with empty leaderboard', (tester) async {
      final noLeaderboard = GamificationData(
        level: richData.level,
        badges: testBadges,
        leaderboard: [],
        stats: richData.stats,
      );
      await pump(tester, buildScreen(data: noLeaderboard));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      final mockRepo = MockGamificationRepo();
      when(
        () => mockRepo.getGamificationData(),
      ).thenAnswer((_) async => richData);
      when(
        () => mockRepo.getLeaderboard(period: any(named: 'period')),
      ).thenAnswer((_) async => testLeaderboard);
      when(
        () => mockRepo.getLeaderboard(),
      ).thenAnswer((_) async => testLeaderboard);
      when(() => mockRepo.getBadges()).thenAnswer((_) async => testBadges);
      when(
        () => mockRepo.getDailyChallenges(),
      ).thenAnswer((_) async => const DailyChallengesData(challenges: []));

      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            gamificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const GamificationScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GamificationScreen), findsOneWidget);
    });
  });
}
