import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/wallet_screen.dart';
import '../../presentation/screens/gamification_screen.dart';

/// Types de widgets disponibles
enum WidgetType {
  stats,           // Statistiques du jour
  activeDelivery,  // Livraison en cours
  earnings,        // Gains de la semaine
  quickActions,    // Actions rapides
}

/// Données pour le widget statistiques
class StatsWidgetData {
  final int deliveriesToday;
  final double earningsToday;
  final double rating;
  final int pendingDeliveries;
  final DateTime updatedAt;

  const StatsWidgetData({
    required this.deliveriesToday,
    required this.earningsToday,
    required this.rating,
    required this.pendingDeliveries,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'deliveriesToday': deliveriesToday,
    'earningsToday': earningsToday,
    'rating': rating,
    'pendingDeliveries': pendingDeliveries,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// Données pour le widget livraison active
class ActiveDeliveryWidgetData {
  final int deliveryId;
  final String pharmacyName;
  final String customerName;
  final String customerAddress;
  final String status;
  final double distanceKm;
  final int estimatedMinutes;
  final double earnings;
  final DateTime updatedAt;

  const ActiveDeliveryWidgetData({
    required this.deliveryId,
    required this.pharmacyName,
    required this.customerName,
    required this.customerAddress,
    required this.status,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.earnings,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'deliveryId': deliveryId,
    'pharmacyName': pharmacyName,
    'customerName': customerName,
    'customerAddress': customerAddress,
    'status': status,
    'distanceKm': distanceKm,
    'estimatedMinutes': estimatedMinutes,
    'earnings': earnings,
    'updatedAt': updatedAt.toIso8601String(),
  };

  String get statusLabel {
    switch (status) {
      case 'accepted':
        return 'Acceptée';
      case 'picked_up':
        return 'Récupérée';
      case 'in_transit':
        return 'En route';
      case 'arrived':
        return 'Arrivé';
      default:
        return status;
    }
  }
}

/// Données pour le widget gains
class EarningsWidgetData {
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final int todayDeliveries;
  final int weekDeliveries;
  final double dailyGoal;
  final DateTime updatedAt;

  const EarningsWidgetData({
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.todayDeliveries,
    required this.weekDeliveries,
    required this.dailyGoal,
    required this.updatedAt,
  });

  double get goalProgress => dailyGoal > 0 ? (todayEarnings / dailyGoal).clamp(0, 1) : 0;

  Map<String, dynamic> toJson() => {
    'todayEarnings': todayEarnings,
    'weekEarnings': weekEarnings,
    'monthEarnings': monthEarnings,
    'todayDeliveries': todayDeliveries,
    'weekDeliveries': weekDeliveries,
    'dailyGoal': dailyGoal,
    'goalProgress': goalProgress,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// Service pour les widgets iOS (WidgetKit)
class IOSWidgetService {
  static const String _appGroupId = 'group.com.drpharma.delivery';
  static const String _iOSWidgetName = 'DeliveryWidget';
  static const String _androidWidgetName = 'DeliveryWidgetReceiver';

  /// Widget stats keys
  static const String keyDeliveriesToday = 'deliveries_today';
  static const String keyEarningsToday = 'earnings_today';
  static const String keyRating = 'rating';
  static const String keyPendingDeliveries = 'pending_deliveries';
  
  /// Widget active delivery keys
  static const String keyHasActiveDelivery = 'has_active_delivery';
  static const String keyDeliveryId = 'delivery_id';
  static const String keyPharmacyName = 'pharmacy_name';
  static const String keyCustomerName = 'customer_name';
  static const String keyCustomerAddress = 'customer_address';
  static const String keyDeliveryStatus = 'delivery_status';
  static const String keyDistance = 'distance';
  static const String keyEstimatedTime = 'estimated_time';
  static const String keyDeliveryEarnings = 'delivery_earnings';
  
  /// Widget earnings keys
  static const String keyTodayEarnings = 'today_earnings';
  static const String keyWeekEarnings = 'week_earnings';
  static const String keyMonthEarnings = 'month_earnings';
  static const String keyTodayDeliveries = 'today_deliveries';
  static const String keyWeekDeliveries = 'week_deliveries';
  static const String keyDailyGoal = 'daily_goal';
  static const String keyGoalProgress = 'goal_progress';
  
  /// Widget common keys
  static const String keyLastUpdated = 'last_updated';
  static const String keyIsOnline = 'is_online';
  static const String keyCourierName = 'courier_name';

  /// Initialiser le service
  Future<void> initialize() async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(_appGroupId);
      }
      if (kDebugMode) debugPrint('📱 iOS Widget Service initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Widget init error: $e');
    }
  }

  /// Mettre à jour les statistiques du widget
  Future<void> updateStats(StatsWidgetData data) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData(keyDeliveriesToday, data.deliveriesToday),
        HomeWidget.saveWidgetData(keyEarningsToday, data.earningsToday),
        HomeWidget.saveWidgetData(keyRating, data.rating),
        HomeWidget.saveWidgetData(keyPendingDeliveries, data.pendingDeliveries),
        HomeWidget.saveWidgetData(keyLastUpdated, data.updatedAt.toIso8601String()),
      ]).timeout(const Duration(seconds: 5));
      
      await _updateWidget();
      
      if (kDebugMode) {
        debugPrint('📊 Widget stats updated: ${data.deliveriesToday} livraisons, ${data.earningsToday} FCFA');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updating stats widget: $e');
    }
  }

  /// Mettre à jour la livraison active
  Future<void> updateActiveDelivery(ActiveDeliveryWidgetData? data) async {
    try {
      if (data == null) {
        // Pas de livraison active
        await HomeWidget.saveWidgetData(keyHasActiveDelivery, false);
        await _clearActiveDeliveryData();
      } else {
        await Future.wait([
          HomeWidget.saveWidgetData(keyHasActiveDelivery, true),
          HomeWidget.saveWidgetData(keyDeliveryId, data.deliveryId),
          HomeWidget.saveWidgetData(keyPharmacyName, data.pharmacyName),
          HomeWidget.saveWidgetData(keyCustomerName, data.customerName),
          HomeWidget.saveWidgetData(keyCustomerAddress, data.customerAddress),
          HomeWidget.saveWidgetData(keyDeliveryStatus, data.status),
          HomeWidget.saveWidgetData(keyDistance, data.distanceKm),
          HomeWidget.saveWidgetData(keyEstimatedTime, data.estimatedMinutes),
          HomeWidget.saveWidgetData(keyDeliveryEarnings, data.earnings),
          HomeWidget.saveWidgetData(keyLastUpdated, data.updatedAt.toIso8601String()),
        ]).timeout(const Duration(seconds: 5));
      }
      
      await _updateWidget();
      
      if (kDebugMode) {
        debugPrint('🚚 Widget delivery updated: ${data?.pharmacyName ?? "No active delivery"}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updating delivery widget: $e');
    }
  }

  /// Mettre à jour les gains du widget
  Future<void> updateEarnings(EarningsWidgetData data) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData(keyTodayEarnings, data.todayEarnings),
        HomeWidget.saveWidgetData(keyWeekEarnings, data.weekEarnings),
        HomeWidget.saveWidgetData(keyMonthEarnings, data.monthEarnings),
        HomeWidget.saveWidgetData(keyTodayDeliveries, data.todayDeliveries),
        HomeWidget.saveWidgetData(keyWeekDeliveries, data.weekDeliveries),
        HomeWidget.saveWidgetData(keyDailyGoal, data.dailyGoal),
        HomeWidget.saveWidgetData(keyGoalProgress, data.goalProgress),
        HomeWidget.saveWidgetData(keyLastUpdated, data.updatedAt.toIso8601String()),
      ]).timeout(const Duration(seconds: 5));
      
      await _updateWidget();
      
      if (kDebugMode) {
        debugPrint('💰 Widget earnings updated: ${data.todayEarnings} FCFA today');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updating earnings widget: $e');
    }
  }

  /// Mettre à jour le statut en ligne
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      await HomeWidget.saveWidgetData(keyIsOnline, isOnline);
      await _updateWidget();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updating online status: $e');
    }
  }

  /// Mettre à jour le nom du coursier
  Future<void> updateCourierName(String name) async {
    try {
      await HomeWidget.saveWidgetData(keyCourierName, name);
      await _updateWidget();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updating courier name: $e');
    }
  }

  /// Mettre à jour tous les widgets
  Future<void> _updateWidget() async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.updateWidget(
          name: _iOSWidgetName,
          iOSName: _iOSWidgetName,
        );
      } else if (Platform.isAndroid) {
        await HomeWidget.updateWidget(
          name: _androidWidgetName,
          androidName: _androidWidgetName,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updating widget: $e');
    }
  }

  /// Effacer les données de livraison active
  Future<void> _clearActiveDeliveryData() async {
    await Future.wait([
      HomeWidget.saveWidgetData(keyDeliveryId, null),
      HomeWidget.saveWidgetData(keyPharmacyName, null),
      HomeWidget.saveWidgetData(keyCustomerName, null),
      HomeWidget.saveWidgetData(keyCustomerAddress, null),
      HomeWidget.saveWidgetData(keyDeliveryStatus, null),
      HomeWidget.saveWidgetData(keyDistance, null),
      HomeWidget.saveWidgetData(keyEstimatedTime, null),
      HomeWidget.saveWidgetData(keyDeliveryEarnings, null),
    ]).timeout(const Duration(seconds: 5));
  }

  /// Écouter les interactions avec le widget
  Stream<Uri?> get widgetClickStream => HomeWidget.widgetClicked;

  /// Gérer un clic sur le widget
  Future<void> handleWidgetClick(Uri? uri) async {
    if (uri == null) return;
    
    final action = uri.host;
    final params = uri.queryParameters;
    
    if (kDebugMode) {
      debugPrint('📱 Widget clicked: $action, params: $params');
    }
    
    // Gérer les différentes actions
    switch (action) {
      case 'open_delivery':
        // Pour l'instant, naviguer vers le dashboard qui listera les livraisons
        // La navigation directe nécessite un objet Delivery complet
        final navigator = MyApp.navigatorKey.currentState;
        if (navigator != null) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (_) => false,
          );
        }
        break;
      case 'go_online':
        // Naviguer vers l'écran principal (home) qui gère le toggle en ligne
        final navigator = MyApp.navigatorKey.currentState;
        if (navigator != null) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (_) => false,
          );
        }
        break;
      case 'open_earnings':
        final navigator = MyApp.navigatorKey.currentState;
        if (navigator != null) {
          navigator.push(MaterialPageRoute(
            builder: (_) => const WalletScreen(),
          ));
        }
        break;
      case 'open_stats':
        final navigator = MyApp.navigatorKey.currentState;
        if (navigator != null) {
          navigator.push(MaterialPageRoute(
            builder: (_) => const GamificationScreen(),
          ));
        }
        break;
    }
  }

  /// Lire les données actuelles du widget
  Future<Map<String, dynamic>> getCurrentWidgetData() async {
    try {
      final data = <String, dynamic>{};
      
      data[keyDeliveriesToday] = await HomeWidget.getWidgetData<int>(keyDeliveriesToday);
      data[keyEarningsToday] = await HomeWidget.getWidgetData<double>(keyEarningsToday);
      data[keyRating] = await HomeWidget.getWidgetData<double>(keyRating);
      data[keyHasActiveDelivery] = await HomeWidget.getWidgetData<bool>(keyHasActiveDelivery);
      data[keyIsOnline] = await HomeWidget.getWidgetData<bool>(keyIsOnline);
      
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error reading widget data: $e');
      return {};
    }
  }

  /// Rafraîchir les widgets en arrière-plan
  Future<void> backgroundRefresh() async {
    // Cette méthode sera appelée par iOS pour rafraîchir les widgets
    // Charger les données depuis le cache local
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Charger et mettre à jour les stats
      final deliveries = prefs.getInt('cached_deliveries_today') ?? 0;
      final earnings = prefs.getDouble('cached_earnings_today') ?? 0.0;
      final rating = prefs.getDouble('cached_rating') ?? 5.0;
      
      await updateStats(StatsWidgetData(
        deliveriesToday: deliveries,
        earningsToday: earnings,
        rating: rating,
        pendingDeliveries: 0,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Background refresh error: $e');
    }
  }
}

/// Provider
final iosWidgetServiceProvider = Provider<IOSWidgetService>((ref) {
  return IOSWidgetService();
});

/// Provider pour le stream de clics widget
final widgetClickStreamProvider = StreamProvider<Uri?>((ref) {
  final service = ref.watch(iosWidgetServiceProvider);
  return service.widgetClickStream;
});
