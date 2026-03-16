import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/ios_widget_service.dart';

void main() {
  group('WidgetType', () {
    test('should have all expected values', () {
      expect(WidgetType.values.length, 4);
      expect(WidgetType.stats.index, 0);
      expect(WidgetType.activeDelivery.index, 1);
      expect(WidgetType.earnings.index, 2);
      expect(WidgetType.quickActions.index, 3);
    });
  });

  group('StatsWidgetData', () {
    test('should create with all properties', () {
      final now = DateTime.now();
      final data = StatsWidgetData(
        deliveriesToday: 5,
        earningsToday: 12500.0,
        rating: 4.8,
        pendingDeliveries: 2,
        updatedAt: now,
      );

      expect(data.deliveriesToday, 5);
      expect(data.earningsToday, 12500.0);
      expect(data.rating, 4.8);
      expect(data.pendingDeliveries, 2);
      expect(data.updatedAt, now);
    });

    test('toJson should serialize correctly', () {
      final now = DateTime(2024, 1, 15, 14, 30);
      final data = StatsWidgetData(
        deliveriesToday: 8,
        earningsToday: 25000.0,
        rating: 4.9,
        pendingDeliveries: 3,
        updatedAt: now,
      );

      final json = data.toJson();

      expect(json['deliveriesToday'], 8);
      expect(json['earningsToday'], 25000.0);
      expect(json['rating'], 4.9);
      expect(json['pendingDeliveries'], 3);
      expect(json['updatedAt'], now.toIso8601String());
    });

    test('should handle zero values', () {
      final now = DateTime.now();
      final data = StatsWidgetData(
        deliveriesToday: 0,
        earningsToday: 0.0,
        rating: 0.0,
        pendingDeliveries: 0,
        updatedAt: now,
      );

      expect(data.deliveriesToday, 0);
      expect(data.earningsToday, 0.0);
      expect(data.rating, 0.0);
      expect(data.pendingDeliveries, 0);
    });
  });

  group('ActiveDeliveryWidgetData', () {
    test('should create with all properties', () {
      final now = DateTime.now();
      final data = ActiveDeliveryWidgetData(
        deliveryId: 12345,
        pharmacyName: 'Pharmacie Centrale',
        customerName: 'Jean Dupont',
        customerAddress: '123 Rue de Paris',
        status: 'in_transit',
        distanceKm: 3.5,
        estimatedMinutes: 15,
        earnings: 1500.0,
        updatedAt: now,
      );

      expect(data.deliveryId, 12345);
      expect(data.pharmacyName, 'Pharmacie Centrale');
      expect(data.customerName, 'Jean Dupont');
      expect(data.customerAddress, '123 Rue de Paris');
      expect(data.status, 'in_transit');
      expect(data.distanceKm, 3.5);
      expect(data.estimatedMinutes, 15);
      expect(data.earnings, 1500.0);
      expect(data.updatedAt, now);
    });

    test('toJson should serialize correctly', () {
      final now = DateTime(2024, 1, 15, 10, 0);
      final data = ActiveDeliveryWidgetData(
        deliveryId: 99999,
        pharmacyName: 'Grande Pharmacie',
        customerName: 'Marie Martin',
        customerAddress: '456 Avenue des Champs',
        status: 'picked_up',
        distanceKm: 5.2,
        estimatedMinutes: 20,
        earnings: 2000.0,
        updatedAt: now,
      );

      final json = data.toJson();

      expect(json['deliveryId'], 99999);
      expect(json['pharmacyName'], 'Grande Pharmacie');
      expect(json['customerName'], 'Marie Martin');
      expect(json['customerAddress'], '456 Avenue des Champs');
      expect(json['status'], 'picked_up');
      expect(json['distanceKm'], 5.2);
      expect(json['estimatedMinutes'], 20);
      expect(json['earnings'], 2000.0);
      expect(json['updatedAt'], now.toIso8601String());
    });

    test('statusLabel should return correct French labels', () {
      final now = DateTime.now();
      
      final accepted = ActiveDeliveryWidgetData(
        deliveryId: 1,
        pharmacyName: 'Test',
        customerName: 'Test',
        customerAddress: 'Test',
        status: 'accepted',
        distanceKm: 1.0,
        estimatedMinutes: 5,
        earnings: 500.0,
        updatedAt: now,
      );
      expect(accepted.statusLabel, 'Acceptée');

      final pickedUp = ActiveDeliveryWidgetData(
        deliveryId: 2,
        pharmacyName: 'Test',
        customerName: 'Test',
        customerAddress: 'Test',
        status: 'picked_up',
        distanceKm: 1.0,
        estimatedMinutes: 5,
        earnings: 500.0,
        updatedAt: now,
      );
      expect(pickedUp.statusLabel, 'Récupérée');

      final inTransit = ActiveDeliveryWidgetData(
        deliveryId: 3,
        pharmacyName: 'Test',
        customerName: 'Test',
        customerAddress: 'Test',
        status: 'in_transit',
        distanceKm: 1.0,
        estimatedMinutes: 5,
        earnings: 500.0,
        updatedAt: now,
      );
      expect(inTransit.statusLabel, 'En route');

      final arrived = ActiveDeliveryWidgetData(
        deliveryId: 4,
        pharmacyName: 'Test',
        customerName: 'Test',
        customerAddress: 'Test',
        status: 'arrived',
        distanceKm: 1.0,
        estimatedMinutes: 5,
        earnings: 500.0,
        updatedAt: now,
      );
      expect(arrived.statusLabel, 'Arrivé');

      final unknown = ActiveDeliveryWidgetData(
        deliveryId: 5,
        pharmacyName: 'Test',
        customerName: 'Test',
        customerAddress: 'Test',
        status: 'custom_status',
        distanceKm: 1.0,
        estimatedMinutes: 5,
        earnings: 500.0,
        updatedAt: now,
      );
      expect(unknown.statusLabel, 'custom_status');
    });
  });

  group('EarningsWidgetData', () {
    test('should create with all properties', () {
      final now = DateTime.now();
      final data = EarningsWidgetData(
        todayEarnings: 8500.0,
        weekEarnings: 45000.0,
        monthEarnings: 180000.0,
        todayDeliveries: 6,
        weekDeliveries: 32,
        dailyGoal: 15000.0,
        updatedAt: now,
      );

      expect(data.todayEarnings, 8500.0);
      expect(data.weekEarnings, 45000.0);
      expect(data.monthEarnings, 180000.0);
      expect(data.todayDeliveries, 6);
      expect(data.weekDeliveries, 32);
      expect(data.dailyGoal, 15000.0);
      expect(data.updatedAt, now);
    });

    test('toJson should serialize correctly', () {
      final now = DateTime(2024, 1, 15, 18, 0);
      final data = EarningsWidgetData(
        todayEarnings: 12000.0,
        weekEarnings: 60000.0,
        monthEarnings: 240000.0,
        todayDeliveries: 10,
        weekDeliveries: 50,
        dailyGoal: 15000.0,
        updatedAt: now,
      );

      final json = data.toJson();

      expect(json['todayEarnings'], 12000.0);
      expect(json['weekEarnings'], 60000.0);
      expect(json['monthEarnings'], 240000.0);
      expect(json['todayDeliveries'], 10);
      expect(json['weekDeliveries'], 50);
      expect(json['dailyGoal'], 15000.0);
      expect(json['updatedAt'], now.toIso8601String());
    });

    test('goalProgress should calculate correctly when under goal', () {
      final now = DateTime.now();
      final data = EarningsWidgetData(
        todayEarnings: 7500.0,
        weekEarnings: 0.0,
        monthEarnings: 0.0,
        todayDeliveries: 5,
        weekDeliveries: 0,
        dailyGoal: 15000.0,
        updatedAt: now,
      );

      expect(data.goalProgress, 0.5);
    });

    test('goalProgress should be capped at 1.0 when over goal', () {
      final now = DateTime.now();
      final data = EarningsWidgetData(
        todayEarnings: 20000.0,
        weekEarnings: 0.0,
        monthEarnings: 0.0,
        todayDeliveries: 15,
        weekDeliveries: 0,
        dailyGoal: 15000.0,
        updatedAt: now,
      );

      expect(data.goalProgress, 1.0);
    });

    test('goalProgress should be 0 when dailyGoal is 0', () {
      final now = DateTime.now();
      final data = EarningsWidgetData(
        todayEarnings: 5000.0,
        weekEarnings: 0.0,
        monthEarnings: 0.0,
        todayDeliveries: 3,
        weekDeliveries: 0,
        dailyGoal: 0.0,
        updatedAt: now,
      );

      expect(data.goalProgress, 0.0);
    });

    test('toJson should include goalProgress', () {
      final now = DateTime.now();
      final data = EarningsWidgetData(
        todayEarnings: 10000.0,
        weekEarnings: 50000.0,
        monthEarnings: 200000.0,
        todayDeliveries: 8,
        weekDeliveries: 40,
        dailyGoal: 20000.0,
        updatedAt: now,
      );

      final json = data.toJson();

      expect(json['goalProgress'], 0.5);
    });
  });

  group('IOSWidgetService static keys', () {
    test('should have stats widget keys', () {
      expect(IOSWidgetService.keyDeliveriesToday, 'deliveries_today');
      expect(IOSWidgetService.keyEarningsToday, 'earnings_today');
      expect(IOSWidgetService.keyRating, 'rating');
      expect(IOSWidgetService.keyPendingDeliveries, 'pending_deliveries');
    });

    test('should have active delivery keys', () {
      expect(IOSWidgetService.keyHasActiveDelivery, 'has_active_delivery');
      expect(IOSWidgetService.keyDeliveryId, 'delivery_id');
      expect(IOSWidgetService.keyPharmacyName, 'pharmacy_name');
      expect(IOSWidgetService.keyCustomerName, 'customer_name');
      expect(IOSWidgetService.keyCustomerAddress, 'customer_address');
      expect(IOSWidgetService.keyDeliveryStatus, 'delivery_status');
      expect(IOSWidgetService.keyDistance, 'distance');
      expect(IOSWidgetService.keyEstimatedTime, 'estimated_time');
      expect(IOSWidgetService.keyDeliveryEarnings, 'delivery_earnings');
    });
  });
}
