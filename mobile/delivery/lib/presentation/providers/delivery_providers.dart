import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/models/delivery.dart';
import '../../data/models/courier_profile.dart';
import '../../core/services/route_service.dart';
import '../../core/services/location_service.dart';
import '../../core/config/app_config.dart';

/// Clé SharedPreferences pour persister le statut "en ligne".
const String _kIsOnlineKey = 'courier_is_online';

/// Source de vérité unique pour le statut en ligne / hors ligne du livreur.
/// Persiste le statut localement et le restaure au démarrage pour éviter
/// que le livreur apparaisse hors ligne quand il quitte et revient dans l'app.
class IsOnlineNotifier extends Notifier<bool> {
  SharedPreferences? _prefs;

  @override
  bool build() {
    // Charger le statut persisté de manière asynchrone dès que possible
    _loadPersistedStatus();
    return false; // Valeur initiale, sera mise à jour rapidement
  }

  /// Charge le statut persisté et synchronise avec le serveur.
  Future<void> _loadPersistedStatus() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final persisted = _prefs?.getBool(_kIsOnlineKey) ?? false;
      if (persisted && state != persisted) {
        state = persisted;
      }
    } catch (_) {
      // Ignorer les erreurs de SharedPreferences
    }
  }

  /// Met à jour le statut et le persiste localement.
  void set(bool value) {
    state = value;
    _persistStatus(value);
  }

  /// Persiste le statut de manière asynchrone.
  Future<void> _persistStatus(bool value) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setBool(_kIsOnlineKey, value);
    } catch (_) {
      // Ignorer les erreurs de persistance
    }
  }
}

final isOnlineProvider = NotifierProvider<IsOnlineNotifier, bool>(
  IsOnlineNotifier.new,
);

final deliveriesProvider = FutureProvider.autoDispose
    .family<List<Delivery>, String>((ref, status) async {
      return ref
          .read(deliveryRepositoryProvider)
          .getDeliveries(status: status)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'NETWORK_ERROR:Le chargement des livraisons a expiré. Vérifiez votre connexion.',
              );
            },
          );
    });

final courierProfileProvider = FutureProvider<CourierProfile>((ref) async {
  return ref
      .read(deliveryRepositoryProvider)
      .getProfile()
      .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            'NETWORK_ERROR:Le serveur ne répond pas. Vérifiez votre connexion.',
          );
        },
      );
});

final routeServiceProvider = Provider<RouteService>((ref) {
  return RouteService(AppConfig.googleMapsApiKey);
});

/// Providers dérivés granulaires pour éviter les rebuilds excessifs
/// Utiliser ces providers au lieu de courierProfileProvider quand seule une partie du profil est nécessaire

/// ID du livreur uniquement (pour initialiser les services)
final courierIdProvider = Provider<int?>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.hasValue ? profile.value?.id : null;
});

/// Nom du livreur uniquement (pour l'affichage)
final courierNameProvider = Provider<String>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.hasValue ? (profile.value?.name ?? '') : '';
});

/// Statut du livreur uniquement (available, offline, delivering)
final courierStatusProvider = Provider<String?>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.hasValue ? profile.value?.status : null;
});

/// Balance wallet uniquement (pour affichage dans la barre)
final courierEarningsProvider = Provider<double>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.hasValue ? (profile.value?.earnings ?? 0.0) : 0.0;
});

/// Badges (challenges complétés) du profil
final courierBadgesProvider = Provider<List<ProfileBadge>>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.hasValue ? (profile.value?.badges ?? []) : [];
});

/// Challenges actifs (en cours) du profil
final courierActiveChallengesProvider = Provider<List<ProfileChallenge>>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.hasValue ? (profile.value?.activeChallenges ?? []) : [];
});

/// Indique si le livreur a au moins une livraison active
final hasActiveDeliveryProvider = Provider<bool>((ref) {
  final deliveries = ref.watch(deliveriesProvider('active'));
  return deliveries.hasValue && (deliveries.value?.isNotEmpty ?? false);
});

/// Première livraison active (ou null)
final activeDeliveryProvider = Provider<Delivery?>((ref) {
  final deliveries = ref.watch(deliveriesProvider('active'));
  if (!deliveries.hasValue) return null;
  final list = deliveries.value;
  return (list != null && list.isNotEmpty) ? list.first : null;
});

final locationStreamProvider = StreamProvider<Position>((ref) {
  return ref.read(locationServiceProvider).locationStream;
});
