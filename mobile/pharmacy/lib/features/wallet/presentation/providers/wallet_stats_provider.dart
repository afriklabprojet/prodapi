import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/wallet_remote_datasource.dart';

/// Wallet period stats from the server.
class WalletStats {
  final double totalCredits;
  final double totalDebits;
  final int transactionCount;

  const WalletStats({
    required this.totalCredits,
    required this.totalDebits,
    required this.transactionCount,
  });

  factory WalletStats.fromJson(Map<String, dynamic> json) {
    return WalletStats(
      totalCredits:
          double.tryParse(json['total_credits']?.toString() ?? '0') ?? 0,
      totalDebits:
          double.tryParse(json['total_debits']?.toString() ?? '0') ?? 0,
      transactionCount:
          int.tryParse(json['transaction_count']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Maps French UI period labels to API period parameter values.
String _mapPeriodToApi(String selectedPeriod) {
  switch (selectedPeriod) {
    case "Aujourd'hui":
      return 'today';
    case 'Cette semaine':
      return 'week';
    case 'Ce mois':
      return 'month';
    case 'Cette année':
      return 'year';
    default:
      return 'month';
  }
}

/// Provider that fetches wallet stats from the server for a given period.
final walletStatsProvider = FutureProvider.autoDispose
    .family<WalletStats, String>((ref, selectedPeriod) async {
      final datasource = ref.watch(walletRemoteDataSourceProvider);
      final apiPeriod = _mapPeriodToApi(selectedPeriod);
      final data = await datasource.getStatsByPeriod(apiPeriod);
      return WalletStats.fromJson(data);
    });
