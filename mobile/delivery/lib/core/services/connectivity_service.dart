import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// État de connectivité de l'application
enum ConnectivityStatus {
  online,
  offline,
  checking,
}

/// État complet de la connectivité avec métadonnées
class ConnectivityState {
  final ConnectivityStatus status;
  final List<ConnectivityResult> connectionTypes;
  final DateTime? lastOnlineTime;
  final int pendingSyncCount;
  final bool isSyncing;

  const ConnectivityState({
    this.status = ConnectivityStatus.checking,
    this.connectionTypes = const [],
    this.lastOnlineTime,
    this.pendingSyncCount = 0,
    this.isSyncing = false,
  });

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    List<ConnectivityResult>? connectionTypes,
    DateTime? lastOnlineTime,
    int? pendingSyncCount,
    bool? isSyncing,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      connectionTypes: connectionTypes ?? this.connectionTypes,
      lastOnlineTime: lastOnlineTime ?? this.lastOnlineTime,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;

  String get connectionTypeLabel {
    if (connectionTypes.isEmpty) return 'Aucune';
    if (connectionTypes.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (connectionTypes.contains(ConnectivityResult.mobile)) return 'Données mobiles';
    if (connectionTypes.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'Autre';
  }

  String get offlineDurationLabel {
    if (lastOnlineTime == null || isOnline) return '';
    final duration = DateTime.now().difference(lastOnlineTime!);
    if (duration.inMinutes < 1) return 'À l\'instant';
    if (duration.inMinutes < 60) return 'Hors-ligne depuis ${duration.inMinutes} min';
    if (duration.inHours < 24) return 'Hors-ligne depuis ${duration.inHours}h';
    return 'Hors-ligne depuis ${duration.inDays}j';
  }
}

/// Service de surveillance de la connectivité réseau
class ConnectivityService extends StateNotifier<ConnectivityState> {
  ConnectivityService() : super(const ConnectivityState()) {
    // NOTE : ne PAS appeler _init() dans le constructeur.
    // L'initialisation est différée via checkConnectivity() appelé par le SplashScreen
    // après que l'UI soit visible, pour éviter un ping HTTP qui bloque le main thread.
  }

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pingTimer;
  bool _initialized = false;
  bool _initializing = false;
  bool _disposed = false;
  Dio? _pingDio; // Réutiliser une seule instance Dio pour les pings
  
  // URL pour vérifier la connectivité réelle (ping)
  static String get _pingUrl => AppConfig.connectivityCheckUrl;

  void _ensureInitialized() {
    if (_initialized || _initializing) return;
    _initializing = true;
    _initialized = true;

    // Écouter les changements de connectivité
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);

    // Ping périodique pour vérifier la connectivité réelle (toutes les 60s)
    // Ping aussi quand offline pour détecter le retour en ligne
    _pingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _verifyRealConnectivity();
    });
    
    _initializing = false;
  }

  /// Vérifie l'état actuel de la connectivité
  Future<void> checkConnectivity() async {
    _ensureInitialized();
    if (_disposed) return;
    state = state.copyWith(status: ConnectivityStatus.checking);
    
    try {
      final results = await _connectivity.checkConnectivity();
      await _handleConnectivityChange(results);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Connectivity] Erreur de vérification: $e');
      state = state.copyWith(status: ConnectivityStatus.offline);
    }
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    if (kDebugMode) debugPrint('📡 [Connectivity] Changement détecté: $results');

    state = state.copyWith(connectionTypes: results);

    // Si aucune connexion hardware
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _setOffline();
      return;
    }

    // Vérifier la connectivité réelle avec un ping
    await _verifyRealConnectivity();
  }

  /// Vérifie si on a vraiment accès à Internet
  Future<bool> _verifyRealConnectivity() async {
    // On web, cross-origin ping requests are blocked by CORS.
    // Trust the connectivity_plus hardware result instead.
    if (kIsWeb) {
      final hasConnection = state.connectionTypes.isNotEmpty &&
          !state.connectionTypes.contains(ConnectivityResult.none);
      if (hasConnection) {
        _setOnline();
      } else {
        _setOffline();
      }
      return hasConnection;
    }

    try {
      _pingDio ??= Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      
      final response = await _pingDio!.get(_pingUrl);
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        _setOnline();
        return true;
      } else {
        _setOffline();
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('📡 [Connectivity] Ping échoué: $e');
      _setOffline();
      return false;
    }
  }

  void _setOnline() {
    if (_disposed) return;
    if (state.status != ConnectivityStatus.online) {
      if (kDebugMode) debugPrint('✅ [Connectivity] Connecté');
      state = state.copyWith(
        status: ConnectivityStatus.online,
        lastOnlineTime: DateTime.now(),
      );
    }
  }

  void _setOffline() {
    if (_disposed) return;
    if (state.status != ConnectivityStatus.offline) {
      if (kDebugMode) debugPrint('📴 [Connectivity] Hors-ligne');
      state = state.copyWith(
        status: ConnectivityStatus.offline,
        lastOnlineTime: state.lastOnlineTime ?? DateTime.now(),
      );
    }
  }

  /// Met à jour le nombre d'éléments en attente de sync
  void updatePendingSyncCount(int count) {
    if (_disposed) return;
    state = state.copyWith(pendingSyncCount: count);
  }

  /// Indique si une synchronisation est en cours
  void setSyncing(bool syncing) {
    if (_disposed) return;
    state = state.copyWith(isSyncing: syncing);
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _pingTimer?.cancel();
    _pingDio?.close();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDERS RIVERPOD
// ══════════════════════════════════════════════════════════════════════════════

/// Provider principal pour la connectivité
final connectivityProvider = StateNotifierProvider<ConnectivityService, ConnectivityState>((ref) {
  return ConnectivityService();
});

/// Shortcut pour savoir si on est connecté au réseau
/// NOTE: ne pas confondre avec isOnlineProvider de delivery_providers.dart
/// (celui-ci concerne la connectivité réseau, l'autre le statut "disponible" du livreur)
final isConnectedProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isOnline;
});

/// Shortcut pour savoir si on est hors-ligne
final isDisconnectedProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isOffline;
});

/// Provider du nombre d'éléments en attente
final pendingSyncCountProvider = Provider<int>((ref) {
  return ref.watch(connectivityProvider).pendingSyncCount;
});
