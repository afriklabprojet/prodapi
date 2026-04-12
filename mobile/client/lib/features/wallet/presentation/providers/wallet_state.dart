import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet_entity.dart';

enum WalletStatus { initial, loading, loaded, error }

class WalletState extends Equatable {
  final WalletStatus status;
  final WalletEntity? wallet;
  final List<WalletTransactionEntity> transactions;
  final String? errorMessage;
  final String? successMessage;

  const WalletState({
    required this.status,
    this.wallet,
    required this.transactions,
    this.errorMessage,
    this.successMessage,
  });

  const WalletState.initial()
      : status = WalletStatus.initial,
        wallet = null,
        transactions = const [],
        errorMessage = null,
        successMessage = null;

  WalletState copyWith({
    WalletStatus? status,
    WalletEntity? wallet,
    List<WalletTransactionEntity>? transactions,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return WalletState(
      status: status ?? this.status,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      errorMessage: clearError ? null : errorMessage,
      successMessage: clearSuccess ? null : successMessage,
    );
  }

  double get balance => wallet?.balance ?? 0;
  double get availableBalance => wallet?.availableBalance ?? 0;
  String get currency => wallet?.currency ?? 'XOF';
  bool get isLoading => status == WalletStatus.loading;

  @override
  List<Object?> get props => [status, wallet, transactions, errorMessage, successMessage];
}
