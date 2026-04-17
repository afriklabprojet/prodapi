import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Clés pour les données du widget Android
class HomeWidgetKeys {
  static const String isOnline = 'is_online';
  static const String hasActiveDelivery = 'has_active_delivery';
  static const String activeDeliveryId = 'active_delivery_id';
  static const String pharmacyName = 'pharmacy_name';
  static const String customerAddress = 'customer_address';
  static const String deliveryStatus = 'delivery_status';
  static const String estimatedTime = 'estimated_time';
  static const String todayEarnings = 'today_earnings';
  static const String todayDeliveries = 'today_deliveries';
  static const String lastUpdated = 'last_updated';
}

/// Statut pour le widget
enum WidgetDeliveryStatus {
  none,       // Pas de livraison
  toPickup,   // En route vers pharmacie
  atPharmacy, // À la pharmacie
  enRoute,    // En route vers client
  atCustomer, // Chez le client
}

/// Service pour mettre à jour le widget Android de l'écran d'accueil
class HomeWidgetService {
  static String get _appGroupId => AppConfig.iosAppGroup;
  static const String _androidWidgetName = 'CourierStatusWidget';
  static const String _iOSWidgetName = 'CourierStatusWidget';
  
  /// Initialiser le service de widget
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      if (kDebugMode) debugPrint('✅ Home Widget initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Home Widget init error: $e');
    }
  }
  
  /// Mettre à jour le statut online/offline
  static Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      await HomeWidget.saveWidgetData<bool>(HomeWidgetKeys.isOnline, isOnline);
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.lastUpdated, 
        DateTime.now().toIso8601String(),
      );
      await _updateWidget();
    } catch (e) {
      if (kDebugMode) debugPrint('Widget update error: $e');
    }
  }
  
  /// Mettre à jour avec une livraison active
  static Future<void> updateActiveDelivery({
    required int deliveryId,
    required String pharmacyName,
    required String customerAddress,
    required WidgetDeliveryStatus status,
    String? estimatedTime,
  }) async {
    try {
      await HomeWidget.saveWidgetData<bool>(HomeWidgetKeys.hasActiveDelivery, true);
      await HomeWidget.saveWidgetData<int>(HomeWidgetKeys.activeDeliveryId, deliveryId);
      await HomeWidget.saveWidgetData<String>(HomeWidgetKeys.pharmacyName, pharmacyName);
      await HomeWidget.saveWidgetData<String>(HomeWidgetKeys.customerAddress, customerAddress);
      await HomeWidget.saveWidgetData<String>(HomeWidgetKeys.deliveryStatus, status.name);
      if (estimatedTime != null) {
        await HomeWidget.saveWidgetData<String>(HomeWidgetKeys.estimatedTime, estimatedTime);
      }
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.lastUpdated, 
        DateTime.now().toIso8601String(),
      );
      await _updateWidget();
    } catch (e) {
      if (kDebugMode) debugPrint('Widget active delivery update error: $e');
    }
  }
  
  /// Effacer la livraison active
  static Future<void> clearActiveDelivery() async {
    try {
      await HomeWidget.saveWidgetData<bool>(HomeWidgetKeys.hasActiveDelivery, false);
      await HomeWidget.saveWidgetData<int?>(HomeWidgetKeys.activeDeliveryId, null);
      await HomeWidget.saveWidgetData<String?>(HomeWidgetKeys.pharmacyName, null);
      await HomeWidget.saveWidgetData<String?>(HomeWidgetKeys.customerAddress, null);
      await HomeWidget.saveWidgetData<String?>(HomeWidgetKeys.deliveryStatus, null);
      await HomeWidget.saveWidgetData<String?>(HomeWidgetKeys.estimatedTime, null);
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.lastUpdated, 
        DateTime.now().toIso8601String(),
      );
      await _updateWidget();
    } catch (e) {
      if (kDebugMode) debugPrint('Widget clear delivery error: $e');
    }
  }
  
  /// Mettre à jour les statistiques du jour
  static Future<void> updateDailyStats({
    required int earnings,
    required int deliveriesCount,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>(HomeWidgetKeys.todayEarnings, earnings);
      await HomeWidget.saveWidgetData<int>(HomeWidgetKeys.todayDeliveries, deliveriesCount);
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.lastUpdated, 
        DateTime.now().toIso8601String(),
      );
      await _updateWidget();
    } catch (e) {
      if (kDebugMode) debugPrint('Widget stats update error: $e');
    }
  }
  
  /// Forcer la mise à jour du widget
  static Future<void> _updateWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
        qualifiedAndroidName: 'com.drpharma.courier.$_androidWidgetName',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Widget refresh error: $e');
    }
  }
  
  /// Gérer les interactions depuis le widget
  static Future<void> handleWidgetClick(Uri? uri) async {
    if (uri == null) return;
    
    final action = uri.host;
    switch (action) {
      case 'toggle_online':
        // Toggle le statut - sera géré par le provider
        final prefs = await SharedPreferences.getInstance();
        final currentStatus = prefs.getBool('widget_toggle_online') ?? false;
        await prefs.setBool('widget_toggle_online', !currentStatus);
        break;
      case 'open_delivery':
        // Ouvrir les détails de la livraison
        // Sera géré par le deep link handler
        break;
      case 'open_app':
      default:
        // Ouvrir l'app normalement
        break;
    }
  }
  
  /// Écouter les clics sur le widget
  /// Retourne la souscription pour permettre l'annulation
  static StreamSubscription<Uri?> registerWidgetClickCallback(void Function(Uri?) callback) {
    return HomeWidget.widgetClicked.listen(callback);
  }
}

/// Provider pour le service de widget
final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  return HomeWidgetService();
});

/// Provider pour écouter les clics sur le widget
final widgetClickProvider = StreamProvider<Uri?>((ref) {
  return HomeWidget.widgetClicked;
});
