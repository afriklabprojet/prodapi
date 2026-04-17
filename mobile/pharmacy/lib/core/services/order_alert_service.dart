import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service de sonorisation pour alerter la pharmacie des nouvelles commandes.
/// Joue un son en boucle jusqu'à ce que le pharmacien acquitte l'alerte.
class OrderAlertService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  Timer? _repeatTimer;
  bool _isAlerting = false;
  int _pendingAlertCount = 0;

  bool get isAlerting => _isAlerting;
  int get pendingAlertCount => _pendingAlertCount;

  /// Démarre l'alerte sonore en boucle pour une nouvelle commande.
  Future<void> startAlert() async {
    _pendingAlertCount++;
    if (_isAlerting) return; // Déjà en cours
    _isAlerting = true;

    if (kDebugMode) debugPrint('🔊 Démarrage alerte sonore commande');

    await _playSound();

    // Rejouer toutes les 8 secondes tant que non acquitté
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (_isAlerting) {
        await _playSound();
      }
    });
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/order_received.mp3'));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur lecture son alerte: $e');
    }
  }

  /// Arrête l'alerte sonore (le pharmacien a vu la commande).
  Future<void> stopAlert() async {
    if (!_isAlerting) return;
    _isAlerting = false;
    _pendingAlertCount = 0;
    _repeatTimer?.cancel();
    _repeatTimer = null;

    try {
      await _audioPlayer.stop();
      // Annuler aussi la notification urgente persistante (ID 999)
      await _localNotifications.cancel(999);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur arrêt son: $e');
    }

    if (kDebugMode) debugPrint('🔇 Alerte sonore arrêtée');
  }

  void dispose() {
    _repeatTimer?.cancel();
    _audioPlayer.dispose();
  }
}

/// Provider global pour le service d'alerte sonore
final orderAlertServiceProvider = Provider<OrderAlertService>((ref) {
  final service = OrderAlertService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// StateProvider pour notifier l'UI qu'une alerte est active
final orderAlertActiveProvider = StateProvider<bool>((ref) => false);
