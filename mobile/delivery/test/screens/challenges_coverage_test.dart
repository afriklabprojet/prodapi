import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/challenges_screen.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHiveForTests();
    await initializeDateFormatting('fr_FR');
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Map<String, dynamic> makeChallengesData({
    List<Map<String, dynamic>>? inProgress,
    List<Map<String, dynamic>>? completed,
    List<Map<String, dynamic>>? rewarded,
    List<Map<String, dynamic>>? activeBonuses,
  }) {
    return {
      'challenges': {
        'in_progress': inProgress ?? [],
        'completed': completed ?? [],
        'rewarded': rewarded ?? [],
      },
      'active_bonuses': activeBonuses ?? [],
      'stats': {
        'in_progress_count': (inProgress ?? []).length,
        'can_claim_count': (completed ?? []).length,
        'rewarded_count': (rewarded ?? []).length,
      },
    };
  }

  Map<String, dynamic> makeChallenge({
    int id = 1,
    String title = 'Défi Test',
    String description = 'Description du défi',
    String color = 'blue',
    String icon = 'star',
    double progressPercent = 50.0,
    int currentProgress = 5,
    int targetValue = 10,
    int rewardAmount = 1000,
  }) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color,
      'icon': icon,
      'progress_percent': progressPercent,
      'current_progress': currentProgress,
      'target_value': targetValue,
      'reward_amount': rewardAmount,
    };
  }

  Widget buildScreen(Map<String, dynamic> data) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        challengesProvider.overrideWith((_) async => data),
      ],
      child: const MaterialApp(home: ChallengesScreen()),
    );
  }

  group('ChallengesScreen', () {
    testWidgets('shows header title Défis & Bonus', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(makeChallengesData()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Défis & Bonus'), findsOneWidget);
    });

    testWidgets('shows stats badges from data', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final data = makeChallengesData(
        inProgress: [makeChallenge(id: 1)],
        completed: [makeChallenge(id: 2, progressPercent: 100)],
      );

      await tester.pumpWidget(buildScreen(data));
      await tester.pump(const Duration(seconds: 1));

      // Stats badges with En cours and À réclamer labels
      expect(find.text('En cours'), findsOneWidget);
      expect(find.text('À réclamer'), findsOneWidget);
    });

    testWidgets('shows in-progress challenges section', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final challenge = makeChallenge(
        id: 1,
        title: 'Défi Vitesse',
        description: 'Faire 10 livraisons',
        color: 'blue',
        icon: 'speed',
        progressPercent: 60.0,
        currentProgress: 6,
        targetValue: 10,
        rewardAmount: 2000,
      );

      await tester.pumpWidget(
        buildScreen(makeChallengesData(inProgress: [challenge])),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Défi Vitesse'), findsOneWidget);
      expect(find.text('Faire 10 livraisons'), findsOneWidget);
      expect(find.text('6 / 10'), findsOneWidget);
    });

    testWidgets('shows completed (claimable) challenges', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final challenge = makeChallenge(
        id: 2,
        title: 'Champion du Jour',
        description: 'Réalisez 5 livraisons',
        color: 'green',
        icon: 'emoji_events',
        progressPercent: 100.0,
        currentProgress: 5,
        targetValue: 5,
        rewardAmount: 5000,
      );

      await tester.pumpWidget(
        buildScreen(makeChallengesData(completed: [challenge])),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Champion du Jour'), findsOneWidget);
      // Claimable challenges show "Réclamer" button
      expect(find.text('Réclamer'), findsOneWidget);
      expect(find.textContaining('Réclamer !'), findsWidgets);
    });

    testWidgets('shows rewarded challenges with check mark', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final challenge = makeChallenge(
        id: 3,
        title: 'Défi Complété',
        color: 'amber',
        rewardAmount: 3000,
      );

      await tester.pumpWidget(
        buildScreen(makeChallengesData(rewarded: [challenge])),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Défi Complété'), findsOneWidget);
      expect(find.text('Réclamé'), findsOneWidget);
      expect(find.textContaining('Complétés'), findsOneWidget);
    });

    testWidgets('shows active bonus cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bonus = {
        'name': 'Bonus Weekend',
        'description': '+20% sur toutes les livraisons',
      };

      await tester.pumpWidget(
        buildScreen(makeChallengesData(activeBonuses: [bonus])),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('🔥 Bonus Actifs'), findsOneWidget);
      expect(find.text('Bonus Weekend'), findsOneWidget);
    });

    testWidgets('shows challenge with various color names', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Test different colors to cover _getColor switch
      final challenges = [
        makeChallenge(
          id: 1,
          title: 'Orange Challenge',
          color: 'orange',
          icon: 'rocket_launch',
        ),
        makeChallenge(
          id: 2,
          title: 'Purple Challenge',
          color: 'purple',
          icon: 'military_tech',
        ),
        makeChallenge(
          id: 3,
          title: 'Teal Challenge',
          color: 'teal',
          icon: 'workspace_premium',
        ),
        makeChallenge(
          id: 4,
          title: 'Red Challenge',
          color: 'red',
          icon: 'local_fire_department',
        ),
      ];

      await tester.pumpWidget(
        buildScreen(makeChallengesData(inProgress: challenges)),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Orange Challenge'), findsOneWidget);
      expect(find.text('Purple Challenge'), findsOneWidget);
    });

    testWidgets('shows challenge with various icon names', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Test different icons to cover _getIcon switch
      final challenges = [
        makeChallenge(
          id: 1,
          title: 'Calendar Challenge',
          color: 'blue',
          icon: 'calendar_today',
        ),
        makeChallenge(
          id: 2,
          title: 'Unknown Icon',
          color: 'amber',
          icon: 'nonexistent',
        ),
      ];

      await tester.pumpWidget(
        buildScreen(makeChallengesData(inProgress: challenges)),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Calendar Challenge'), findsOneWidget);
    });

    testWidgets('shows scaffold with CustomScrollView', (tester) async {
      await tester.pumpWidget(buildScreen(makeChallengesData()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('shows classement button in header', (tester) async {
      await tester.pumpWidget(buildScreen(makeChallengesData()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Classement'), findsOneWidget);
    });

    testWidgets('shows en cours section label', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final challenge = makeChallenge(id: 1, title: 'Active Challenge');

      await tester.pumpWidget(
        buildScreen(makeChallengesData(inProgress: [challenge])),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('⏳ En Cours'), findsOneWidget);
    });
  });
}
