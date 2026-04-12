import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/realtime_event_bus.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/models/wallet_data.dart';

/// Provider principal du portefeuille - StreamProvider pour mise à jour temps réel
/// Se rafraîchit automatiquement toutes les 30s et sur événements (paiement, remboursement)
final walletProvider = StreamProvider.autoDispose<WalletData>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final datasource = WalletRemoteDataSourceImpl(apiClient: apiClient);

  final controller = StreamController<WalletData>();
  Timer? refreshTimer;
  StreamSubscription<RealtimeEvent>? walletSub;

  Future<void> fetchWallet() async {
    try {
      final data = await datasource.getWalletData();
      if (!controller.isClosed) {
        controller.add(WalletData.fromJson(data));
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  // Fetch initial data
  fetchWallet();

  // Auto-refresh every 30 seconds
  refreshTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) => fetchWallet(),
  );

  // Listen to wallet events (payment, refund, withdrawal)
  walletSub = RealtimeEventBus().on(RealtimeEventType.walletUpdate).listen((_) {
    fetchWallet();
  });

  ref.onDispose(() {
    refreshTimer?.cancel();
    walletSub?.cancel();
    controller.close();
  });

  return controller.stream;
});

/// État des actions wallet
class WalletActionsState {
  final bool isLoading;
  final String? error;

  const WalletActionsState({this.isLoading = false, this.error});
}

/// Notifier pour les actions wallet (retrait, paramètres, etc.)
class WalletActionsNotifier extends AutoDisposeNotifier<WalletActionsState> {
  late final WalletRemoteDataSource _datasource;

  @override
  WalletActionsState build() {
    _datasource = ref.watch(walletRemoteDataSourceProvider);
    return const WalletActionsState();
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    String? accountDetails,
    String? phone,
    String? pin,
  }) async {
    state = const WalletActionsState(isLoading: true);
    try {
      final result = await _datasource.requestWithdrawal(
        amount: amount,
        paymentMethod: paymentMethod,
        accountDetails: accountDetails,
        phone: phone,
        pin: pin,
      );
      state = const WalletActionsState();
      return result;
    } catch (e) {
      state = WalletActionsState(error: e.toString());
      rethrow;
    }
  }

  Future<void> saveBankInfo({
    required String bankName,
    required String holderName,
    required String accountNumber,
    String? iban,
  }) async {
    state = const WalletActionsState(isLoading: true);
    try {
      await _datasource.saveBankInfo(
        bankName: bankName,
        holderName: holderName,
        accountNumber: accountNumber,
        iban: iban,
      );
      state = const WalletActionsState();
    } catch (e) {
      state = WalletActionsState(error: e.toString());
      rethrow;
    }
  }

  Future<void> saveMobileMoneyInfo({
    required String operator,
    required String phoneNumber,
    required String accountName,
    bool isPrimary = true,
  }) async {
    state = const WalletActionsState(isLoading: true);
    try {
      await _datasource.saveMobileMoneyInfo(
        operator: operator,
        phoneNumber: phoneNumber,
        accountName: accountName,
        isPrimary: isPrimary,
      );
      state = const WalletActionsState();
    } catch (e) {
      state = WalletActionsState(error: e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWithdrawalSettings() async {
    state = const WalletActionsState(isLoading: true);
    try {
      final result = await _datasource.getWithdrawalSettings();
      state = const WalletActionsState();
      return result;
    } catch (e) {
      state = WalletActionsState(error: e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> setWithdrawalThreshold({
    required double threshold,
    required bool autoWithdraw,
  }) async {
    state = const WalletActionsState(isLoading: true);
    try {
      final result = await _datasource.setWithdrawalThreshold(
        threshold: threshold,
        autoWithdraw: autoWithdraw,
      );
      state = const WalletActionsState();
      return result;
    } catch (e) {
      state = WalletActionsState(error: e.toString());
      rethrow;
    }
  }

  /// Configure le code PIN de retrait (première fois)
  Future<Map<String, dynamic>> setWithdrawalPin(String pin) async {
    state = const WalletActionsState(isLoading: true);
    try {
      final result = await _datasource.setWithdrawalPin(pin);
      // Invalider le cache des settings pour refléter has_pin: true
      ref.invalidate(withdrawalSettingsProvider);
      state = const WalletActionsState();
      return result;
    } catch (e) {
      state = WalletActionsState(error: e.toString());
      rethrow;
    }
  }

  /// Modifie le code PIN de retrait
  Future<Map<String, dynamic>> changeWithdrawalPin({
    required String currentPin,
    required String newPin,
  }) async {
    state = const WalletActionsState(isLoading: true);
    try {
      final result = await _datasource.changeWithdrawalPin(
        currentPin: currentPin,
        newPin: newPin,
      );
      state = const WalletActionsState();
      return result;
    } catch (e) {
      state = WalletActionsState(error: e.toString());
      rethrow;
    }
  }

  /// Demande la réinitialisation du PIN (envoie OTP par SMS)
  Future<Map<String, dynamic>> requestPinReset() async {
    state = const WalletActionsState(isLoading: true);
    try {
      final result = await _datasource.requestPinReset();
      state = const WalletActionsState();
      return result;
    } catch (e) {
      state = WalletActionsState(error: e.toString());
      rethrow;
    }
  }

  /// Confirme la réinitialisation du PIN avec l'OTP
  Future<Map<String, dynamic>> confirmPinReset({
    required String otp,
    required String newPin,
  }) async {
    state = const WalletActionsState(isLoading: true);
    try {
      final result = await _datasource.confirmPinReset(
        otp: otp,
        newPin: newPin,
      );
      // Invalider le cache des settings
      ref.invalidate(withdrawalSettingsProvider);
      state = const WalletActionsState();
      return result;
    } catch (e) {
      state = WalletActionsState(error: e.toString());
      rethrow;
    }
  }
}

final walletActionsProvider =
    NotifierProvider.autoDispose<WalletActionsNotifier, WalletActionsState>(
      WalletActionsNotifier.new,
    );

/// Provider pour les informations de paiement enregistrées
final paymentInfoProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final datasource = WalletRemoteDataSourceImpl(apiClient: apiClient);
  return datasource.getPaymentInfo();
});

/// Provider pour les paramètres de retrait (inclut has_pin)
final withdrawalSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final apiClient = ref.watch(apiClientProvider);
      final datasource = WalletRemoteDataSourceImpl(apiClient: apiClient);
      return datasource.getWithdrawalSettings();
    });

/// Provider pour vérifier si le PIN de retrait est configuré
final hasPinConfiguredProvider = FutureProvider.autoDispose<bool>((ref) async {
  final settings = await ref.watch(withdrawalSettingsProvider.future);
  return settings['has_pin'] == true;
});
