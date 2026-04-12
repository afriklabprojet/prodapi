import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/gamification/daily_challenges_widgets.dart';
import 'package:courier/data/models/gamification.dart';
import 'package:courier/data/repositories/gamification_repository.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  final farFuture = DateTime.now().add(const Duration(hours: 12));
  final pastDate = DateTime(2020, 1, 1);

  DailyChallenge makeChallenge({
    String id = 'test-challenge',
    String title = 'Livrer 5 commandes',
    String description = 'Livrez 5 commandes aujourd\'hui',
    ChallengeType type = ChallengeType.deliveries,
    ChallengeDifficulty difficulty = ChallengeDifficulty.easy,
    int targetValue = 5,
    int currentValue = 3,
    int xpReward = 100,
    int? bonusReward,
    DateTime? expiresAt,
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
      expiresAt: expiresAt ?? farFuture,
      isCompleted: isCompleted,
      isClaimed: isClaimed,
    );
  }

  Widget buildCard(
    DailyChallenge challenge, {
    bool isCompact = false,
    VoidCallback? onClaim,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DailyChallengeCard(
            challenge: challenge,
            isCompact: isCompact,
            onClaim: onClaim,
          ),
        ),
      ),
    );
  }

  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── DailyChallengeCard ─────────────────────────
  group('DailyChallengeCard', () {
    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(buildCard(makeChallenge()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Livrer 5 commandes'), findsOneWidget);
      expect(find.text('Livrez 5 commandes aujourd\'hui'), findsOneWidget);
    });

    testWidgets('shows easy difficulty badge label', (tester) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(difficulty: ChallengeDifficulty.easy)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Facile'), findsOneWidget);
    });

    testWidgets('shows medium difficulty badge label', (tester) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(difficulty: ChallengeDifficulty.medium)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Moyen'), findsOneWidget);
    });

    testWidgets('shows hard difficulty label', (tester) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(difficulty: ChallengeDifficulty.hard)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Difficile'), findsOneWidget);
    });

    testWidgets('shows legendary difficulty label', (tester) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(difficulty: ChallengeDifficulty.legendary)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Légendaire'), findsOneWidget);
    });

    testWidgets('shows XP reward text', (tester) async {
      await tester.pumpWidget(buildCard(makeChallenge(xpReward: 200)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('+200 XP'), findsOneWidget);
    });

    testWidgets('shows bonus reward when present', (tester) async {
      await tester.pumpWidget(buildCard(makeChallenge(bonusReward: 500)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('+500 F'), findsOneWidget);
    });

    testWidgets('hides bonus reward when null', (tester) async {
      await tester.pumpWidget(buildCard(makeChallenge(bonusReward: null)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining(' F'), findsNothing);
    });

    testWidgets('shows progress count', (tester) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(targetValue: 10, currentValue: 7)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('7 / 10'), findsOneWidget);
    });

    testWidgets('shows Terminé badge when completed and claimed', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(isCompleted: true, isClaimed: true)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Terminé'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows claim button when completed but not claimed', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(
          makeChallenge(isCompleted: true, isClaimed: false),
          onClaim: () {},
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Réclamer'), findsOneWidget);
    });

    testWidgets('tapping claim button triggers onClaim', (tester) async {
      bool claimed = false;
      await tester.pumpWidget(
        buildCard(
          makeChallenge(isCompleted: true, isClaimed: false),
          onClaim: () => claimed = true,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Réclamer'));
      await tester.pump();
      expect(claimed, true);
    });

    testWidgets('shows timer icon when in progress', (tester) async {
      await tester.pumpWidget(buildCard(makeChallenge()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('compact mode renders title', (tester) async {
      await tester.pumpWidget(buildCard(makeChallenge(), isCompact: true));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Livrer 5 commandes'), findsOneWidget);
    });

    testWidgets('shows delivery icon for deliveries type', (tester) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(type: ChallengeType.deliveries)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    });

    testWidgets('shows money icon for earnings type', (tester) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(type: ChallengeType.earnings)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('shows distance icon', (tester) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(type: ChallengeType.distance)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.straighten), findsOneWidget);
    });

    testWidgets('shows speed icon', (tester) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(type: ChallengeType.speed)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });

    testWidgets('shows streak icon', (tester) async {
      await tester.pumpWidget(
        buildCard(makeChallenge(type: ChallengeType.streak)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });
  });

  // ── ChallengeRefreshTimer ──────────────────────
  group('ChallengeRefreshTimer', () {
    testWidgets('renders with future refresh time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChallengeRefreshTimer(
              nextRefresh: DateTime.now().add(
                const Duration(hours: 5, minutes: 30),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ChallengeRefreshTimer), findsOneWidget);
    });

    testWidgets('renders with null refresh time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChallengeRefreshTimer(nextRefresh: null)),
        ),
      );
      await tester.pump();
      expect(find.byType(ChallengeRefreshTimer), findsOneWidget);
    });

    testWidgets('renders with past refresh time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChallengeRefreshTimer(nextRefresh: pastDate)),
        ),
      );
      await tester.pump();
      expect(find.byType(ChallengeRefreshTimer), findsOneWidget);
    });
  });

  // ── DailyChallengesHomeWidget ──────────────────
  group('DailyChallengesHomeWidget', () {
    Widget buildHome({
      AsyncValue<DailyChallengesData>? challengesAsync,
      VoidCallback? onSeeAll,
    }) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          if (challengesAsync != null)
            dailyChallengesProvider.overrideWith((ref) {
              if (challengesAsync is AsyncData<DailyChallengesData>) {
                return Future.value(challengesAsync.value);
              }
              if (challengesAsync is AsyncError<DailyChallengesData>) {
                return Future.error(challengesAsync.error);
              }
              return Future.delayed(const Duration(days: 1));
            })
          else
            dailyChallengesProvider.overrideWith(
              (ref) => Future.value(DailyChallengesData(challenges: [])),
            ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyChallengesHomeWidget(onSeeAll: onSeeAll),
            ),
          ),
        ),
      );
    }

    testWidgets('renders with empty challenges', (tester) async {
      await tester.pumpWidget(
        buildHome(
          challengesAsync: AsyncData(DailyChallengesData(challenges: [])),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DailyChallengesHomeWidget), findsOneWidget);
    });

    testWidgets('renders with active challenges', (tester) async {
      await tester.pumpWidget(
        buildHome(
          challengesAsync: AsyncData(
            DailyChallengesData(
              challenges: [
                makeChallenge(id: 'c1', title: 'Challenge 1'),
                makeChallenge(id: 'c2', title: 'Challenge 2'),
              ],
              currentStreak: 3,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DailyChallengesHomeWidget), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(buildHome(challengesAsync: const AsyncLoading()));
      await tester.pump();
      expect(find.byType(DailyChallengesHomeWidget), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        buildHome(
          challengesAsync: AsyncError('Test error', StackTrace.current),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DailyChallengesHomeWidget), findsOneWidget);
    });
  });

  // ── DailyChallengesScreen ──────────────────────
  group('DailyChallengesScreen', () {
    Widget buildScreen({AsyncValue<DailyChallengesData>? challengesAsync}) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          if (challengesAsync != null)
            dailyChallengesProvider.overrideWith((ref) {
              if (challengesAsync is AsyncData<DailyChallengesData>) {
                return Future.value(challengesAsync.value);
              }
              if (challengesAsync is AsyncError<DailyChallengesData>) {
                return Future.error(challengesAsync.error);
              }
              return Future.delayed(const Duration(days: 1));
            })
          else
            dailyChallengesProvider.overrideWith(
              (ref) => Future.value(DailyChallengesData(challenges: [])),
            ),
        ],
        child: const MaterialApp(home: DailyChallengesScreen()),
      );
    }

    testWidgets('renders screen with mixed states', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          challengesAsync: AsyncData(
            DailyChallengesData(
              challenges: [
                makeChallenge(id: 'c1', title: 'Active challenge'),
                makeChallenge(
                  id: 'c2',
                  isCompleted: true,
                  isClaimed: false,
                  title: 'Claimable',
                ),
                makeChallenge(
                  id: 'c3',
                  isCompleted: true,
                  isClaimed: true,
                  title: 'Done',
                ),
              ],
              completedToday: 1,
              totalXpEarnedToday: 100,
              currentStreak: 3,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DailyChallengesScreen), findsOneWidget);
    });

    testWidgets('renders empty challenges', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          challengesAsync: AsyncData(DailyChallengesData(challenges: [])),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DailyChallengesScreen), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        buildScreen(challengesAsync: const AsyncLoading()),
      );
      await tester.pump();
      expect(find.byType(DailyChallengesScreen), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          challengesAsync: AsyncError('Network error', StackTrace.current),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DailyChallengesScreen), findsOneWidget);
    });
  });
}
