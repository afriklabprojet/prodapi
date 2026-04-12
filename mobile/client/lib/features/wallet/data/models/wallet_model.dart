import '../../domain/entities/wallet_entity.dart';

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class WalletModel {
  final double balance;
  final String currency;
  final double pendingWithdrawals;
  final double availableBalance;
  final int minimumWithdrawal;
  final WalletStatisticsModel statistics;

  const WalletModel({
    required this.balance,
    this.currency = 'XOF',
    this.pendingWithdrawals = 0,
    required this.availableBalance,
    this.minimumWithdrawal = 500,
    required this.statistics,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final statsJson = json['statistics'] as Map<String, dynamic>? ?? {};
    return WalletModel(
      balance: _toDouble(json['balance']),
      currency: json['currency'] as String? ?? 'XOF',
      pendingWithdrawals: _toDouble(json['pending_withdrawals']),
      availableBalance: _toDouble(json['available_balance']),
      minimumWithdrawal: _toInt(json['minimum_withdrawal']),
      statistics: WalletStatisticsModel.fromJson(statsJson),
    );
  }

  WalletEntity toEntity() {
    return WalletEntity(
      balance: balance,
      currency: currency,
      pendingWithdrawals: pendingWithdrawals,
      availableBalance: availableBalance,
      minimumWithdrawal: minimumWithdrawal,
      statistics: statistics.toEntity(),
    );
  }
}

class WalletStatisticsModel {
  final double totalTopups;
  final double totalOrderPayments;
  final double totalRefunds;
  final double totalWithdrawals;
  final int ordersPaid;

  const WalletStatisticsModel({
    this.totalTopups = 0,
    this.totalOrderPayments = 0,
    this.totalRefunds = 0,
    this.totalWithdrawals = 0,
    this.ordersPaid = 0,
  });

  factory WalletStatisticsModel.fromJson(Map<String, dynamic> json) {
    return WalletStatisticsModel(
      totalTopups: _toDouble(json['total_topups']),
      totalOrderPayments: _toDouble(json['total_order_payments']),
      totalRefunds: _toDouble(json['total_refunds']),
      totalWithdrawals: _toDouble(json['total_withdrawals']),
      ordersPaid: _toInt(json['orders_paid']),
    );
  }

  WalletStatistics toEntity() {
    return WalletStatistics(
      totalTopups: totalTopups,
      totalOrderPayments: totalOrderPayments,
      totalRefunds: totalRefunds,
      totalWithdrawals: totalWithdrawals,
      ordersPaid: ordersPaid,
    );
  }
}

class WalletTransactionModel {
  final int id;
  final String type;
  final String category;
  final double amount;
  final double balanceAfter;
  final String reference;
  final String description;
  final String? status;
  final String? paymentMethod;
  final String createdAt;

  const WalletTransactionModel({
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

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: _toInt(json['id']),
      type: json['type'] as String? ?? 'CREDIT',
      category: json['category'] as String? ?? 'topup',
      amount: _toDouble(json['amount']),
      balanceAfter: _toDouble(json['balance_after']),
      reference: json['reference'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String?,
      paymentMethod: json['payment_method'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  WalletTransactionEntity toEntity() {
    return WalletTransactionEntity(
      id: id,
      type: type.toUpperCase() == 'CREDIT'
          ? TransactionType.credit
          : TransactionType.debit,
      category: _parseCategory(category),
      amount: amount,
      balanceAfter: balanceAfter,
      reference: reference,
      description: description,
      status: status,
      paymentMethod: paymentMethod,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }

  TransactionCategory _parseCategory(String cat) {
    switch (cat) {
      case 'topup':
        return TransactionCategory.topup;
      case 'order_payment':
        return TransactionCategory.orderPayment;
      case 'refund':
        return TransactionCategory.refund;
      case 'withdrawal':
        return TransactionCategory.withdrawal;
      default:
        return TransactionCategory.topup;
    }
  }
}
