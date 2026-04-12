import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/advanced_home_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdvancedHomeWidgetService', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('WidgetDataKeys', () {
      test('has all required keys', () {
        expect(WidgetDataKeys.isOnline, 'is_online');
        expect(WidgetDataKeys.courierName, 'courier_name');
        expect(WidgetDataKeys.hasActiveDelivery, 'has_active_delivery');
        expect(WidgetDataKeys.pharmacyName, 'pharmacy_name');
        expect(WidgetDataKeys.customerAddress, 'customer_address');
        expect(WidgetDataKeys.deliveryStatus, 'delivery_status');
        expect(WidgetDataKeys.todayEarnings, 'today_earnings');
        expect(WidgetDataKeys.todayDeliveries, 'today_deliveries');
        expect(WidgetDataKeys.dailyGoal, 'daily_goal');
        expect(WidgetDataKeys.goalProgress, 'goal_progress');
      });

      test('has profile image url key', () {
        expect(WidgetDataKeys.profileImageUrl, 'profile_image_url');
      });

      test('has active delivery id key', () {
        expect(WidgetDataKeys.activeDeliveryId, 'active_delivery_id');
      });

      test('has customer name key', () {
        expect(WidgetDataKeys.customerName, 'customer_name');
      });

      test('has estimated time key', () {
        expect(WidgetDataKeys.estimatedTime, 'estimated_time');
      });

      test('has delivery progress key', () {
        expect(WidgetDataKeys.deliveryProgress, 'delivery_progress');
      });

      test('has today distance key', () {
        expect(WidgetDataKeys.todayDistance, 'today_distance');
      });

      test('has today rating key', () {
        expect(WidgetDataKeys.todayRating, 'today_rating');
      });

      test('has last updated key', () {
        expect(WidgetDataKeys.lastUpdated, 'last_updated');
      });

      test('has widget style key', () {
        expect(WidgetDataKeys.widgetStyle, 'widget_style');
      });

      test('has show earnings key', () {
        expect(WidgetDataKeys.showEarnings, 'show_earnings');
      });
    });

    group('WidgetStyle', () {
      test('has three styles', () {
        expect(WidgetStyle.values.length, 3);
        expect(WidgetStyle.values, contains(WidgetStyle.compact));
        expect(WidgetStyle.values, contains(WidgetStyle.standard));
        expect(WidgetStyle.values, contains(WidgetStyle.detailed));
      });

      test('compact has index 0', () {
        expect(WidgetStyle.compact.index, 0);
      });

      test('standard has index 1', () {
        expect(WidgetStyle.standard.index, 1);
      });

      test('detailed has index 2', () {
        expect(WidgetStyle.detailed.index, 2);
      });

      test('compact name is compact', () {
        expect(WidgetStyle.compact.name, 'compact');
      });

      test('standard name is standard', () {
        expect(WidgetStyle.standard.name, 'standard');
      });

      test('detailed name is detailed', () {
        expect(WidgetStyle.detailed.name, 'detailed');
      });
    });

    group('WidgetDeliveryStep', () {
      test('has correct labels', () {
        expect(WidgetDeliveryStep.none.label, 'En attente');
        expect(WidgetDeliveryStep.accepted.label, 'Acceptée');
        expect(WidgetDeliveryStep.toPickup.label, 'En route pharmacie');
        expect(WidgetDeliveryStep.atPharmacy.label, 'À la pharmacie');
        expect(WidgetDeliveryStep.pickedUp.label, 'Récupérée');
        expect(WidgetDeliveryStep.toCustomer.label, 'En route client');
        expect(WidgetDeliveryStep.atCustomer.label, 'Arrivé');
        expect(WidgetDeliveryStep.delivering.label, 'Livraison en cours');
      });

      test('has correct progress values', () {
        expect(WidgetDeliveryStep.none.progress, 0.0);
        expect(WidgetDeliveryStep.accepted.progress, 0.1);
        expect(WidgetDeliveryStep.toPickup.progress, 0.2);
        expect(WidgetDeliveryStep.atPharmacy.progress, 0.4);
        expect(WidgetDeliveryStep.pickedUp.progress, 0.5);
        expect(WidgetDeliveryStep.toCustomer.progress, 0.7);
        expect(WidgetDeliveryStep.atCustomer.progress, 0.9);
        expect(WidgetDeliveryStep.delivering.progress, 0.95);
      });

      test('progress values are in ascending order', () {
        final steps = WidgetDeliveryStep.values;
        for (int i = 1; i < steps.length; i++) {
          expect(
            steps[i].progress,
            greaterThanOrEqualTo(steps[i - 1].progress),
            reason:
                '${steps[i].name} should have progress >= ${steps[i - 1].name}',
          );
        }
      });

      test('has 8 steps', () {
        expect(WidgetDeliveryStep.values.length, 8);
      });

      test('none has index 0', () {
        expect(WidgetDeliveryStep.none.index, 0);
      });

      test('delivering has index 7', () {
        expect(WidgetDeliveryStep.delivering.index, 7);
      });

      test('all labels are non-empty', () {
        for (final step in WidgetDeliveryStep.values) {
          expect(step.label, isNotEmpty, reason: '${step.name} label');
        }
      });

      test('all progress values are between 0 and 1', () {
        for (final step in WidgetDeliveryStep.values) {
          expect(step.progress, greaterThanOrEqualTo(0.0));
          expect(step.progress, lessThanOrEqualTo(1.0));
        }
      });

      test('progress increments follow logical delivery flow', () {
        // Validate the flow makes sense: pickup phase < 0.5, delivery phase >= 0.5
        expect(WidgetDeliveryStep.toPickup.progress, lessThan(0.5));
        expect(WidgetDeliveryStep.atPharmacy.progress, lessThan(0.5));
        expect(WidgetDeliveryStep.pickedUp.progress, equals(0.5));
        expect(WidgetDeliveryStep.toCustomer.progress, greaterThan(0.5));
      });
    });

    group('HomeWidgetState', () {
      test('creates with default values', () {
        const state = HomeWidgetState();

        expect(state.isOnline, false);
        expect(state.courierName, isNull);
        expect(state.hasActiveDelivery, false);
        expect(state.todayEarnings, 0);
        expect(state.todayDeliveries, 0);
        expect(state.dailyGoal, 5);
        expect(state.style, WidgetStyle.standard);
        expect(state.showEarnings, true);
      });

      test('goalProgress calculates correctly', () {
        const state1 = HomeWidgetState(todayDeliveries: 3, dailyGoal: 5);
        expect(state1.goalProgress, 0.6);

        const state2 = HomeWidgetState(todayDeliveries: 5, dailyGoal: 5);
        expect(state2.goalProgress, 1.0);

        const state3 = HomeWidgetState(todayDeliveries: 10, dailyGoal: 5);
        expect(state3.goalProgress, 1.0); // Clamped

        const state4 = HomeWidgetState(todayDeliveries: 0, dailyGoal: 5);
        expect(state4.goalProgress, 0.0);
      });

      test('copyWith updates values correctly', () {
        const state = HomeWidgetState();
        final newState = state.copyWith(
          isOnline: true,
          courierName: 'Jean',
          todayDeliveries: 5,
          todayEarnings: 15000,
        );

        expect(newState.isOnline, true);
        expect(newState.courierName, 'Jean');
        expect(newState.todayDeliveries, 5);
        expect(newState.todayEarnings, 15000);

        // Original unchanged
        expect(state.isOnline, false);
        expect(state.courierName, isNull);
      });

      test('copyWith with clearDelivery resets delivery fields', () {
        final state = HomeWidgetState(
          hasActiveDelivery: true,
          activeDeliveryId: 123,
          pharmacyName: 'Pharmacie Test',
          customerAddress: '123 Rue Test',
          deliveryStep: WidgetDeliveryStep.toCustomer,
        );

        final clearedState = state.copyWith(clearDelivery: true);

        expect(clearedState.hasActiveDelivery, false);
        expect(clearedState.activeDeliveryId, isNull);
        expect(clearedState.pharmacyName, isNull);
        expect(clearedState.customerAddress, isNull);
        expect(clearedState.deliveryStep, WidgetDeliveryStep.none);
      });

      test('copyWith preserves delivery when clearDelivery is false', () {
        final state = HomeWidgetState(
          hasActiveDelivery: true,
          pharmacyName: 'Test',
        );

        final newState = state.copyWith(isOnline: true);

        expect(newState.hasActiveDelivery, true);
        expect(newState.pharmacyName, 'Test');
      });

      test('creates with all fields', () {
        final now = DateTime.now();
        final state = HomeWidgetState(
          isOnline: true,
          courierName: 'Pierre',
          hasActiveDelivery: true,
          activeDeliveryId: 456,
          pharmacyName: 'Pharmacie A',
          customerAddress: '10 Avenue Test',
          deliveryStep: WidgetDeliveryStep.pickedUp,
          estimatedTime: '15 min',
          todayEarnings: 25000,
          todayDeliveries: 8,
          todayDistance: 42.5,
          todayRating: 4.8,
          dailyGoal: 10,
          style: WidgetStyle.detailed,
          showEarnings: false,
          lastUpdated: now,
        );

        expect(state.isOnline, true);
        expect(state.courierName, 'Pierre');
        expect(state.hasActiveDelivery, true);
        expect(state.activeDeliveryId, 456);
        expect(state.pharmacyName, 'Pharmacie A');
        expect(state.customerAddress, '10 Avenue Test');
        expect(state.deliveryStep, WidgetDeliveryStep.pickedUp);
        expect(state.estimatedTime, '15 min');
        expect(state.todayEarnings, 25000);
        expect(state.todayDeliveries, 8);
        expect(state.todayDistance, 42.5);
        expect(state.todayRating, 4.8);
        expect(state.dailyGoal, 10);
        expect(state.style, WidgetStyle.detailed);
        expect(state.showEarnings, false);
        expect(state.lastUpdated, now);
      });

      test('default activeDeliveryId is null', () {
        const state = HomeWidgetState();
        expect(state.activeDeliveryId, isNull);
      });

      test('default estimatedTime is null', () {
        const state = HomeWidgetState();
        expect(state.estimatedTime, isNull);
      });

      test('default todayRating is null', () {
        const state = HomeWidgetState();
        expect(state.todayRating, isNull);
      });

      test('default lastUpdated is null', () {
        const state = HomeWidgetState();
        expect(state.lastUpdated, isNull);
      });

      test('default todayDistance is 0.0', () {
        const state = HomeWidgetState();
        expect(state.todayDistance, 0.0);
      });

      test('default deliveryStep is none', () {
        const state = HomeWidgetState();
        expect(state.deliveryStep, WidgetDeliveryStep.none);
      });

      test('goalProgress with dailyGoal of 1', () {
        const state = HomeWidgetState(todayDeliveries: 1, dailyGoal: 1);
        expect(state.goalProgress, 1.0);
      });

      test('goalProgress with large numbers', () {
        const state = HomeWidgetState(todayDeliveries: 500, dailyGoal: 1000);
        expect(state.goalProgress, 0.5);
      });

      test('copyWith updates activeDeliveryId', () {
        const state = HomeWidgetState();
        final updated = state.copyWith(activeDeliveryId: 999);
        expect(updated.activeDeliveryId, 999);
      });

      test('copyWith updates estimatedTime', () {
        const state = HomeWidgetState();
        final updated = state.copyWith(estimatedTime: '30 min');
        expect(updated.estimatedTime, '30 min');
      });

      test('copyWith updates todayDistance', () {
        const state = HomeWidgetState();
        final updated = state.copyWith(todayDistance: 123.45);
        expect(updated.todayDistance, 123.45);
      });

      test('copyWith updates todayRating', () {
        const state = HomeWidgetState();
        final updated = state.copyWith(todayRating: 4.5);
        expect(updated.todayRating, 4.5);
      });

      test('copyWith updates deliveryStep', () {
        const state = HomeWidgetState();
        final updated = state.copyWith(
          deliveryStep: WidgetDeliveryStep.atPharmacy,
        );
        expect(updated.deliveryStep, WidgetDeliveryStep.atPharmacy);
      });

      test('copyWith updates style', () {
        const state = HomeWidgetState();
        final updated = state.copyWith(style: WidgetStyle.compact);
        expect(updated.style, WidgetStyle.compact);
      });

      test('copyWith sets lastUpdated to now', () {
        const state = HomeWidgetState();
        final before = DateTime.now();
        final updated = state.copyWith(isOnline: true);
        final after = DateTime.now();

        expect(updated.lastUpdated, isNotNull);
        expect(
          updated.lastUpdated!.isAfter(before.subtract(Duration(seconds: 1))),
          true,
        );
        expect(
          updated.lastUpdated!.isBefore(after.add(Duration(seconds: 1))),
          true,
        );
      });

      test('clearDelivery also clears estimatedTime', () {
        final state = HomeWidgetState(
          hasActiveDelivery: true,
          estimatedTime: '10 min',
        );
        final cleared = state.copyWith(clearDelivery: true);
        expect(cleared.estimatedTime, isNull);
      });

      test('clearDelivery preserves stats', () {
        final state = HomeWidgetState(
          hasActiveDelivery: true,
          todayEarnings: 5000,
          todayDeliveries: 3,
        );
        final cleared = state.copyWith(clearDelivery: true);
        expect(cleared.todayEarnings, 5000);
        expect(cleared.todayDeliveries, 3);
      });

      test('clearDelivery preserves style and showEarnings', () {
        final state = HomeWidgetState(
          hasActiveDelivery: true,
          style: WidgetStyle.detailed,
          showEarnings: false,
        );
        final cleared = state.copyWith(clearDelivery: true);
        expect(cleared.style, WidgetStyle.detailed);
        expect(cleared.showEarnings, false);
      });
    });

    group('Provider', () {
      test('advancedHomeWidgetProvider exists', () {
        expect(advancedHomeWidgetProvider, isNotNull);
      });

      test('widgetOnlineStatusProvider returns bool', () {
        final isOnline = container.read(widgetOnlineStatusProvider);
        expect(isOnline, isA<bool>());
        expect(isOnline, false); // Default
      });

      test('widgetGoalProgressProvider returns double', () {
        final progress = container.read(widgetGoalProgressProvider);
        expect(progress, isA<double>());
        expect(progress, greaterThanOrEqualTo(0.0));
        expect(progress, lessThanOrEqualTo(1.0));
      });
    });
  });
}
