import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/delivery.dart';
import '../config/app_config.dart';

/// Service avancé pour le widget écran d'accueil
/// ==============================================

/// Clés pour les données du widget
class WidgetDataKeys {
  // Statut
  static const String isOnline = 'is_online';
  static const String courierName = 'courier_name';
  static const String profileImageUrl = 'profile_image_url';
  
  // Livraison active
  static const String hasActiveDelivery = 'has_active_delivery';
  static const String activeDeliveryId = 'active_delivery_id';
  static const String pharmacyName = 'pharmacy_name';
  static const String customerName = 'customer_name';
  static const String customerAddress = 'customer_address';
  static const String deliveryStatus = 'delivery_status';
  static const String estimatedTime = 'estimated_time';
  static const String deliveryProgress = 'delivery_progress'; // 0.0 - 1.0
  
  // Stats journalières
  static const String todayEarnings = 'today_earnings';
  static const String todayDeliveries = 'today_deliveries';
  static const String todayDistance = 'today_distance';
  static const String todayRating = 'today_rating';
  
  // Objectifs
  static const String dailyGoal = 'daily_goal';
  static const String goalProgress = 'goal_progress'; // 0.0 - 1.0
  
  // Métadonnées
  static const String lastUpdated = 'last_updated';
  static const String widgetStyle = 'widget_style';
  static const String showEarnings = 'show_earnings';
}

/// Style de widget disponibles
enum WidgetStyle {
  compact,   // Minimal: statut + bouton
  standard,  // Stats + livraison active
  detailed,  // Tout avec objectifs
}

/// Statut de livraison pour le widget
enum WidgetDeliveryStep {
  none,          // Pas de livraison
  accepted,      // Commande acceptée
  toPickup,      // En route vers pharmacie
  atPharmacy,    // À la pharmacie
  pickedUp,      // Commande récupérée
  toCustomer,    // En route vers client
  atCustomer,    // Arrivé chez client
  delivering,    // En cours de remise
}

extension WidgetDeliveryStepX on WidgetDeliveryStep {
  String get label {
    switch (this) {
      case WidgetDeliveryStep.none: return 'En attente';
      case WidgetDeliveryStep.accepted: return 'Acceptée';
      case WidgetDeliveryStep.toPickup: return 'En route pharmacie';
      case WidgetDeliveryStep.atPharmacy: return 'À la pharmacie';
      case WidgetDeliveryStep.pickedUp: return 'Récupérée';
      case WidgetDeliveryStep.toCustomer: return 'En route client';
      case WidgetDeliveryStep.atCustomer: return 'Arrivé';
      case WidgetDeliveryStep.delivering: return 'Livraison en cours';
    }
  }
  
  double get progress {
    switch (this) {
      case WidgetDeliveryStep.none: return 0.0;
      case WidgetDeliveryStep.accepted: return 0.1;
      case WidgetDeliveryStep.toPickup: return 0.2;
      case WidgetDeliveryStep.atPharmacy: return 0.4;
      case WidgetDeliveryStep.pickedUp: return 0.5;
      case WidgetDeliveryStep.toCustomer: return 0.7;
      case WidgetDeliveryStep.atCustomer: return 0.9;
      case WidgetDeliveryStep.delivering: return 0.95;
    }
  }
}

/// État du widget pour preview dans l'app
class HomeWidgetState {
  final bool isOnline;
  final String? courierName;
  final bool hasActiveDelivery;
  final int? activeDeliveryId;
  final String? pharmacyName;
  final String? customerAddress;
  final WidgetDeliveryStep deliveryStep;
  final String? estimatedTime;
  final int todayEarnings;
  final int todayDeliveries;
  final double todayDistance;
  final double? todayRating;
  final int dailyGoal;
  final WidgetStyle style;
  final bool showEarnings;
  final DateTime? lastUpdated;

  const HomeWidgetState({
    this.isOnline = false,
    this.courierName,
    this.hasActiveDelivery = false,
    this.activeDeliveryId,
    this.pharmacyName,
    this.customerAddress,
    this.deliveryStep = WidgetDeliveryStep.none,
    this.estimatedTime,
    this.todayEarnings = 0,
    this.todayDeliveries = 0,
    this.todayDistance = 0.0,
    this.todayRating,
    this.dailyGoal = 5,
    this.style = WidgetStyle.standard,
    this.showEarnings = true,
    this.lastUpdated,
  });

  double get goalProgress => (todayDeliveries / dailyGoal).clamp(0.0, 1.0);

  HomeWidgetState copyWith({
    bool? isOnline,
    String? courierName,
    bool? hasActiveDelivery,
    int? activeDeliveryId,
    String? pharmacyName,
    String? customerAddress,
    WidgetDeliveryStep? deliveryStep,
    String? estimatedTime,
    int? todayEarnings,
    int? todayDeliveries,
    double? todayDistance,
    double? todayRating,
    int? dailyGoal,
    WidgetStyle? style,
    bool? showEarnings,
    DateTime? lastUpdated,
    bool clearDelivery = false,
  }) {
    return HomeWidgetState(
      isOnline: isOnline ?? this.isOnline,
      courierName: courierName ?? this.courierName,
      hasActiveDelivery: clearDelivery ? false : (hasActiveDelivery ?? this.hasActiveDelivery),
      activeDeliveryId: clearDelivery ? null : (activeDeliveryId ?? this.activeDeliveryId),
      pharmacyName: clearDelivery ? null : (pharmacyName ?? this.pharmacyName),
      customerAddress: clearDelivery ? null : (customerAddress ?? this.customerAddress),
      deliveryStep: clearDelivery ? WidgetDeliveryStep.none : (deliveryStep ?? this.deliveryStep),
      estimatedTime: clearDelivery ? null : (estimatedTime ?? this.estimatedTime),
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayDeliveries: todayDeliveries ?? this.todayDeliveries,
      todayDistance: todayDistance ?? this.todayDistance,
      todayRating: todayRating ?? this.todayRating,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      style: style ?? this.style,
      showEarnings: showEarnings ?? this.showEarnings,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}

/// Service principal du home widget
class AdvancedHomeWidgetService extends Notifier<HomeWidgetState> {
  static String get _appGroupId => AppConfig.iosAppGroup;
  static const String _androidWidgetName = 'CourierStatusWidget';
  static const String _iOSWidgetName = 'CourierStatusWidget';

  @override
  HomeWidgetState build() {
    _initialize();
    return const HomeWidgetState();
  }

  Future<void> _initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await _loadSettings();
      if (kDebugMode) debugPrint('✅ Advanced Home Widget initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Home Widget init error: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final styleIndex = prefs.getInt('widget_style') ?? 1;
    final showEarnings = prefs.getBool('widget_show_earnings') ?? true;
    final dailyGoal = prefs.getInt('widget_daily_goal') ?? 5;
    
    state = state.copyWith(
      style: WidgetStyle.values[styleIndex],
      showEarnings: showEarnings,
      dailyGoal: dailyGoal,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('widget_style', state.style.index);
    await prefs.setBool('widget_show_earnings', state.showEarnings);
    await prefs.setInt('widget_daily_goal', state.dailyGoal);
  }

  /// Mettre à jour le statut en ligne
  Future<void> setOnlineStatus(bool isOnline) async {
    state = state.copyWith(isOnline: isOnline);
    await _syncToWidget();
  }

  /// Mettre à jour le nom du coursier
  Future<void> setCourierName(String name) async {
    state = state.copyWith(courierName: name);
    await _syncToWidget();
  }

  /// Démarrer une livraison
  Future<void> startDelivery(Delivery delivery) async {
    state = state.copyWith(
      hasActiveDelivery: true,
      activeDeliveryId: delivery.id,
      pharmacyName: delivery.pharmacyName,
      customerAddress: delivery.deliveryAddress,
      deliveryStep: WidgetDeliveryStep.accepted,
    );
    await _syncToWidget();
  }

  /// Mettre à jour l'étape de livraison
  Future<void> updateDeliveryStep(WidgetDeliveryStep step, {String? eta}) async {
    state = state.copyWith(
      deliveryStep: step,
      estimatedTime: eta,
    );
    await _syncToWidget();
  }

  /// Terminer une livraison
  Future<void> completeDelivery({required int earnings}) async {
    state = state.copyWith(
      clearDelivery: true,
      todayDeliveries: state.todayDeliveries + 1,
      todayEarnings: state.todayEarnings + earnings,
    );
    await _syncToWidget();
  }

  /// Annuler la livraison en cours
  Future<void> cancelDelivery() async {
    state = state.copyWith(clearDelivery: true);
    await _syncToWidget();
  }

  /// Mettre à jour les stats du jour
  Future<void> updateDailyStats({
    required int earnings,
    required int deliveries,
    double? distance,
    double? rating,
  }) async {
    state = state.copyWith(
      todayEarnings: earnings,
      todayDeliveries: deliveries,
      todayDistance: distance ?? state.todayDistance,
      todayRating: rating,
    );
    await _syncToWidget();
  }

  /// Changer le style du widget
  Future<void> setWidgetStyle(WidgetStyle style) async {
    state = state.copyWith(style: style);
    await _saveSettings();
    await _syncToWidget();
  }

  /// Afficher/masquer les gains
  Future<void> setShowEarnings(bool show) async {
    state = state.copyWith(showEarnings: show);
    await _saveSettings();
    await _syncToWidget();
  }

  /// Définir l'objectif quotidien
  Future<void> setDailyGoal(int goal) async {
    state = state.copyWith(dailyGoal: goal);
    await _saveSettings();
    await _syncToWidget();
  }

  /// Réinitialiser les stats du jour (à minuit)
  Future<void> resetDailyStats() async {
    state = state.copyWith(
      todayEarnings: 0,
      todayDeliveries: 0,
      todayDistance: 0.0,
      todayRating: null,
    );
    await _syncToWidget();
  }

  /// Synchroniser l'état vers le widget natif
  Future<void> _syncToWidget() async {
    try {
      // Statut
      await HomeWidget.saveWidgetData<bool>(WidgetDataKeys.isOnline, state.isOnline);
      await HomeWidget.saveWidgetData<String?>(WidgetDataKeys.courierName, state.courierName);
      
      // Livraison
      await HomeWidget.saveWidgetData<bool>(WidgetDataKeys.hasActiveDelivery, state.hasActiveDelivery);
      await HomeWidget.saveWidgetData<int?>(WidgetDataKeys.activeDeliveryId, state.activeDeliveryId);
      await HomeWidget.saveWidgetData<String?>(WidgetDataKeys.pharmacyName, state.pharmacyName);
      await HomeWidget.saveWidgetData<String?>(WidgetDataKeys.customerAddress, state.customerAddress);
      await HomeWidget.saveWidgetData<String>(WidgetDataKeys.deliveryStatus, state.deliveryStep.name);
      await HomeWidget.saveWidgetData<double>(WidgetDataKeys.deliveryProgress, state.deliveryStep.progress);
      await HomeWidget.saveWidgetData<String?>(WidgetDataKeys.estimatedTime, state.estimatedTime);
      
      // Stats
      await HomeWidget.saveWidgetData<int>(WidgetDataKeys.todayEarnings, state.todayEarnings);
      await HomeWidget.saveWidgetData<int>(WidgetDataKeys.todayDeliveries, state.todayDeliveries);
      await HomeWidget.saveWidgetData<double>(WidgetDataKeys.todayDistance, state.todayDistance);
      await HomeWidget.saveWidgetData<double?>(WidgetDataKeys.todayRating, state.todayRating);
      
      // Objectifs
      await HomeWidget.saveWidgetData<int>(WidgetDataKeys.dailyGoal, state.dailyGoal);
      await HomeWidget.saveWidgetData<double>(WidgetDataKeys.goalProgress, state.goalProgress);
      
      // Settings
      await HomeWidget.saveWidgetData<String>(WidgetDataKeys.widgetStyle, state.style.name);
      await HomeWidget.saveWidgetData<bool>(WidgetDataKeys.showEarnings, state.showEarnings);
      
      // Métadonnées
      await HomeWidget.saveWidgetData<String>(
        WidgetDataKeys.lastUpdated, 
        DateTime.now().toIso8601String(),
      );
      
      // Rafraîchir le widget
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
        qualifiedAndroidName: 'com.drpharma.courier.$_androidWidgetName',
      );
      
      if (kDebugMode) debugPrint('✅ Widget synced');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Widget sync error: $e');
    }
  }

  /// Forcer la mise à jour du widget
  Future<void> forceRefresh() async {
    await _syncToWidget();
  }
}

/// Provider principal
final advancedHomeWidgetProvider =
    NotifierProvider<AdvancedHomeWidgetService, HomeWidgetState>(
  AdvancedHomeWidgetService.new,
);

/// Provider pour le statut en ligne du widget
final widgetOnlineStatusProvider = Provider<bool>((ref) {
  return ref.watch(advancedHomeWidgetProvider).isOnline;
});

/// Provider pour la progression de l'objectif
final widgetGoalProgressProvider = Provider<double>((ref) {
  return ref.watch(advancedHomeWidgetProvider).goalProgress;
});

/// Provider pour écouter les clics sur le widget
final widgetClickStreamProvider = StreamProvider<Uri?>((ref) {
  return HomeWidget.widgetClicked;
});
