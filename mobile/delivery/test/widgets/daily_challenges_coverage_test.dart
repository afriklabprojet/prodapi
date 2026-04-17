import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/models/gamification.dart';
import 'package:courier/data/repositories/gamification_repository.dart';
import 'package:courier/presentation/widgets/gamification/daily_challenges_widgets.dart';
import '../helpers/widget_test_helpers.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

DailyChallenge _makeChallenge({
  String id = 'c1',
  String title = 'Trio du jour',
  String description = 'Effectuez 3 livraisons',
  ChallengeType type = ChallengeType.deliveries,
  ChallengeDifficulty difficulty = ChallengeDifficulty.easy,
  int targetValue = 3,
  int currentValue = 1,
  int xpReward = 50,
  int? bonusReward,
  bool isCompleted = false,
  bool isClaimed = false,
}) {
  return DailyChallenge(
    id: id,
    title: title,
    description: description,
    type: type,
    difficulty: difficulty,
    targetValue: targetValue,
    currentValue: currentValue,
    xpReward: xpReward,
    bonusReward: bonusReward,
    expiresAt: DateTime.now().add(const Duration(hours: 3)),
    isCompleted: isCompleted,
    isClaimed: isClaimed,
  );
}

DailyChallengesData _makeData({
  List<DailyChallenge>? challenges,
  int completedToday = 0,
  int currentStreak = 0,
}) {
  return DailyChallengesData(
    challenges: challenges ?? [_makeChallenge()],
    completedToday: completedToday,
    currentStreak: currentStreak,
  );
}

void main() {
  late MockGamificationRepository mockRepo;

  setUp(() {
    mockRepo = MockGamificationRepository();
  });

  group('DailyChallengeCard - full mode', () {
    testWidgets('shows challenge title and difficulty badge', (tester) async {
      final challenge = _makeChallenge();
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(body: DailyChallengeCard(challenge: challenge)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trio du jour'), findsOneWidget);
      expect(find.text('Facile'), findsOneWidget);
    });

    testWidgets('shows XP reward', (tester) async {
      final challenge = _makeChallenge(xpReward: 75);
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(body: DailyChallengeCard(challenge: challenge)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('75 XP'), findsOneWidget);
    });

    testWidgets('shows bonus reward when provided', (tester) async {
      final challenge = _makeChallenge(bonusReward: 500);
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(body: DailyChallengeCard(challenge: challenge)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('500 F'), findsOneWidget);
    });

    testWidgets('shows progress text', (tester) async {
      final challenge = _makeChallenge(currentValue: 1, targetValue: 3);
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(body: DailyChallengeCard(challenge: challenge)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('shows Réclamer button when completed and not claimed', (
      tester,
    ) async {
      tester.binding.clock; // binding access to check timers
      final challenge = _makeChallenge(
        isCompleted: true,
        isClaimed: false,
        currentValue: 3,
        targetValue: 3,
      );
      bool claimed = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: DailyChallengeCard(
                challenge: challenge,
                onClaim: () => claimed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Réclamer'), findsOneWidget);
      await tester.tap(find.text('Réclamer'));
      await tester.pump();
      expect(claimed, isTrue);
      // Dispose animation to avoid pending timer assertion
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('shows Terminé badge when completed and claimed', (
      tester,
    ) async {
      final challenge = _makeChallenge(
        isCompleted: true,
        isClaimed: true,
        currentValue: 3,
        targetValue: 3,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(body: DailyChallengeCard(challenge: challenge)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Terminé'), findsOneWidget);
    });

    testWidgets('shows timer for in-progress challenge', (tester) async {
      final challenge = _makeChallenge();
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(body: DailyChallengeCard(challenge: challenge)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('medium difficulty shows blue color badge', (tester) async {
      final challenge = _makeChallenge(difficulty: ChallengeDifficulty.medium);
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(body: DailyChallengeCard(challenge: challenge)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Moyen'), findsOneWidget);
    });
  });

  group('DailyChallengeCard - compact mode', () {
    testWidgets('compact mode shows title', (tester) async {
      final challenge = _makeChallenge(title: 'Challenge Compact');
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: DailyChallengeCard(challenge: challenge, isCompact: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Challenge Compact'), findsOneWidget);
    });

    testWidgets('compact mode shows LinearProgressIndicator', (tester) async {
      final challenge = _makeChallenge(currentValue: 1, targetValue: 3);
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: DailyChallengeCard(challenge: challenge, isCompact: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('DailyChallengesHomeWidget', () {
    testWidgets('shows Défis du jour header', (tester) async {
      final data = _makeData(challenges: [_makeChallenge()]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(
            extra: [
              dailyChallengesProvider.overrideWith((_) async => data),
              gamificationRepositoryProvider.overrideWithValue(mockRepo),
            ],
          ),
          child: const MaterialApp(
            home: Scaffold(body: DailyChallengesHomeWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Défis du jour'), findsOneWidget);
    });

    testWidgets('shows streak badge when currentStreak > 0', (tester) async {
      final data = _makeData(challenges: [_makeChallenge()], currentStreak: 5);

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(
            extra: [
              dailyChallengesProvider.overrideWith((_) async => data),
              gamificationRepositoryProvider.overrideWithValue(mockRepo),
            ],
          ),
          child: const MaterialApp(
            home: Scaffold(body: DailyChallengesHomeWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5j'), findsOneWidget);
    });

    testWidgets('shows voir tous button when >3 challenges', (tester) async {
      final challenges = List.generate(
        5,
        (i) => _makeChallenge(id: 'c$i', title: 'Défi $i'),
      );
      final data = _makeData(challenges: challenges);
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(
            extra: [
              dailyChallengesProvider.overrideWith((_) async => data),
              gamificationRepositoryProvider.overrideWithValue(mockRepo),
            ],
          ),
          child: MaterialApp(
            home: Scaffold(
              body: DailyChallengesHomeWidget(onSeeAll: () => tapped = true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Voir tous les défis'), findsOneWidget);
      await tester.tap(find.textContaining('Voir tous les défis'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('shows skeleton when loading', (tester) async {
      final completer = Completer<DailyChallengesData>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(
            extra: [
              dailyChallengesProvider.overrideWith((_) => completer.future),
              gamificationRepositoryProvider.overrideWithValue(mockRepo),
            ],
          ),
          child: const MaterialApp(
            home: Scaffold(body: DailyChallengesHomeWidget()),
          ),
        ),
      );
      await tester.pump();

      // During loading the skeleton renders some containers
      expect(find.byType(Card), findsAtLeastNWidgets(1));

      // Complete to avoid timer pending
      completer.complete(_makeData());
      await tester.pumpAndSettle();
    });
  });

  group('ChallengeRefreshTimer', () {
    testWidgets('shows refresh countdown when nextRefresh is set', (
      tester,
    ) async {
      final nextRefresh = DateTime.now().add(const Duration(hours: 2));
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: ChallengeRefreshTimer(nextRefresh: nextRefresh),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Nouveaux défis dans'), findsOneWidget);
    });

    testWidgets('shows nothing when nextRefresh is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: ChallengeRefreshTimer(nextRefresh: null)),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Nouveaux défis'), findsNothing);
    });
  });
}
