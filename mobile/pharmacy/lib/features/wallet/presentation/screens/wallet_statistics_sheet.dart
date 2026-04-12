import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/models/wallet_data.dart';

/// Map French period labels to API period values
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

void showWalletStatisticsSheet(
  BuildContext parentContext,
  WalletRemoteDataSource datasource,
  String selectedPeriod,
) {
  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => _WalletStatisticsContent(
        scrollController: scrollController,
        datasource: datasource,
        selectedPeriod: selectedPeriod,
      ),
    ),
  );
}

class _WalletStatisticsContent extends StatefulWidget {
  final ScrollController scrollController;
  final WalletRemoteDataSource datasource;
  final String selectedPeriod;

  const _WalletStatisticsContent({
    required this.scrollController,
    required this.datasource,
    required this.selectedPeriod,
  });

  @override
  State<_WalletStatisticsContent> createState() =>
      _WalletStatisticsContentState();
}

class _WalletStatisticsContentState extends State<_WalletStatisticsContent> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    final apiPeriod = _mapPeriodToApi(widget.selectedPeriod);
    _statsFuture = widget.datasource.getStatsByPeriod(apiPeriod);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;

          final totalCredits =
              (snapshot.data?['total_credits'] as num?)?.toDouble() ?? 0.0;
          final totalDebits =
              (snapshot.data?['total_debits'] as num?)?.toDouble() ?? 0.0;
          final nbTransactions =
              (snapshot.data?['transaction_count'] as num?)?.toInt() ?? 0;
          final avgTransaction =
              (snapshot.data?['average_transaction'] as num?)?.toDouble() ??
              0.0;

          return SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Statistiques detaillees',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade300,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                final apiPeriod = _mapPeriodToApi(
                                  widget.selectedPeriod,
                                );
                                _statsFuture = widget.datasource
                                    .getStatsByPeriod(apiPeriod);
                              });
                            },
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          title: 'Total Revenus',
                          value: currencyFormat.format(totalCredits),
                          icon: Icons.arrow_downward_rounded,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          title: 'Total Depenses',
                          value: currencyFormat.format(totalDebits),
                          icon: Icons.arrow_upward_rounded,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          title: 'Transactions',
                          value: nbTransactions.toString(),
                          icon: Icons.receipt_long_rounded,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          title: 'Moyenne',
                          value: currencyFormat.format(avgTransaction),
                          icon: Icons.trending_flat_rounded,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Repartition',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildProgressBar(
                          'Revenus',
                          totalCredits,
                          totalCredits + totalDebits,
                          Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _buildProgressBar(
                          'Depenses',
                          totalDebits,
                          totalCredits + totalDebits,
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.textPrimary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solde Net',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                          ],
                        ),
                        Text(
                          currencyFormat.format(totalCredits - totalDebits),
                          style: TextStyle(
                            color: (totalCredits - totalDebits) >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

List<WalletTransaction> filterWalletTransactionsByPeriod(
  List<WalletTransaction> transactions,
  String selectedPeriod,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DateTime startDate;
  switch (selectedPeriod) {
    case "Aujourd'hui":
      startDate = today;
    case 'Cette semaine':
      startDate = today.subtract(Duration(days: now.weekday - 1));
    case 'Ce mois':
      startDate = DateTime(now.year, now.month, 1);
    case 'Cette année':
      startDate = DateTime(now.year, 1, 1);
    default:
      return transactions;
  }

  return transactions.where((tx) {
    if (tx.date == null || tx.date!.isEmpty) return false;

    DateTime? txDate = _parseTransactionDate(tx.date!);
    if (txDate == null) return false;

    return !txDate.isBefore(startDate);
  }).toList();
}

/// Parse la date de transaction avec plusieurs formats possibles
DateTime? _parseTransactionDate(String dateStr) {
  // Try ISO format first (2026-04-02T10:30:00)
  DateTime? result = DateTime.tryParse(dateStr);
  if (result != null) return result;

  // Try various French date formats
  final formats = [
    DateFormat('dd/MM/yyyy HH:mm'), // 02/04/2026 10:30
    DateFormat('d/M/yyyy HH:mm'), // 2/4/2026 10:30
    DateFormat('dd/MM/yyyy H:mm'), // 02/04/2026 9:30
    DateFormat('d/M/yyyy H:mm'), // 2/4/2026 9:30
    DateFormat('dd/MM/yyyy'), // 02/04/2026
    DateFormat('d/M/yyyy'), // 2/4/2026
  ];

  for (final format in formats) {
    try {
      return format.parseStrict(dateStr);
    } catch (_) {
      // Try next format
    }
  }

  // Last resort: try to extract date parts manually
  try {
    final parts = dateStr.split(' ');
    final datePart = parts[0].split('/');
    if (datePart.length == 3) {
      final day = int.parse(datePart[0]);
      final month = int.parse(datePart[1]);
      final year = int.parse(datePart[2]);
      int hour = 0, minute = 0;
      if (parts.length > 1) {
        final timePart = parts[1].split(':');
        hour = int.tryParse(timePart[0]) ?? 0;
        minute = timePart.length > 1 ? (int.tryParse(timePart[1]) ?? 0) : 0;
      }
      return DateTime(year, month, day, hour, minute);
    }
  } catch (_) {
    // Parsing failed
  }

  return null;
}

Widget _buildStatBox({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

Widget _buildProgressBar(
  String label,
  double value,
  double total,
  Color color,
) {
  final percentage = total > 0 ? (value / total * 100) : 0.0;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ),
    ],
  );
}
