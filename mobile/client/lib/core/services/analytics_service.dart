import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contracts/analytics_contract.dart';
import '../constants/analytics_events.dart';

/// Service d'analytics multi-provider
/// 
/// Wrapper unifié pour envoyer des événements à plusieurs providers
/// (Firebase Analytics, Mixpanel, etc.) via une interface unique.
/// 
/// Usage:
/// ```dart
/// ref.read(analyticsServiceProvider).track(
///   AnalyticsEvents.addToCart,
///   properties: {
///     AnalyticsProperties.productId: product.id,
///     AnalyticsProperties.productPrice: product.price,
///   },
/// );
/// ```
class AnalyticsService implements AnalyticsContract {
  final List<AnalyticsProvider> _providers;
  bool _isInitialized = false;
  String? _currentUserId;
  
  AnalyticsService({
    required List<AnalyticsProvider> providers,
  }) : _providers = providers;
  
  @override
  Future<void> init() async {
    if (_isInitialized) return;
    
    await Future.wait(
      _providers.map((p) => p.init().catchError((e) {
        debugPrint('AnalyticsService: Failed to init ${p.runtimeType}: $e');
      })),
    );
    
    _isInitialized = true;
  }
  
  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    _currentUserId = userId;
    
    await Future.wait(
      _providers.map((p) => p.identify(userId, traits: traits).catchError((e) {
        debugPrint('AnalyticsService: Failed to identify on ${p.runtimeType}: $e');
      })),
    );
  }
  
  @override
  Future<void> reset() async {
    _currentUserId = null;
    
    await Future.wait(
      _providers.map((p) => p.reset().catchError((e) {
        debugPrint('AnalyticsService: Failed to reset on ${p.runtimeType}: $e');
      })),
    );
  }
  
  @override
  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    final props = {
      ...?properties,
      if (_currentUserId != null) AnalyticsProperties.userId: _currentUserId,
    };
    
    await Future.wait(
      _providers.map((p) => p.track(event, properties: props).catchError((e) {
        debugPrint('AnalyticsService: Failed to track $event on ${p.runtimeType}: $e');
      })),
    );
  }
  
  @override
  Future<void> screen(String screenName, {Map<String, dynamic>? properties}) async {
    final props = {
      AnalyticsProperties.screenName: screenName,
      ...?properties,
      if (_currentUserId != null) AnalyticsProperties.userId: _currentUserId,
    };
    
    await Future.wait(
      _providers.map((p) => p.screen(screenName, properties: props).catchError((e) {
        debugPrint('AnalyticsService: Failed to track screen $screenName on ${p.runtimeType}: $e');
      })),
    );
  }
  
  @override
  Future<void> setUserProperty(String name, String value) async {
    await Future.wait(
      _providers.map((p) => p.setUserProperty(name, value).catchError((e) {
        debugPrint('AnalyticsService: Failed to set property $name on ${p.runtimeType}: $e');
      })),
    );
  }
  
  @override
  Future<void> trackPurchase({
    required String orderId,
    required double total,
    required String currency,
    Map<String, dynamic>? properties,
  }) async {
    await track(AnalyticsEvents.purchase, properties: {
      AnalyticsProperties.orderId: orderId,
      AnalyticsProperties.orderTotal: total,
      'currency': currency,
      ...?properties,
    });
  }
  
  @override
  Future<void> trackCheckoutStarted({
    required double cartValue,
    required int itemCount,
    Map<String, dynamic>? properties,
  }) async {
    await track(AnalyticsEvents.checkoutStarted, properties: {
      AnalyticsProperties.cartValue: cartValue,
      AnalyticsProperties.cartItemCount: itemCount,
      ...?properties,
    });
  }
  
  @override
  Future<void> trackAddToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
    Map<String, dynamic>? properties,
  }) async {
    await track(AnalyticsEvents.addToCart, properties: {
      AnalyticsProperties.productId: productId,
      AnalyticsProperties.productName: productName,
      AnalyticsProperties.productPrice: price,
      AnalyticsProperties.quantity: quantity,
      ...?properties,
    });
  }
  
  @override
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? errorCode,
    Map<String, dynamic>? properties,
  }) async {
    await track(AnalyticsEvents.errorOccurred, properties: {
      AnalyticsProperties.errorType: errorType,
      AnalyticsProperties.errorMessage: errorMessage,
      if (errorCode != null) AnalyticsProperties.errorCode: errorCode,
      ...?properties,
    });
  }
}

/// Interface pour les providers d'analytics individuels
abstract class AnalyticsProvider {
  Future<void> init();
  Future<void> identify(String userId, {Map<String, dynamic>? traits});
  Future<void> reset();
  Future<void> track(String event, {Map<String, dynamic>? properties});
  Future<void> screen(String screenName, {Map<String, dynamic>? properties});
  Future<void> setUserProperty(String name, String value);
}

/// Provider NoOp pour le mode debug/test
/// Logue les événements sans les envoyer
class DebugAnalyticsProvider implements AnalyticsProvider {
  final bool _enabled;
  
  DebugAnalyticsProvider({bool enabled = true}) : _enabled = enabled;
  
  @override
  Future<void> init() async {
    if (_enabled) debugPrint('[Analytics] Initialized DebugAnalyticsProvider');
  }
  
  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    if (_enabled) debugPrint('[Analytics] Identify: $userId ${traits ?? ''}');
  }
  
  @override
  Future<void> reset() async {
    if (_enabled) debugPrint('[Analytics] Reset');
  }
  
  @override
  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    if (_enabled) debugPrint('[Analytics] Track: $event ${properties ?? ''}');
  }
  
  @override
  Future<void> screen(String screenName, {Map<String, dynamic>? properties}) async {
    if (_enabled) debugPrint('[Analytics] Screen: $screenName ${properties ?? ''}');
  }
  
  @override
  Future<void> setUserProperty(String name, String value) async {
    if (_enabled) debugPrint('[Analytics] SetUserProperty: $name = $value');
  }
}

/// Note: Le provider Riverpod analyticsServiceProvider est défini dans
/// config/providers.dart pour centraliser toutes les dépendances.
