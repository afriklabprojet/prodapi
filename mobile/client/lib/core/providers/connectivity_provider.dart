import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider global : true = connecté, false = hors ligne
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Vérifier l'état initial
      final result = await Connectivity().checkConnectivity();
      if (!mounted) return;
      state = _isConnected(result);

      // Écouter les changements
      _subscription = Connectivity().onConnectivityChanged.listen((results) {
        if (mounted) state = _isConnected(results);
      });
    } catch (_) {
      // Connectivity check can fail on some platforms
    }
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
