import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/advanced_home_widget_service.dart';

void main() {
  // ════════════════════════════════════════════
  // WidgetDataKeys constants
  // ════════════════════════════════════════════
  group('WidgetDataKeys', () {
    test('isOnline key', () {
      expect(WidgetDataKeys.isOnline, 'is_online');
    });

    test('courierName key', () {
      expect(WidgetDataKeys.courierName, 'courier_name');
    });

    test('profileImageUrl key', () {
      expect(WidgetDataKeys.profileImageUrl, 'profile_image_url');
    });

    test('hasActiveDelivery key', () {
      expect(WidgetDataKeys.hasActiveDelivery, 'has_active_delivery');
    });

    test('activeDeliveryId key', () {
      expect(WidgetDataKeys.activeDeliveryId, 'active_delivery_id');
    });

    test('pharmacyName key', () {
      expect(WidgetDataKeys.pharmacyName, 'pharmacy_name');
    });

    test('customerName key', () {
      expect(WidgetDataKeys.customerName, 'customer_name');
    });

    test('customerAddress key', () {
      expect(WidgetDataKeys.customerAddress, 'customer_address');
    });

    test('deliveryStatus key', () {
      expect(WidgetDataKeys.deliveryStatus, 'delivery_status');
    });

    test('estimatedTime key', () {
      expect(WidgetDataKeys.estimatedTime, 'estimated_time');
    });

    test('deliveryProgress key', () {
      expect(WidgetDataKeys.deliveryProgress, 'delivery_progress');
    });

    test('todayEarnings key', () {
      expect(WidgetDataKeys.todayEarnings, 'today_earnings');
    });

    test('todayDeliveries key', () {
      expect(WidgetDataKeys.todayDeliveries, 'today_deliveries');
    });

    test('todayDistance key', () {
      expect(WidgetDataKeys.todayDistance, 'today_distance');
    });

    test('todayRating key', () {
      expect(WidgetDataKeys.todayRating, 'today_rating');
    });

    test('dailyGoal key', () {
      expect(WidgetDataKeys.dailyGoal, 'daily_goal');
    });

    test('goalProgress key', () {
      expect(WidgetDataKeys.goalProgress, 'goal_progress');
    });

    test('lastUpdated key', () {
      expect(WidgetDataKeys.lastUpdated, 'last_updated');
    });

    test('widgetStyle key', () {
      expect(WidgetDataKeys.widgetStyle, 'widget_style');
    });

    test('showEarnings key', () {
      expect(WidgetDataKeys.showEarnings, 'show_earnings');
    });
  });

  // ════════════════════════════════════════════
  // WidgetStyle enum
  // ════════════════════════════════════════════
  group('WidgetStyle', () {
    test('has 3 values', () {
      expect(WidgetStyle.values.length, 3);
    });

    test('compact exists', () {
      expect(WidgetStyle.compact.index, 0);
    });

    test('standard exists', () {
      expect(WidgetStyle.standard.index, 1);
    });

    test('detailed exists', () {
      expect(WidgetStyle.detailed.index, 2);
    });
  });

  // ════════════════════════════════════════════
  // WidgetDeliveryStep enum + extension
  // ════════════════════════════════════════════
  group('WidgetDeliveryStep', () {
    test('has 8 values', () {
      expect(WidgetDeliveryStep.values.length, 8);
    });

    test('label for none', () {
      expect(WidgetDeliveryStep.none.label, 'En attente');
    });

    test('label for accepted', () {
      expect(WidgetDeliveryStep.accepted.label, 'Acceptée');
    });

    test('label for toPickup', () {
      expect(WidgetDeliveryStep.toPickup.label, 'En route pharmacie');
    });

    test('label for atPharmacy', () {
      expect(WidgetDeliveryStep.atPharmacy.label, 'À la pharmacie');
    });

    test('label for pickedUp', () {
      expect(WidgetDeliveryStep.pickedUp.label, 'Récupérée');
    });

    test('label for toCustomer', () {
      expect(WidgetDeliveryStep.toCustomer.label, 'En route client');
    });

    test('label for atCustomer', () {
      expect(WidgetDeliveryStep.atCustomer.label, 'Arrivé');
    });

    test('label for delivering', () {
      expect(WidgetDeliveryStep.delivering.label, 'Livraison en cours');
    });

    test('progress for none', () {
      expect(WidgetDeliveryStep.none.progress, 0.0);
    });

    test('progress for accepted', () {
      expect(WidgetDeliveryStep.accepted.progress, 0.1);
    });

    test('progress for toPickup', () {
      expect(WidgetDeliveryStep.toPickup.progress, 0.2);
    });

    test('progress for atPharmacy', () {
      expect(WidgetDeliveryStep.atPharmacy.progress, 0.4);
    });

    test('progress for pickedUp', () {
      expect(WidgetDeliveryStep.pickedUp.progress, 0.5);
    });

    test('progress for toCustomer', () {
      expect(WidgetDeliveryStep.toCustomer.progress, 0.7);
    });

    test('progress for atCustomer', () {
      expect(WidgetDeliveryStep.atCustomer.progress, 0.9);
    });

    test('progress for delivering', () {
      expect(WidgetDeliveryStep.delivering.progress, 0.95);
    });
  });

  // ════════════════════════════════════════════
  // HomeWidgetState
  // ════════════════════════════════════════════
  group('HomeWidgetState', () {
    test('default constructor has correct defaults', () {
      const state = HomeWidgetState();
      expect(state.isOnline, false);
      expect(state.courierName, null);
      expect(state.hasActiveDelivery, false);
      expect(state.activeDeliveryId, null);
      expect(state.pharmacyName, null);
      expect(state.customerAddress, null);
      expect(state.deliveryStep, WidgetDeliveryStep.none);
      expect(state.estimatedTime, null);
      expect(state.todayEarnings, 0);
      expect(state.todayDeliveries, 0);
      expect(state.todayDistance, 0.0);
      expect(state.todayRating, null);
      expect(state.dailyGoal, 5);
      expect(state.style, WidgetStyle.standard);
      expect(state.showEarnings, true);
      expect(state.lastUpdated, null);
    });

    test('goalProgress returns clamp 0.0-1.0', () {
      const state = HomeWidgetState(todayDeliveries: 3, dailyGoal: 5);
      expect(state.goalProgress, 0.6);
    });

    test('goalProgress clamps to 1.0 when exceeded', () {
      const state = HomeWidgetState(todayDeliveries: 10, dailyGoal: 5);
      expect(state.goalProgress, 1.0);
    });

    test('goalProgress is 0.0 when no deliveries', () {
      const state = HomeWidgetState(todayDeliveries: 0, dailyGoal: 5);
      expect(state.goalProgress, 0.0);
    });

    test('copyWith preserves values when no args', () {
      const state = HomeWidgetState(
        isOnline: true,
        courierName: 'Test',
        todayEarnings: 5000,
        dailyGoal: 10,
      );
      final copy = state.copyWith();
      expect(copy.isOnline, true);
      expect(copy.courierName, 'Test');
      expect(copy.todayEarnings, 5000);
      expect(copy.dailyGoal, 10);
    });

    test('copyWith updates all fields', () {
      const state = HomeWidgetState();
      final copy = state.copyWith(
        isOnline: true,
        courierName: 'Ali',
        hasActiveDelivery: true,
        activeDeliveryId: 42,
        pharmacyName: 'Pharmacie X',
        customerAddress: '123 Main',
        deliveryStep: WidgetDeliveryStep.toCustomer,
        estimatedTime: '10 min',
        todayEarnings: 3000,
        todayDeliveries: 5,
        todayDistance: 12.5,
        todayRating: 4.8,
        dailyGoal: 8,
        style: WidgetStyle.detailed,
        showEarnings: false,
      );
      expect(copy.isOnline, true);
      expect(copy.courierName, 'Ali');
      expect(copy.hasActiveDelivery, true);
      expect(copy.activeDeliveryId, 42);
      expect(copy.pharmacyName, 'Pharmacie X');
      expect(copy.customerAddress, '123 Main');
      expect(copy.deliveryStep, WidgetDeliveryStep.toCustomer);
      expect(copy.estimatedTime, '10 min');
      expect(copy.todayEarnings, 3000);
      expect(copy.todayDeliveries, 5);
      expect(copy.todayDistance, 12.5);
      expect(copy.todayRating, 4.8);
      expect(copy.dailyGoal, 8);
      expect(copy.style, WidgetStyle.detailed);
      expect(copy.showEarnings, false);
    });

    test('copyWith with clearDelivery resets delivery fields', () {
      const state = HomeWidgetState(
        hasActiveDelivery: true,
        activeDeliveryId: 99,
        pharmacyName: 'Pharmacie A',
        customerAddress: '456 Street',
        deliveryStep: WidgetDeliveryStep.atPharmacy,
        estimatedTime: '5 min',
      );
      final cleared = state.copyWith(clearDelivery: true);
      expect(cleared.hasActiveDelivery, false);
      expect(cleared.activeDeliveryId, null);
      expect(cleared.pharmacyName, null);
      expect(cleared.customerAddress, null);
      expect(cleared.deliveryStep, WidgetDeliveryStep.none);
      expect(cleared.estimatedTime, null);
    });

    test('copyWith with clearDelivery preserves non-delivery fields', () {
      const state = HomeWidgetState(
        isOnline: true,
        courierName: 'Bob',
        todayEarnings: 2000,
        todayDeliveries: 3,
        hasActiveDelivery: true,
        activeDeliveryId: 1,
      );
      final cleared = state.copyWith(clearDelivery: true);
      expect(cleared.isOnline, true);
      expect(cleared.courierName, 'Bob');
      expect(cleared.todayEarnings, 2000);
      expect(cleared.todayDeliveries, 3);
    });

    test('copyWith sets lastUpdated', () {
      const state = HomeWidgetState();
      final copy = state.copyWith(todayEarnings: 100);
      expect(copy.lastUpdated, isNotNull);
    });

    test('constructor with all params', () {
      final now = DateTime.now();
      final state = HomeWidgetState(
        isOnline: true,
        courierName: 'Test',
        hasActiveDelivery: true,
        activeDeliveryId: 1,
        pharmacyName: 'P',
        customerAddress: 'A',
        deliveryStep: WidgetDeliveryStep.delivering,
        estimatedTime: '2 min',
        todayEarnings: 100,
        todayDeliveries: 2,
        todayDistance: 5.0,
        todayRating: 4.5,
        dailyGoal: 10,
        style: WidgetStyle.compact,
        showEarnings: false,
        lastUpdated: now,
      );
      expect(state.lastUpdated, now);
      expect(state.style, WidgetStyle.compact);
    });
  });
}
