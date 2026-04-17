import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/widgets/profile/profile_hero.dart';
import 'package:courier/data/models/user.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget() {
    final user = User.fromJson({
      'id': 1,
      'name': 'Jean Dupont',
      'email': 'jean@test.com',
      'phone': '+2250101010101',
      'courier': {
        'id': 1,
        'status': 'active',
        'completed_deliveries': '120',
        'rating': '4.7',
      },
    });
    return ProviderScope(
      overrides: commonWidgetTestOverrides(),
      child: MaterialApp(
        home: Scaffold(body: ProfileHero(user: user)),
      ),
    );
  }

  group('ProfileHero', () {
    testWidgets('renders with user data', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
    });

    testWidgets('displays user name', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Jean Dupont'), findsWidgets);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Container widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('contains Column widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contains Row widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('ProfileHero - user variations', () {
    Widget buildWithUser(
      Map<String, dynamic> json, {
      VoidCallback? onNotificationTap,
      VoidCallback? onSettingsTap,
    }) {
      final user = User.fromJson(json);
      return ProviderScope(
        overrides: commonWidgetTestOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: ProfileHero(
              user: user,
              onNotificationTap: onNotificationTap,
              onSettingsTap: onSettingsTap,
            ),
          ),
        ),
      );
    }

    testWidgets('user with motorcycle vehicle type', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 2,
          'name': 'Ali Koné',
          'email': 'ali@test.com',
          'phone': '+2250505050505',
          'courier': {
            'id': 2,
            'status': 'available',
            'completed_deliveries': '200',
            'rating': '4.9',
            'vehicle_type': 'motorcycle',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
      expect(find.textContaining('Ali Koné'), findsWidgets);
    });

    testWidgets('user with car vehicle type', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 3,
          'name': 'Fatou Traoré',
          'email': 'fatou@test.com',
          'phone': '+2250606060606',
          'courier': {
            'id': 3,
            'status': 'available',
            'completed_deliveries': '50',
            'rating': '4.5',
            'vehicle_type': 'car',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
    });

    testWidgets('user with bicycle vehicle type', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 4,
          'name': 'Bakary Cissé',
          'email': 'bakary@test.com',
          'phone': '+2250808080808',
          'courier': {
            'id': 4,
            'status': 'available',
            'completed_deliveries': '10',
            'rating': '3.5',
            'vehicle_type': 'bicycle',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
    });

    testWidgets('user with scooter vehicle type', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 5,
          'name': 'Moussa Diallo',
          'email': 'moussa@test.com',
          'phone': '+2250909090909',
          'courier': {
            'id': 5,
            'status': 'available',
            'completed_deliveries': '30',
            'rating': '4.2',
            'vehicle_type': 'scooter',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
    });

    testWidgets('user with no vehicle type', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 6,
          'name': 'Aminata Bamba',
          'email': 'aminata@test.com',
          'phone': '+2250707070707',
          'courier': {
            'id': 6,
            'status': 'active',
            'completed_deliveries': '0',
            'rating': '0',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
    });

    testWidgets('user with unavailable status', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 7,
          'name': 'Ibrahim Konan',
          'email': 'ibrahim@test.com',
          'phone': '+2250111111111',
          'courier': {
            'id': 7,
            'status': 'unavailable',
            'completed_deliveries': '80',
            'rating': '4.0',
            'vehicle_type': 'motorcycle',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
    });

    testWidgets('user with avatar URL', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 8,
          'name': 'Yao Pascal',
          'email': 'yao@test.com',
          'phone': '+2250222222222',
          'avatar': 'https://example.com/avatar.jpg',
          'courier': {
            'id': 8,
            'status': 'available',
            'completed_deliveries': '150',
            'rating': '4.8',
            'vehicle_type': 'car',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
    });

    testWidgets('user with perfect rating 5.0', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 9,
          'name': 'Top Courier',
          'email': 'top@test.com',
          'phone': '+2250333333333',
          'courier': {
            'id': 9,
            'status': 'available',
            'completed_deliveries': '500',
            'rating': '5.0',
            'vehicle_type': 'motorcycle',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
    });

    testWidgets('user with zero rating', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 10,
          'name': 'New Courier',
          'email': 'new@test.com',
          'phone': '+2250444444444',
          'courier': {
            'id': 10,
            'status': 'active',
            'completed_deliveries': '0',
            'rating': '0.0',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
    });
  });

  group('ProfileHero - callbacks', () {
    testWidgets('renders with notification callback', (tester) async {
      final user = User.fromJson({
        'id': 1,
        'name': 'Jean Dupont',
        'email': 'jean@test.com',
        'phone': '+2250101010101',
        'courier': {
          'id': 1,
          'status': 'active',
          'completed_deliveries': '120',
          'rating': '4.7',
        },
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: ProfileHero(
                user: user,
                onNotificationTap: () {},
                onSettingsTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
      // Should have clickable areas for notification and settings
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('renders without callbacks', (tester) async {
      final user = User.fromJson({
        'id': 1,
        'name': 'Jean Dupont',
        'email': 'jean@test.com',
        'phone': '+2250101010101',
        'courier': {
          'id': 1,
          'status': 'active',
          'completed_deliveries': '120',
          'rating': '4.7',
        },
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(body: ProfileHero(user: user)),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProfileHero), findsOneWidget);
    });
  });
}
