import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/gamification/gamification_widgets.dart';
import 'package:courier/data/models/gamification.dart';

void main() {
  CourierLevel makeLevel({
    int level = 3,
    String title = 'Or',
    int currentXP = 750,
    int requiredXP = 1000,
    int totalXP = 1750,
    Color color = const Color(0xFFFFD700),
    List<String> perks = const [],
  }) {
    return CourierLevel(
      level: level,
      title: title,
      currentXP: currentXP,
      requiredXP: requiredXP,
      totalXP: totalXP,
      color: color,
      perks: perks,
    );
  }

  GamificationBadge makeBadge({
    String id = 'test',
    String name = 'Test Badge',
    String description = 'Description',
    bool isUnlocked = true,
    int requiredValue = 10,
    int currentValue = 10,
  }) {
    return GamificationBadge(
      id: id,
      name: name,
      description: description,
      iconName: 'trophy',
      color: Colors.amber,
      isUnlocked: isUnlocked,
      requiredValue: requiredValue,
      currentValue: currentValue,
      unlockedAt: isUnlocked ? DateTime.now() : null,
    );
  }

  LeaderboardEntry makeEntry({
    int rank = 1,
    int courierId = 100,
    String courierName = 'Ali',
    int deliveriesCount = 50,
    int score = 1000,
    int level = 5,
    bool isCurrentUser = false,
  }) {
    return LeaderboardEntry(
      rank: rank,
      courierId: courierId,
      courierName: courierName,
      deliveriesCount: deliveriesCount,
      score: score,
      level: level,
      isCurrentUser: isCurrentUser,
    );
  }

  // ── LevelProgressWidget ────────────────────────
  group('LevelProgressWidget', () {
    testWidgets('renders with level', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LevelProgressWidget(level: makeLevel())),
        ),
      );
      expect(find.byType(LevelProgressWidget), findsOneWidget);
    });

    testWidgets('shows level number', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LevelProgressWidget(level: makeLevel(level: 5))),
        ),
      );
      expect(find.text('Niveau 5'), findsOneWidget);
    });

    testWidgets('shows total XP', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelProgressWidget(level: makeLevel(totalXP: 2500)),
          ),
        ),
      );
      expect(find.text('2500 XP'), findsOneWidget);
    });

    testWidgets('shows XP progress text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelProgressWidget(
              level: makeLevel(currentXP: 300, requiredXP: 500),
            ),
          ),
        ),
      );
      expect(find.text('300 / 500 XP'), findsOneWidget);
    });

    testWidgets('renders without details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelProgressWidget(level: makeLevel(), showDetails: false),
          ),
        ),
      );
      expect(find.byType(LevelProgressWidget), findsOneWidget);
    });

    testWidgets('shows XP restants when details shown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelProgressWidget(
              level: makeLevel(currentXP: 750, requiredXP: 1000, totalXP: 1750),
            ),
          ),
        ),
      );
      expect(find.textContaining('XP restants'), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelProgressWidget(
              level: makeLevel(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(LevelProgressWidget));
      expect(tapped, true);
    });

    testWidgets('shows percentage progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelProgressWidget(
              level: makeLevel(currentXP: 500, requiredXP: 1000),
            ),
          ),
        ),
      );
      expect(find.text('50%'), findsOneWidget);
    });
  });

  // ── LevelBadgeCompact ──────────────────────────
  group('LevelBadgeCompact', () {
    testWidgets('renders with level info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LevelBadgeCompact(level: makeLevel())),
        ),
      );
      expect(find.byType(LevelBadgeCompact), findsOneWidget);
    });

    testWidgets('shows compact level text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LevelBadgeCompact(level: makeLevel(level: 7))),
        ),
      );
      expect(find.text('Niv. 7'), findsOneWidget);
    });

    testWidgets('renders level 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelBadgeCompact(
              level: makeLevel(level: 1, title: 'Bronze'),
            ),
          ),
        ),
      );
      expect(find.text('Niv. 1'), findsOneWidget);
    });
  });

  // ── BadgesGridWidget ───────────────────────────
  group('BadgesGridWidget', () {
    testWidgets('renders with badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgesGridWidget(
              badges: [
                makeBadge(id: 'b1', name: 'Speed'),
                makeBadge(id: 'b2', name: 'Perfect', isUnlocked: false),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(BadgesGridWidget), findsOneWidget);
    });

    testWidgets('renders empty badges list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BadgesGridWidget(badges: [])),
        ),
      );
      expect(find.byType(BadgesGridWidget), findsOneWidget);
    });

    testWidgets('shows badges count header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgesGridWidget(
              badges: [
                makeBadge(id: 'b1', isUnlocked: true),
                makeBadge(id: 'b2', isUnlocked: false),
                makeBadge(id: 'b3', isUnlocked: true),
              ],
            ),
          ),
        ),
      );
      expect(find.textContaining('2/3'), findsOneWidget);
    });

    testWidgets('shows see all button', (tester) async {
      bool seeAllTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgesGridWidget(
              badges: [makeBadge()],
              onSeeAll: () => seeAllTapped = true,
            ),
          ),
        ),
      );
      expect(find.text('Voir tout'), findsOneWidget);
      await tester.tap(find.text('Voir tout'));
      expect(seeAllTapped, true);
    });

    testWidgets('hides locked badges when showLocked false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgesGridWidget(
              badges: [
                makeBadge(id: 'b1', isUnlocked: true),
                makeBadge(id: 'b2', isUnlocked: false),
              ],
              showLocked: false,
            ),
          ),
        ),
      );
      expect(find.byType(BadgeWidget), findsOneWidget);
    });

    testWidgets('renders with custom cross axis count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgesGridWidget(badges: [makeBadge()], crossAxisCount: 3),
          ),
        ),
      );
      expect(find.byType(BadgesGridWidget), findsOneWidget);
    });
  });

  // ── BadgeWidget ────────────────────────────────
  group('BadgeWidget', () {
    testWidgets('renders unlocked badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BadgeWidget(badge: makeBadge())),
        ),
      );
      expect(find.byType(BadgeWidget), findsOneWidget);
    });

    testWidgets('renders locked badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeWidget(
              badge: makeBadge(
                isUnlocked: false,
                currentValue: 3,
                requiredValue: 10,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(BadgeWidget), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BadgeWidget(badge: makeBadge(), size: 100)),
        ),
      );
      expect(find.byType(BadgeWidget), findsOneWidget);
    });

    testWidgets('shows progress on locked badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeWidget(
              badge: makeBadge(
                isUnlocked: false,
                currentValue: 7,
                requiredValue: 10,
              ),
              showProgress: true,
            ),
          ),
        ),
      );
      expect(find.byType(BadgeWidget), findsOneWidget);
    });

    testWidgets('hides progress when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeWidget(
              badge: makeBadge(isUnlocked: false),
              showProgress: false,
            ),
          ),
        ),
      );
      expect(find.byType(BadgeWidget), findsOneWidget);
    });
  });

  // ── LeaderboardWidget ──────────────────────────
  group('LeaderboardWidget', () {
    testWidgets('renders with entries', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaderboardWidget(
                entries: [
                  makeEntry(rank: 1, courierName: 'Moussa', score: 2000),
                  makeEntry(rank: 2, courierName: 'Awa', score: 1500),
                  makeEntry(rank: 3, courierName: 'Ibrahim', score: 1200),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(LeaderboardWidget), findsOneWidget);
      expect(find.text('Classement'), findsOneWidget);
    });

    testWidgets('shows default title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LeaderboardWidget(entries: [makeEntry()])),
        ),
      );
      expect(find.text('Classement'), findsOneWidget);
    });

    testWidgets('shows custom title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeaderboardWidget(
              entries: [makeEntry()],
              title: 'Top Livreurs',
            ),
          ),
        ),
      );
      expect(find.text('Top Livreurs'), findsOneWidget);
    });

    testWidgets('shows courier names in podium', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaderboardWidget(
                entries: [
                  makeEntry(rank: 1, courierName: 'Ali'),
                  makeEntry(rank: 2, courierId: 101, courierName: 'Fatou'),
                  makeEntry(rank: 3, courierId: 102, courierName: 'Moussa'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('Fatou'), findsOneWidget);
      expect(find.text('Moussa'), findsOneWidget);
    });

    testWidgets('shows scores in podium', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaderboardWidget(
                entries: [
                  makeEntry(rank: 1, score: 2000),
                  makeEntry(
                    rank: 2,
                    courierId: 101,
                    courierName: 'B',
                    score: 1500,
                  ),
                  makeEntry(
                    rank: 3,
                    courierId: 102,
                    courierName: 'C',
                    score: 1000,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('2000 pts'), findsOneWidget);
    });

    testWidgets('highlights current user entry when rank > 10', (tester) async {
      final currentUser = makeEntry(
        rank: 15,
        courierId: 42,
        courierName: 'Moi',
        isCurrentUser: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaderboardWidget(
                entries: [
                  makeEntry(rank: 1, courierName: 'A'),
                  makeEntry(rank: 2, courierId: 101, courierName: 'B'),
                  makeEntry(rank: 3, courierId: 102, courierName: 'C'),
                ],
                currentUser: currentUser,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Moi'), findsOneWidget);
      expect(find.text('• • •'), findsOneWidget);
    });

    testWidgets('shows see all button', (tester) async {
      bool seeAllTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeaderboardWidget(
              entries: [makeEntry()],
              onSeeAll: () => seeAllTapped = true,
            ),
          ),
        ),
      );
      expect(find.text('Voir tout'), findsOneWidget);
      await tester.tap(find.text('Voir tout'));
      expect(seeAllTapped, true);
    });

    testWidgets('shows trophy icon for rank 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaderboardWidget(
                entries: [
                  makeEntry(rank: 1),
                  makeEntry(rank: 2, courierId: 101, courierName: 'B'),
                  makeEntry(rank: 3, courierId: 102, courierName: 'C'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('renders empty entries list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LeaderboardWidget(entries: const [])),
        ),
      );
      expect(find.byType(LeaderboardWidget), findsOneWidget);
    });

    testWidgets('shows delivery count in rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaderboardWidget(
                entries: [
                  makeEntry(rank: 1),
                  makeEntry(rank: 2, courierId: 101, courierName: 'B'),
                  makeEntry(rank: 3, courierId: 102, courierName: 'C'),
                  makeEntry(
                    rank: 4,
                    courierId: 103,
                    courierName: 'D',
                    deliveriesCount: 150,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('150 livraisons'), findsOneWidget);
    });
  });
}
