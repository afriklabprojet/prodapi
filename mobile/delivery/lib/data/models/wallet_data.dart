import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_data.freezed.dart';

@freezed
abstract class WalletData with _$WalletData {
  const factory WalletData({
    required double balance,
    @Default('XOF') String currency,
    @Default([]) List<WalletTransaction> transactions,
    @Default(0.0) double? pendingPayouts,
    double? availableBalance,
    @Default(true) bool canDeliver,
    @Default(200) int commissionAmount,
    @Default(0.0) double totalTopups,
    @Default(0.0) double totalEarnings,
    @Default(0.0) double todayEarnings,
    @Default(0.0) double totalCommissions,
    @Default(0) int deliveriesCount,
  }) = _WalletData;

  factory WalletData.fromJson(Map<String, dynamic> json) {
    // Les stats peuvent être au premier niveau ou imbriquées dans 'statistics'
    final stats = json['statistics'] as Map<String, dynamic>? ?? {};

    T? pick<T>(String key) {
      if (json[key] != null) return json[key] as T;
      if (stats[key] != null) return stats[key] as T;
      return null;
    }

    double pickDouble(String key) {
      final v = pick<dynamic>(key);
      if (v == null) return 0;
      return double.tryParse(v.toString()) ?? 0;
    }

    return WalletData(
      balance: double.parse(json['balance'].toString()),
      currency: json['currency'] ?? 'XOF',
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingPayouts: json['pending_payouts'] != null
          ? double.tryParse(json['pending_payouts'].toString())
          : 0.0,
      availableBalance: json['available_balance'] != null
          ? double.tryParse(json['available_balance'].toString())
          : null,
      canDeliver: json['can_deliver'] as bool? ?? true,
      commissionAmount: (json['commission_amount'] as num?)?.toInt() ?? 200,
      totalTopups: pickDouble('total_topups'),
      totalEarnings: pickDouble('total_delivery_earnings') != 0
          ? pickDouble('total_delivery_earnings')
          : pickDouble('total_earnings'),
      todayEarnings: pickDouble('today_earnings'),
      totalCommissions: pickDouble('total_commissions'),
      deliveriesCount:
          (pick<dynamic>('deliveries_count') as num?)?.toInt() ?? 0,
    );
  }
}

@freezed
abstract class WalletTransaction with _$WalletTransaction {
  const WalletTransaction._();

  const factory WalletTransaction({
    required int id,
    required double amount,
    @Default('debit') String type,
    String? category,
    String? description,
    String? reference,
    String? status,
    int? deliveryId,
    required DateTime createdAt,
  }) = _WalletTransaction;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      amount: double.parse(json['amount'].toString()),
      type: json['type']?.toString().toLowerCase() ?? 'debit',
      category: json['category'],
      description: json['description'],
      reference: json['reference'],
      status: json['status'],
      deliveryId: json['delivery_id'],
      createdAt: _parseCreatedAt(json),
    );
  }

  /// Parse created_at avec fallback sur 'date', log si parse échoue
  static DateTime _parseCreatedAt(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'] ?? json['date'];
    if (createdAtRaw != null) {
      final parsed = DateTime.tryParse(createdAtRaw.toString());
      if (parsed != null) return parsed;
    }
    // Fallback — ne devrait pas arriver sur des données valides
    return DateTime.now();
  }

  bool get isCredit => type == 'credit';
  bool get isCommission => category == 'commission';
  bool get isTopUp => category == 'topup';
  bool get isWithdrawal => category == 'withdrawal';
}
