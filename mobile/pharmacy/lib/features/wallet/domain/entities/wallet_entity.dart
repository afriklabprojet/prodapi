/// Entité représentant les données du portefeuille
class WalletEntity {
  final double balance;
  final String currency;
  final double totalEarnings;
  final double totalCommissionPaid;
  final List<TransactionEntity> transactions;

  const WalletEntity({
    required this.balance,
    required this.currency,
    required this.totalEarnings,
    required this.totalCommissionPaid,
    required this.transactions,
  });

  /// Solde net (balance - commissions en attente)
  double get netBalance => balance;
  
  /// Pourcentage de commission moyen
  double get averageCommissionRate => 
      totalEarnings > 0 ? (totalCommissionPaid / totalEarnings) * 100 : 0;
}

/// Type de transaction
enum TransactionType {
  credit,
  debit,
  unknown;
  
  static TransactionType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
        return TransactionType.debit;
      default:
        return TransactionType.unknown;
    }
  }
}

/// Entité représentant une transaction
class TransactionEntity {
  final int id;
  final double amount;
  final TransactionType type;
  final String? description;
  final String? reference;
  final DateTime? date;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    this.description,
    this.reference,
    this.date,
  });

  /// Vérifie si c'est un crédit
  bool get isCredit => type == TransactionType.credit;
  
  /// Vérifie si c'est un débit
  bool get isDebit => type == TransactionType.debit;
}

/// Entité pour les paramètres de retrait
class WithdrawalSettingsEntity {
  final double threshold;
  final bool autoWithdraw;
  final bool hasPin;
  final bool hasMobileMoney;
  final bool hasBankInfo;
  final WithdrawalConfigEntity config;

  const WithdrawalSettingsEntity({
    required this.threshold,
    required this.autoWithdraw,
    this.hasPin = false,
    this.hasMobileMoney = false,
    this.hasBankInfo = false,
    this.config = const WithdrawalConfigEntity(),
  });

  /// Vérifie si le retrait automatique est configuré correctement
  bool get isAutoWithdrawReady => 
      autoWithdraw && (hasMobileMoney || hasBankInfo) && (!config.requirePin || hasPin);
}

/// Configuration des règles de retrait
class WithdrawalConfigEntity {
  final double minThreshold;
  final double maxThreshold;
  final double defaultThreshold;
  final double step;
  final bool autoWithdrawAllowed;
  final bool requirePin;
  final bool requireMobileMoney;

  const WithdrawalConfigEntity({
    this.minThreshold = 10000,
    this.maxThreshold = 500000,
    this.defaultThreshold = 50000,
    this.step = 5000,
    this.autoWithdrawAllowed = true,
    this.requirePin = true,
    this.requireMobileMoney = true,
  });
}

/// Résultat d'une demande de retrait
class WithdrawResultEntity {
  final bool success;
  final String message;
  final String? reference;
  final String? status;

  const WithdrawResultEntity({
    required this.success,
    required this.message,
    this.reference,
    this.status,
  });
}

/// Statistiques du wallet par période
class WalletStatsEntity {
  final double totalCredits;
  final double totalDebits;
  final int transactionCount;
  final double averageTransaction;
  final String period;

  const WalletStatsEntity({
    required this.totalCredits,
    required this.totalDebits,
    required this.transactionCount,
    required this.averageTransaction,
    required this.period,
  });

  /// Solde net de la période
  double get netBalance => totalCredits - totalDebits;
}
