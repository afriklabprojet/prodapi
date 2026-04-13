import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/loyalty_entity.dart';

/// État du programme de fidélité
class LoyaltyState {
  final LoyaltyEntity? loyalty;
  final bool isLoading;
  final String? error;
  final List<LoyaltyTransaction> transactions;
  final bool isLoadingHistory;

  const LoyaltyState({
    this.loyalty,
    this.isLoading = false,
    this.error,
    this.transactions = const [],
    this.isLoadingHistory = false,
  });

  bool get hasData => loyalty != null;
}

/// Provider du programme de fidélité
final loyaltyProvider =
    StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LoyaltyNotifier(apiClient);
});

class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  final dynamic _apiClient;

  LoyaltyNotifier(this._apiClient) : super(const LoyaltyState());

  /// Charger les données de fidélité
  Future<void> loadLoyalty() async {
    state = const LoyaltyState(isLoading: true);

    try {
      final response = await _apiClient.get('/customer/loyalty');
      final data = response.data['data'] as Map<String, dynamic>?;

      if (data != null) {
        state = LoyaltyState(loyalty: LoyaltyEntity.fromJson(data));
      } else {
        state = const LoyaltyState();
      }
    } catch (e) {
      AppLogger.debug('[Loyalty] Could not load loyalty data: $e');
      // Non-blocking: fallback to computed tier from profile stats
      state = const LoyaltyState();
    }
  }

  /// Échanger des points contre une récompense
  Future<bool> redeemReward(String rewardId) async {
    try {
      await _apiClient.post(
        '/customer/loyalty/redeem',
        data: {'reward_id': rewardId},
      );
      // Refresh loyalty data
      await loadLoyalty();
      return true;
    } catch (e) {
      AppLogger.error('[Loyalty] Failed to redeem reward: $e');
      return false;
    }
  }

  /// Charger l'historique des transactions de points
  Future<void> loadHistory() async {
    state = LoyaltyState(
      loyalty: state.loyalty,
      transactions: state.transactions,
      isLoadingHistory: true,
    );

    try {
      final response = await _apiClient.get('/customer/loyalty/history');
      final items = (response.data['data'] as List<dynamic>?)
              ?.map((t) => LoyaltyTransaction.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [];
      state = LoyaltyState(
        loyalty: state.loyalty,
        transactions: items,
      );
    } catch (e) {
      AppLogger.debug('[Loyalty] Could not load history: $e');
      state = LoyaltyState(
        loyalty: state.loyalty,
        transactions: state.transactions,
      );
    }
  }
}
