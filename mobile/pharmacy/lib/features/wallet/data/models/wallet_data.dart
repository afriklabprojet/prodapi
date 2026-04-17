class WalletData {
  final double balance;
  final String currency;
  final double totalEarnings;
  final double totalCommissionPaid;
  final List<WalletTransaction> transactions;

  WalletData({
    required this.balance,
    required this.currency,
    required this.totalEarnings,
    required this.totalCommissionPaid,
    required this.transactions,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'XOF',
      totalEarnings: double.tryParse((json['total_earnings'] ?? 0).toString()) ?? 0.0,
      totalCommissionPaid: double.tryParse((json['total_commission_paid'] ?? 0).toString()) ?? 0.0,
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => WalletTransaction.fromJson(e))
          .toList(),
    );
  }
}

class WalletTransaction {
  final int id;
  final double amount;
  final String type; // 'credit' | 'debit'
  final String? description;
  final String? reference;
  final String? date;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.description,
    this.reference,
    this.date,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? 'unknown',
      description: json['description'],
      reference: json['reference'],
      date: json['date'],
    );
  }
}

/// Paramètres de seuil de retrait
class WithdrawalSettings {
  final double threshold;
  final bool autoWithdraw;
  final bool hasPin;
  final bool hasMobileMoney;
  final bool hasBankInfo;
  final WithdrawalConfig config;

  WithdrawalSettings({
    required this.threshold,
    required this.autoWithdraw,
    this.hasPin = false,
    this.hasMobileMoney = false,
    this.hasBankInfo = false,
    WithdrawalConfig? config,
  }) : config = config ?? WithdrawalConfig.defaults();

  factory WithdrawalSettings.fromJson(Map<String, dynamic> json) {
    return WithdrawalSettings(
      threshold: (json['threshold'] as num?)?.toDouble() ?? 50000,
      autoWithdraw: json['auto_withdraw'] ?? false,
      hasPin: json['has_pin'] ?? false,
      hasMobileMoney: json['has_mobile_money'] ?? false,
      hasBankInfo: json['has_bank_info'] ?? false,
      config: json['config'] != null 
          ? WithdrawalConfig.fromJson(json['config']) 
          : WithdrawalConfig.defaults(),
    );
  }

  Map<String, dynamic> toJson() => {
    'threshold': threshold,
    'auto_withdraw': autoWithdraw,
    'has_pin': hasPin,
    'has_mobile_money': hasMobileMoney,
    'has_bank_info': hasBankInfo,
  };
}

/// Configuration globale des seuils de retrait (depuis Filament admin)
class WithdrawalConfig {
  final double minThreshold;
  final double maxThreshold;
  final double defaultThreshold;
  final double step;
  final bool autoWithdrawAllowed;
  final bool requirePin;
  final bool requireMobileMoney;

  WithdrawalConfig({
    required this.minThreshold,
    required this.maxThreshold,
    required this.defaultThreshold,
    required this.step,
    required this.autoWithdrawAllowed,
    required this.requirePin,
    required this.requireMobileMoney,
  });

  factory WithdrawalConfig.defaults() {
    return WithdrawalConfig(
      minThreshold: 10000,
      maxThreshold: 500000,
      defaultThreshold: 50000,
      step: 5000,
      autoWithdrawAllowed: true,
      requirePin: true,
      requireMobileMoney: true,
    );
  }

  factory WithdrawalConfig.fromJson(Map<String, dynamic> json) {
    return WithdrawalConfig(
      minThreshold: (json['min_threshold'] as num?)?.toDouble() ?? 10000,
      maxThreshold: (json['max_threshold'] as num?)?.toDouble() ?? 500000,
      defaultThreshold: (json['default_threshold'] as num?)?.toDouble() ?? 50000,
      step: (json['step'] as num?)?.toDouble() ?? 5000,
      autoWithdrawAllowed: json['auto_withdraw_allowed'] ?? true,
      requirePin: json['require_pin'] ?? true,
      requireMobileMoney: json['require_mobile_money'] ?? true,
    );
  }
}
