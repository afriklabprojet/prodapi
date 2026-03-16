import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/advanced_home_widget_service.dart';

void main() {
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
    });

    group('WidgetStyle', () {
      test('has three styles', () {
        expect(WidgetStyle.values.length, 3);
        expect(WidgetStyle.values, contains(WidgetStyle.compact));
        expect(WidgetStyle.values, contains(WidgetStyle.standard));
        expect(WidgetStyle.values, contains(WidgetStyle.detailed));
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
            reason: '${steps[i].name} should have progress >= ${steps[i - 1].name}',
          );
        }
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
