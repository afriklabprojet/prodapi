import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/models/wallet_data.dart';

/// Provider principal du portefeuille - FutureProvider car walletScreen utilise .when()
final walletProvider = FutureProvider.autoDispose<WalletData>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final datasource = WalletRemoteDataSourceImpl(apiClient: apiClient);
  final data = await datasource.getWalletData();
  return WalletData.fromJson(data);
});

/// État des actions wallet
class WalletActionsState {
  final bool isLoading;
  final String? error;

  const WalletActionsState({this.isLoading = false, this.error});
}

/// Notifier pour les actions wallet (retrait, paramètres, etc.)
class WalletActionsNotifier extends StateNotifier<WalletActionsState> {
  final WalletRemoteDataSource _datasource;

  WalletActionsNotifier(this._datasource) : super(const WalletActionsState());

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
}

final walletActionsProvider =
    StateNotifierProvider.autoDispose<WalletActionsNotifier, WalletActionsState>((ref) {
  final datasource = ref.watch(walletRemoteDataSourceProvider);
  return WalletActionsNotifier(datasource);
});
