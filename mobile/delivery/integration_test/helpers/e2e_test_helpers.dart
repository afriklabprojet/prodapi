import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:courier/core/services/firestore_tracking_service.dart';
import 'package:courier/core/services/location_service.dart';
import 'package:courier/core/services/notification_service.dart';
import 'package:courier/data/models/courier_profile.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/models/statistics.dart';
import 'package:courier/data/models/user.dart';
import 'package:courier/data/models/wallet_data.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/data/repositories/statistics_repository.dart';
import 'package:courier/presentation/providers/profile_provider.dart';
import 'package:courier/presentation/providers/wallet_provider.dart';

/// Helpers partagés pour les tests d'intégration E2E de l'app Delivery
class E2ETestHelpers {
  /// Vérifie si un finder est visible
  static bool isVisible(Finder finder) => finder.evaluate().isNotEmpty;

  /// Attend que l'UI soit stable
  static Future<void> waitForStableUi(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (hasStableUi()) {
        return;
      }
    }
    await tester.pump(const Duration(seconds: 1));
  }

  /// Vérifie si l'UI est dans un état stable
  static bool hasStableUi() {
    return isVisible(find.byType(Scaffold)) ||
        isVisible(find.byType(MaterialApp)) ||
        isVisible(find.byType(BottomNavigationBar)) ||
        isVisible(find.byType(NavigationBar));
  }

  /// Attend un élément spécifique
  static Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (isVisible(finder)) {
        return true;
      }
    }
    return false;
  }

  /// Tap sur un élément s'il est visible
  static Future<bool> tapIfVisible(
    WidgetTester tester,
    Finder finder, {
    bool scrollIntoView = true,
  }) async {
    if (!isVisible(finder)) {
      return false;
    }

    if (scrollIntoView) {
      await tester.ensureVisible(finder.first);
    }
    await tester.tap(finder.first);
    await tester.pump(const Duration(milliseconds: 300));
    return true;
  }

  /// Entre du texte dans un champ
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.ensureVisible(finder.first);
    await tester.tap(finder.first);
    await tester.pump();
    await tester.enterText(finder.first, text);
    await tester.pump(const Duration(milliseconds: 200));
  }
}

class MockCourierProfileData {
  static const CourierProfile standard = CourierProfile(
    id: 42,
    name: 'Livreur Test',
    email: 'delivery-test@drpharma.app',
    status: 'active',
    vehicleType: 'moto',
    plateNumber: 'TEST-001',
    rating: 4.8,
    completedDeliveries: 24,
    earnings: 45000,
    kycStatus: 'approved',
  );
}

class MockUserData {
  static const User standard = User(
    id: 42,
    name: 'Livreur Test',
    email: 'delivery-test@drpharma.app',
    phone: '+2250700000000',
    role: 'courier',
    courier: CourierInfo(
      id: 42,
      status: 'active',
      vehicleType: 'moto',
      vehicleNumber: 'TEST-001',
      rating: 4.8,
      completedDeliveries: 24,
      kycStatus: 'approved',
    ),
  );
}

class _TestDeliveryRepository extends DeliveryRepository {
  _TestDeliveryRepository() : super(Dio());

  @override
  Future<CourierProfile> getProfile() async => MockCourierProfileData.standard;

  @override
  Future<List<Delivery>> getDeliveries({String status = 'pending'}) async =>
      const [];
}

class _TestNotificationService extends NotificationService {
  _TestNotificationService() : super.forTest(Dio());

  @override
  Future<void> initNotifications() async {}
}

class _FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

class _TestLocationService extends LocationService {
  _TestLocationService()
    : super(
        _TestDeliveryRepository(),
        FirestoreTrackingService(firestore: _FakeFirebaseFirestore()),
      );

  @override
  Stream<Position> get locationStream => const Stream<Position>.empty();

  @override
  void initializeFirestore(int courierId) {}

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> startTracking() async {}

  @override
  Future<void> stopTracking() async {}

  @override
  Future<void> goOnline() async {}

  @override
  Future<void> goOffline() async {}
}

class MockStatisticsData {
  static Statistics standard({String period = 'week'}) => Statistics(
    period: period,
    startDate: '2026-04-01',
    endDate: '2026-04-07',
    overview: const StatsOverview(
      totalDeliveries: 24,
      totalEarnings: 45000,
      totalDistanceKm: 120.5,
      totalDurationMinutes: 340,
      averageRating: 4.8,
      deliveryTrend: 12.0,
      earningsTrend: 8.0,
      currency: 'FCFA',
    ),
    performance: const StatsPerformance(
      totalAssigned: 28,
      totalAccepted: 26,
      totalDelivered: 24,
      totalCancelled: 2,
      acceptanceRate: 92.8,
      completionRate: 85.7,
      cancellationRate: 7.2,
      onTimeRate: 95.0,
      satisfactionRate: 96.0,
    ),
    revenueBreakdown: const RevenueBreakdown(total: 45000),
    goals: const StatsGoals(
      weeklyTarget: 30,
      currentProgress: 24,
      progressPercentage: 80,
      remaining: 6,
    ),
  );
}

class _TestStatisticsRepository extends StatisticsRepository {
  _TestStatisticsRepository() : super(Dio());

  @override
  Future<Statistics> getStatistics({String period = 'week'}) async {
    return MockStatisticsData.standard(period: period);
  }
}

/// Données de test pour le wallet
class MockWalletData {
  static WalletData get standard => WalletData(
    balance: 25000,
    currency: 'XOF',
    transactions: [
      WalletTransaction(
        id: 1,
        amount: 5000,
        type: 'credit',
        category: 'topup',
        description: 'Recharge Orange Money',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      WalletTransaction(
        id: 2,
        amount: 200,
        type: 'credit',
        category: 'commission',
        description: 'Commission livraison #1234',
        deliveryId: 1234,
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      WalletTransaction(
        id: 3,
        amount: 3000,
        type: 'debit',
        category: 'withdrawal',
        description: 'Retrait MTN MoMo',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
    pendingPayouts: 1500,
    availableBalance: 23500,
    canDeliver: true,
    commissionAmount: 200,
    totalTopups: 50000,
    totalEarnings: 45000,
    todayEarnings: 2400,
    totalCommissions: 4800,
    deliveriesCount: 24,
  );

  static WalletData get empty => const WalletData(
    balance: 0,
    currency: 'XOF',
    transactions: [],
    pendingPayouts: 0,
    availableBalance: 0,
    canDeliver: true,
    commissionAmount: 200,
    totalTopups: 0,
    totalEarnings: 0,
    todayEarnings: 0,
    totalCommissions: 0,
    deliveriesCount: 0,
  );

  static WalletData get lowBalance => const WalletData(
    balance: 150,
    currency: 'XOF',
    transactions: [],
    pendingPayouts: 0,
    availableBalance: 150,
    canDeliver: false,
    commissionAmount: 200,
    totalTopups: 5000,
    totalEarnings: 1200,
    todayEarnings: 0,
    totalCommissions: 200,
    deliveriesCount: 1,
  );
}

/// Override des providers pour les tests wallet/dashboard.
// ignore: strict_top_level_inference
createWalletOverrides({WalletData? walletData}) {
  final data = walletData ?? MockWalletData.standard;

  SharedPreferences.setMockInitialValues({
    'has_auth_token': true,
    'courier_is_online': false,
  });

  return [
    walletProvider.overrideWith((ref) async => data),
    walletDataProvider.overrideWith((ref) async => data),
    profileProvider.overrideWith((ref) async => MockUserData.standard),
    deliveryRepositoryProvider.overrideWith((ref) => _TestDeliveryRepository()),
    statisticsRepositoryProvider.overrideWith(
      (ref) => _TestStatisticsRepository(),
    ),
    firestoreTrackingServiceProvider.overrideWith(
      (ref) => FirestoreTrackingService(firestore: _FakeFirebaseFirestore()),
    ),
    locationServiceProvider.overrideWith((ref) => _TestLocationService()),
    notificationServiceProvider.overrideWith(
      (ref) => _TestNotificationService(),
    ),
  ];
}
