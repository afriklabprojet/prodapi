import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../domain/usecases/wallet_usecases.dart';
import 'wallet_notifier.dart';
import 'wallet_state.dart';

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final repository = ref.watch(walletRepositoryProvider);

  return WalletNotifier(
    getWalletUseCase: GetWalletUseCase(repository),
    getTransactionsUseCase: GetTransactionsUseCase(repository),
    initiateTopUpUseCase: InitiateTopUpUseCase(repository),
    checkPaymentStatusUseCase: CheckPaymentStatusUseCase(repository),
    topUpWalletUseCase: TopUpWalletUseCase(repository),
    withdrawWalletUseCase: WithdrawWalletUseCase(repository),
    payOrderUseCase: PayOrderUseCase(repository),
  );
});
