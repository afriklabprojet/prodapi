import 'package:equatable/equatable.dart';

enum TransactionType { credit, debit }

enum TransactionCategory { topup, orderPayment, refund, withdrawal }

/// Résultat de l'initiation d'un paiement Jeko
class PaymentInitResult extends Equatable {
  final String reference;
  final String redirectUrl;
  final int amount;
  final String currency;
  final String paymentMethod;

  const PaymentInitResult({
    required this.reference,
    required this.redirectUrl,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
  });

  factory PaymentInitResult.fromJson(Map<String, dynamic> json) {
    return PaymentInitResult(
      reference: json['reference'] as String,
      redirectUrl: json['redirect_url'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String? ?? 'XOF',
      paymentMethod: json['payment_method'] as String,
    );
  }

  @override
  List<Object?> get props => [reference, redirectUrl, amount];
}

/// Résultat du statut d'un paiement Jeko
class PaymentStatusResult extends Equatable {
  final String reference;
  final String status;
  final String statusLabel;
  final bool isFinal;
  final int amount;
  final String? errorMessage;

  const PaymentStatusResult({
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.isFinal,
    required this.amount,
    this.errorMessage,
  });

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    final reference = (json['reference'] ?? json['payment_reference'] ?? '')
        .toString();
    final status = (json['payment_status'] ?? json['status'] ?? '').toString();
    final statusLabel =
        (json['payment_status_label'] ?? json['status_label'] ?? status)
            .toString();
    final amountRaw = json['amount'];
    final amount = amountRaw is num
        ? amountRaw.toInt()
        : int.tryParse(amountRaw?.toString() ?? '') ?? 0;
    final isFinal =
        json['is_final'] as bool? ??
        const [
          'success',
          'completed',
          'failed',
          'expired',
          'cancelled',
        ].contains(status);

    return PaymentStatusResult(
      reference: reference,
      status: status,
      statusLabel: statusLabel,
      isFinal: isFinal,
      amount: amount,
      errorMessage: (json['error_message'] ?? json['message']) as String?,
    );
  }

  bool get isSuccess => status == 'success' || status == 'completed';
  bool get isFailed =>
      status == 'failed' || status == 'expired' || status == 'cancelled';

  @override
  List<Object?> get props => [reference, status, isFinal];
}

class WalletEntity extends Equatable {
  final double balance;
  final String currency;
  final double pendingWithdrawals;
  final double availableBalance;
  final int minimumWithdrawal;
  final WalletStatistics statistics;

  const WalletEntity({
    required this.balance,
    this.currency = 'XOF',
    this.pendingWithdrawals = 0,
    required this.availableBalance,
    this.minimumWithdrawal = 500,
    required this.statistics,
  });

  bool get canWithdraw => availableBalance >= minimumWithdrawal;

  @override
  List<Object?> get props => [
    balance,
    currency,
    pendingWithdrawals,
    availableBalance,
  ];
}

class WalletStatistics extends Equatable {
  final double totalTopups;
  final double totalOrderPayments;
  final double totalRefunds;
  final double totalWithdrawals;
  final int ordersPaid;

  const WalletStatistics({
    this.totalTopups = 0,
    this.totalOrderPayments = 0,
    this.totalRefunds = 0,
    this.totalWithdrawals = 0,
    this.ordersPaid = 0,
  });

  @override
  List<Object?> get props => [
    totalTopups,
    totalOrderPayments,
    totalRefunds,
    totalWithdrawals,
    ordersPaid,
  ];
}

class WalletTransactionEntity extends Equatable {
  final int id;
  final TransactionType type;
  final TransactionCategory category;
  final double amount;
  final double balanceAfter;
  final String reference;
  final String description;
  final String? status;
  final String? paymentMethod;
  final DateTime createdAt;

  const WalletTransactionEntity({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.balanceAfter,
    required this.reference,
    required this.description,
    this.status,
    this.paymentMethod,
    required this.createdAt,
  });

  bool get isCredit => type == TransactionType.credit;
  bool get isDebit => type == TransactionType.debit;
  bool get isPending => status == 'pending';

  String get categoryLabel {
    switch (category) {
      case TransactionCategory.topup:
        return 'Rechargement';
      case TransactionCategory.orderPayment:
        return 'Paiement commande';
      case TransactionCategory.refund:
        return 'Remboursement';
      case TransactionCategory.withdrawal:
        return 'Retrait';
    }
  }

  @override
  List<Object?> get props => [id, type, category, amount, reference, createdAt];
}
