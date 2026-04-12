import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mixin pour le suivi de la mémoire des StateNotifiers
/// Permet de détecter les fuites mémoire et le nettoyage incorrect
mixin MemoryAuditMixin<T> on StateNotifier<T> {
  static final _activeNotifiers = <String, _NotifierTrackingInfo>{};
  static bool _isTrackingEnabled = kDebugMode;
  
  String? _trackingId;
  DateTime? _createdAt;
  final _subscriptions = <StreamSubscription>[];
  final _timers = <Timer>[];
  
  /// Initialise le tracking de ce notifier
  void initMemoryTracking(String notifierId) {
    if (!_isTrackingEnabled) return;
    
    _trackingId = '${runtimeType}_$notifierId';
    _createdAt = DateTime.now();
    
    _activeNotifiers[_trackingId!] = _NotifierTrackingInfo(
      id: _trackingId!,
      type: runtimeType.toString(),
      createdAt: _createdAt!,
    );
    
    if (kDebugMode) {
      debugPrint('📊 [MemoryAudit] Created: $_trackingId');
    }
  }
  
  /// Enregistre une souscription pour auto-cleanup
  void trackSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }
  
  /// Enregistre un timer pour auto-cleanup
  void trackTimer(Timer timer) {
    _timers.add(timer);
  }
  
  /// Nettoie toutes les ressources trackées
  void disposeTrackedResources() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    
    if (_trackingId != null) {
      _activeNotifiers.remove(_trackingId);
      if (kDebugMode) {
        final lifetime = DateTime.now().difference(_createdAt!);
        debugPrint('🧹 [MemoryAudit] Disposed: $_trackingId (lived ${lifetime.inSeconds}s)');
      }
    }
  }
  
  @override
  void dispose() {
    disposeTrackedResources();
    super.dispose();
  }
  
  // ==================== STATIC METHODS ====================
  
  /// Active/Désactive le tracking global
  static void setTrackingEnabled(bool enabled) {
    _isTrackingEnabled = enabled;
  }
  
  /// Retourne les notifiers actuellement actifs
  static List<_NotifierTrackingInfo> getActiveNotifiers() {
    return _activeNotifiers.values.toList();
  }
  
  /// Détecte les notifiers qui vivent depuis trop longtemps
  static List<_NotifierTrackingInfo> detectPotentialLeaks({
    Duration threshold = const Duration(minutes: 30),
  }) {
    final now = DateTime.now();
    return _activeNotifiers.values
        .where((info) => now.difference(info.createdAt) > threshold)
        .toList();
  }
  
  /// Imprime un rapport des notifiers actifs
  static void printMemoryReport() {
    if (!kDebugMode) return;
    
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 MEMORY AUDIT REPORT');
    debugPrint('───────────────────────────────────────');
    debugPrint('Active notifiers: ${_activeNotifiers.length}');
    
    for (final info in _activeNotifiers.values) {
      final age = DateTime.now().difference(info.createdAt);
      debugPrint('  • ${info.type} (${age.inMinutes}m ${age.inSeconds % 60}s)');
    }
    
    final leaks = detectPotentialLeaks();
    if (leaks.isNotEmpty) {
      debugPrint('───────────────────────────────────────');
      debugPrint('⚠️ POTENTIAL LEAKS (>30min):');
      for (final leak in leaks) {
        debugPrint('  🔴 ${leak.type}');
      }
    }
    
    debugPrint('═══════════════════════════════════════');
  }
  
  /// Réinitialise tous les trackings
  static void resetTracking() {
    _activeNotifiers.clear();
  }
}

class _NotifierTrackingInfo {
  final String id;
  final String type;
  final DateTime createdAt;
  
  _NotifierTrackingInfo({
    required this.id,
    required this.type,
    required this.createdAt,
  });
}

/// Extension pour faciliter le nettoyage avec Ref
extension RefMemoryExtension on Ref {
  /// Enregistre un cleanup automatique lors du dispose
  void onDisposeCleanup(void Function() cleanup) {
    onDispose(cleanup);
  }
  
  /// Annule un timer au dispose
  void autoDisposeTimer(Timer timer) {
    onDispose(timer.cancel);
  }
  
  /// Annule une subscription au dispose
  void autoDisposeSubscription(StreamSubscription subscription) {
    onDispose(subscription.cancel);
  }
}
