import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/usecases/wallet_usecases.dart';
import 'wallet_state.dart';

class WalletNotifier extends StateNotifier<WalletState> {
  final GetWalletUseCase getWalletUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;
  final InitiateTopUpUseCase initiateTopUpUseCase;
  final CheckPaymentStatusUseCase checkPaymentStatusUseCase;
  final TopUpWalletUseCase topUpWalletUseCase;
  final WithdrawWalletUseCase withdrawWalletUseCase;
  final PayOrderUseCase payOrderUseCase;

  WalletNotifier({
    required this.getWalletUseCase,
    required this.getTransactionsUseCase,
    required this.initiateTopUpUseCase,
    required this.checkPaymentStatusUseCase,
    required this.topUpWalletUseCase,
    required this.withdrawWalletUseCase,
    required this.payOrderUseCase,
  }) : super(const WalletState.initial());

  Future<void> loadWallet() async {
    state = state.copyWith(status: WalletStatus.loading);
    final result = await getWalletUseCase();
    result.fold(
      (failure) => state = state.copyWith(
        status: WalletStatus.error,
        errorMessage: failure.message,
      ),
      (wallet) => state = state.copyWith(
        status: WalletStatus.loaded,
        wallet: wallet,
        clearError: true,
      ),
    );
  }

  Future<void> loadTransactions({String? category}) async {
    final result = await getTransactionsUseCase(category: category);
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (transactions) => state = state.copyWith(
        transactions: transactions,
        clearError: true,
      ),
    );
  }

  Future<void> loadAll() async {
    state = state.copyWith(status: WalletStatus.loading);
    final walletResult = await getWalletUseCase();
    final txResult = await getTransactionsUseCase();

    walletResult.fold(
      (failure) => state = state.copyWith(
        status: WalletStatus.error,
        errorMessage: failure.message,
      ),
      (wallet) {
        final transactions = txResult.fold(
          (_) => state.transactions,
          (txList) => txList,
        );
        state = state.copyWith(
          status: WalletStatus.loaded,
          wallet: wallet,
          transactions: transactions,
          clearError: true,
        );
      },
    );
  }

  /// Initier un rechargement via Jeko - retourne le résultat avec redirect_url
  Future<PaymentInitResult?> initiateTopUp({
    required double amount,
    required String paymentMethod,
  }) async {
    state = state.copyWith(status: WalletStatus.loading);
    final result = await initiateTopUpUseCase(
      amount: amount,
      paymentMethod: paymentMethod,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: failure.message,
        );
        return null;
      },
      (paymentInit) {
        state = state.copyWith(
          status: WalletStatus.loaded,
          clearError: true,
        );
        return paymentInit;
      },
    );
  }

  /// Vérifier le statut d'un paiement
  Future<PaymentStatusResult?> checkPaymentStatus(String reference) async {
    final result = await checkPaymentStatusUseCase(reference);
    return result.fold(
      (failure) => null,
      (status) => status,
    );
  }

  Future<bool> topUp({
    required double amount,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    state = state.copyWith(status: WalletStatus.loading);
    final result = await topUpWalletUseCase(
      amount: amount,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: failure.message,
        );
        return false;
      },
      (transaction) {
        state = state.copyWith(
          status: WalletStatus.loaded,
          successMessage: 'Rechargement effectué avec succès',
          clearError: true,
        );
        loadAll();
        return true;
      },
    );
  }

  Future<bool> withdraw({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) async {
    state = state.copyWith(status: WalletStatus.loading);
    final result = await withdrawWalletUseCase(
      amount: amount,
      paymentMethod: paymentMethod,
      phoneNumber: phoneNumber,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: failure.message,
        );
        return false;
      },
      (transaction) {
        state = state.copyWith(
          status: WalletStatus.loaded,
          successMessage: 'Demande de retrait enregistrée',
          clearError: true,
        );
        loadAll();
        return true;
      },
    );
  }

  Future<bool> payOrder({
    required double amount,
    required String orderReference,
  }) async {
    state = state.copyWith(status: WalletStatus.loading);
    final result = await payOrderUseCase(
      amount: amount,
      orderReference: orderReference,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: failure.message,
        );
        return false;
      },
      (transaction) {
        state = state.copyWith(
          status: WalletStatus.loaded,
          successMessage: 'Paiement effectué',
          clearError: true,
        );
        loadAll();
        return true;
      },
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
