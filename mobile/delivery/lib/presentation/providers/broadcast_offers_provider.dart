import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery_offer.dart';
import '../../data/repositories/delivery_offer_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/delivery_alert_service.dart';
import 'delivery_providers.dart';

/// État complet des offres broadcast
class BroadcastOffersState {
  final List<DeliveryOffer> offers;
  final bool isLoading;
  final String? error;
  final int? acceptingOfferId;

  const BroadcastOffersState({
    this.offers = const [],
    this.isLoading = false,
    this.error,
    this.acceptingOfferId,
  });

  BroadcastOffersState copyWith({
    List<DeliveryOffer>? offers,
    bool? isLoading,
    String? error,
    int? acceptingOfferId,
  }) {
    return BroadcastOffersState(
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      acceptingOfferId: acceptingOfferId,
    );
  }

  bool get hasOffers => offers.isNotEmpty;
  DeliveryOffer? get topOffer => offers.isNotEmpty ? offers.first : null;
}

/// Notifier principal pour gérer les offres broadcast
class BroadcastOffersNotifier extends Notifier<BroadcastOffersState> {
  Timer? _refreshTimer;
  StreamSubscription? _newOrderSub;

  @override
  BroadcastOffersState build() {
    // Auto-refresh toutes les 15s quand en ligne
    _startAutoRefresh();
    // Écouter les nouvelles notifications push pour refresh immédiat
    _listenForNewOrders();

    ref.onDispose(() {
      _refreshTimer?.cancel();
      _newOrderSub?.cancel();
    });

    // Charger les offres initiales
    _loadOffers();

    return const BroadcastOffersState(isLoading: true);
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final isOnline = ref.read(isOnlineProvider);
      if (isOnline) {
        _loadOffers(silent: true);
      }
    });
  }

  void _listenForNewOrders() {
    _newOrderSub?.cancel();
    _newOrderSub = ref.read(notificationServiceProvider).newOrderStream.listen((
      notification,
    ) {
      if (notification != null) {
        if (kDebugMode) {
          debugPrint(
            '🔔 [BroadcastOffers] Nouvelle offre push reçue, refresh...',
          );
        }
        _loadOffers();
      }
    });
  }

  /// Charge les offres depuis l'API
  Future<void> _loadOffers({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final repo = ref.read(deliveryOfferRepositoryProvider);
      final offers = await repo.getPendingOffers();

      // Filtrer les offres déjà expirées côté client
      final now = DateTime.now();
      final activeOffers = offers.where((offer) {
        try {
          final expiresAt = DateTime.parse(offer.expiresAt);
          return expiresAt.isAfter(now);
        } catch (_) {
          return true; // En cas d'erreur de parsing, garder l'offre
        }
      }).toList();

      state = state.copyWith(
        offers: activeOffers,
        isLoading: false,
        error: null,
      );

      // Déclencher l'alerte sonore si nouvelles offres
      if (activeOffers.isNotEmpty) {
        ref.read(deliveryAlertServiceProvider).startAlert();
      }
    } catch (e) {
      if (!silent) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      if (kDebugMode) {
        debugPrint('❌ [BroadcastOffers] Erreur chargement: $e');
      }
    }
  }

  /// Refresh manuel (pull-to-refresh)
  Future<void> refresh() async {
    await _loadOffers();
  }

  /// Accepter une offre
  Future<bool> acceptOffer(int offerId) async {
    state = state.copyWith(acceptingOfferId: offerId);

    try {
      final repo = ref.read(deliveryOfferRepositoryProvider);
      await repo.acceptOffer(offerId);

      // Retirer l'offre de la liste et stopper l'alerte
      final updatedOffers = state.offers.where((o) => o.id != offerId).toList();
      state = state.copyWith(offers: updatedOffers, acceptingOfferId: null);

      // Stopper l'alerte sonore
      ref.read(deliveryAlertServiceProvider).stopAlert();

      // Rafraîchir les livraisons actives
      ref.invalidate(deliveriesProvider('active'));
      ref.invalidate(deliveriesProvider('pending'));

      return true;
    } catch (e) {
      state = state.copyWith(acceptingOfferId: null);
      rethrow;
    }
  }

  /// Refuser une offre avec raison
  Future<void> rejectOffer(int offerId, {String? reason}) async {
    try {
      final repo = ref.read(deliveryOfferRepositoryProvider);
      await repo.rejectOffer(offerId, reason: reason);

      // Retirer l'offre de la liste
      final updatedOffers = state.offers.where((o) => o.id != offerId).toList();
      state = state.copyWith(offers: updatedOffers);

      // Si plus d'offres, stopper l'alerte
      if (updatedOffers.isEmpty) {
        ref.read(deliveryAlertServiceProvider).stopAlert();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [BroadcastOffers] Erreur rejet: $e');
      }
    }
  }

  /// Retirer une offre expirée côté client
  void removeExpiredOffer(int offerId) {
    final updatedOffers = state.offers.where((o) => o.id != offerId).toList();
    state = state.copyWith(offers: updatedOffers);

    if (updatedOffers.isEmpty) {
      ref.read(deliveryAlertServiceProvider).stopAlert();
    }
  }
}

/// Provider principal des offres broadcast
final broadcastOffersProvider =
    NotifierProvider<BroadcastOffersNotifier, BroadcastOffersState>(
      BroadcastOffersNotifier.new,
    );

/// Convenience : offre la plus urgente (top of stack)
final topBroadcastOfferProvider = Provider<DeliveryOffer?>((ref) {
  return ref.watch(broadcastOffersProvider).topOffer;
});

/// Convenience : nombre d'offres actives
final broadcastOfferCountProvider = Provider<int>((ref) {
  return ref.watch(broadcastOffersProvider).offers.length;
});
