import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/delivery.dart';
import '../../data/models/wallet_data.dart';

/// Service pour exporter les données de revenus en PDF et CSV
class EarningsExportService {
  static final EarningsExportService instance = EarningsExportService._();
  EarningsExportService._();

  final _currencyFormat = NumberFormat("#,##0", "fr_FR");
  final _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  /// Exporte les livraisons en CSV
  Future<String?> exportToCSV({
    required List<Delivery> deliveries,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final buffer = StringBuffer();

      // Header
      buffer.writeln(
        'ID,Date,Pharmacie,Adresse,Montant Total,Frais Livraison,Statut',
      );

      // Data
      for (final delivery in deliveries) {
        final date = delivery.createdAt != null
            ? DateTime.tryParse(delivery.createdAt!)
            : null;

        // Escape commas in text fields
        final pharmacyName = _escapeCSV(delivery.pharmacyName);
        final address = _escapeCSV(delivery.deliveryAddress);
        final status = delivery.status == 'delivered' ? 'Livrée' : 'Annulée';

        buffer.writeln(
          '${delivery.id},'
          '${date != null ? _dateTimeFormat.format(date) : ""},'
          '$pharmacyName,'
          '$address,'
          '${delivery.totalAmount},'
          '${delivery.deliveryFee},'
          '$status',
        );
      }

      // Calculate totals
      double totalEarnings = 0;
      int deliveredCount = 0;
      for (final d in deliveries) {
        if (d.status == 'delivered') {
          totalEarnings += d.deliveryFee ?? 0;
          deliveredCount++;
        }
      }

      buffer.writeln('');
      buffer.writeln('RÉSUMÉ');
      buffer.writeln('Total livraisons,$deliveredCount');
      buffer.writeln(
        'Total gains,${_currencyFormat.format(totalEarnings)} FCFA',
      );

      // Période
      if (dateFrom != null || dateTo != null) {
        buffer.writeln(
          'Période,${dateFrom != null ? _dateFormat.format(dateFrom) : "Début"} - ${dateTo != null ? _dateFormat.format(dateTo) : "Fin"}',
        );
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/revenus_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      if (kDebugMode) debugPrint('📄 CSV exporté: ${file.path}');

      return file.path;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur export CSV: $e');
      return null;
    }
  }

  /// Exporte les transactions du wallet en CSV
  Future<String?> exportTransactionsToCSV({
    required List<WalletTransaction> transactions,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final buffer = StringBuffer();

      // Header
      buffer.writeln('ID,Date,Type,Catégorie,Description,Montant,Statut');

      // Data
      for (final tx in transactions) {
        final type = tx.isCredit ? 'Crédit' : 'Débit';
        final category = _getCategoryLabel(tx.category ?? '');
        final description = _escapeCSV(tx.description ?? '');
        final amount = tx.isCredit ? '+${tx.amount}' : '-${tx.amount}';

        buffer.writeln(
          '${tx.id},'
          '${_dateTimeFormat.format(tx.createdAt)},'
          '$type,'
          '$category,'
          '$description,'
          '$amount,'
          '${tx.status ?? "complété"}',
        );
      }

      // Calculate totals
      double totalCredits = 0;
      double totalDebits = 0;
      for (final tx in transactions) {
        if (tx.isCredit) {
          totalCredits += tx.amount;
        } else {
          totalDebits += tx.amount;
        }
      }

      buffer.writeln('');
      buffer.writeln('RÉSUMÉ');
      buffer.writeln(
        'Total crédits,${_currencyFormat.format(totalCredits)} FCFA',
      );
      buffer.writeln(
        'Total débits,${_currencyFormat.format(totalDebits)} FCFA',
      );
      buffer.writeln(
        'Solde net,${_currencyFormat.format(totalCredits - totalDebits)} FCFA',
      );

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/transactions_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      if (kDebugMode) debugPrint('📄 CSV exporté: ${file.path}');

      return file.path;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur export CSV: $e');
      return null;
    }
  }

  /// Génère un relevé de revenus en texte formaté (pour partage)
  String generateEarningsReport({
    required List<Delivery> deliveries,
    required String courierName,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('       RELEVÉ DE REVENUS - DR-PHARMA');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('Livreur: $courierName');
    buffer.writeln(
      'Date génération: ${_dateTimeFormat.format(DateTime.now())}',
    );

    if (dateFrom != null || dateTo != null) {
      buffer.writeln(
        'Période: ${dateFrom != null ? _dateFormat.format(dateFrom) : "Début"} - ${dateTo != null ? _dateFormat.format(dateTo) : "Aujourd'hui"}',
      );
    }
    buffer.writeln('');

    // Statistics
    int delivered = 0;
    int cancelled = 0;
    double totalEarnings = 0;
    double totalCommissions = 0;

    for (final delivery in deliveries) {
      if (delivery.status == 'delivered') {
        delivered++;
        totalEarnings += delivery.deliveryFee ?? 0;
        totalCommissions += delivery.commission ?? 0;
      } else if (delivery.status == 'cancelled') {
        cancelled++;
      }
    }

    buffer.writeln('─────────────────────────────────────');
    buffer.writeln('              STATISTIQUES');
    buffer.writeln('─────────────────────────────────────');
    buffer.writeln('Livraisons effectuées : $delivered');
    buffer.writeln('Livraisons annulées   : $cancelled');
    buffer.writeln(
      'Taux de succès        : ${deliveries.isNotEmpty ? ((delivered / deliveries.length) * 100).toStringAsFixed(1) : 0}%',
    );
    buffer.writeln('');

    buffer.writeln('─────────────────────────────────────');
    buffer.writeln('                REVENUS');
    buffer.writeln('─────────────────────────────────────');
    buffer.writeln(
      'Gains bruts           : ${_currencyFormat.format(totalEarnings)} FCFA',
    );
    buffer.writeln(
      'Commissions DR-PHARMA : ${_currencyFormat.format(totalCommissions)} FCFA',
    );
    buffer.writeln(
      'Net à percevoir       : ${_currencyFormat.format(totalEarnings - totalCommissions)} FCFA',
    );
    buffer.writeln('');

    // Delivery list
    if (deliveries.isNotEmpty) {
      buffer.writeln('─────────────────────────────────────');
      buffer.writeln('           DÉTAIL LIVRAISONS');
      buffer.writeln('─────────────────────────────────────');

      for (final delivery
          in deliveries.where((d) => d.status == 'delivered').take(20)) {
        final date = delivery.createdAt != null
            ? DateTime.tryParse(delivery.createdAt!)
            : null;
        buffer.writeln(
          '${date != null ? _dateFormat.format(date) : "N/A"} | '
          '#${delivery.id} | '
          '${delivery.pharmacyName.length > 15 ? delivery.pharmacyName.substring(0, 15) : delivery.pharmacyName} | '
          '${_currencyFormat.format(delivery.deliveryFee ?? 0)} FCFA',
        );
      }

      if (delivered > 20) {
        buffer.writeln('... et ${delivered - 20} autres livraisons');
      }
    }

    buffer.writeln('');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('   Document généré par DR-PHARMA App');
    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }

  /// Partage le fichier exporté
  Future<void> shareFile(String filePath, {String? subject}) async {
    final file = XFile(filePath);
    await Share.shareXFiles([
      file,
    ], subject: subject ?? 'Relevé de revenus DR-PHARMA');
  }

  /// Partage le rapport texte
  Future<void> shareReport(String report, {String? subject}) async {
    await Share.share(
      report,
      subject: subject ?? 'Relevé de revenus DR-PHARMA',
    );
  }

  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'commission':
        return 'Commission';
      case 'topup':
        return 'Recharge';
      case 'withdrawal':
        return 'Retrait';
      case 'delivery':
        return 'Livraison';
      case 'bonus':
        return 'Bonus';
      default:
        return category;
    }
  }
}
