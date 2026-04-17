import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/delivery.dart';

/// Service d'export des données de livraison
class DeliveryExportService {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
  static final _dateOnlyFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

  /// Génère un PDF de l'historique des livraisons
  static Future<Uint8List> generateHistoryPdf({
    required List<Delivery> deliveries,
    required String courierName,
    String? periodLabel,
    HistoryStats? stats,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Calcul des totaux
    final totalEarnings = deliveries.fold<double>(
      0,
      (sum, d) => sum + (d.commission ?? 0),
    );
    final totalDeliveries = deliveries.length;
    final deliveredCount = deliveries.where((d) => d.status == 'delivered').length;
    final cancelledCount = deliveries.where((d) => d.status == 'cancelled').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(courierName, periodLabel, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Résumé
          _buildSummarySection(
            totalDeliveries: totalDeliveries,
            deliveredCount: deliveredCount,
            cancelledCount: cancelledCount,
            totalEarnings: totalEarnings,
          ),
          pw.SizedBox(height: 30),

          // Tableau des livraisons
          _buildDeliveriesTable(deliveries),
          pw.SizedBox(height: 20),

          // Totaux
          _buildTotalsSection(totalEarnings, totalDeliveries),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String courierName, String? periodLabel, DateTime now) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DR PHARMA',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Historique des Livraisons',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  courierName,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  periodLabel ?? 'Toutes périodes',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Généré le ${_dateFormat.format(now)}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _buildSummarySection({
    required int totalDeliveries,
    required int deliveredCount,
    required int cancelledCount,
    required double totalEarnings,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.teal200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', totalDeliveries.toString(), PdfColors.blue700),
          _buildSummaryItem('Livrées', deliveredCount.toString(), PdfColors.green700),
          _buildSummaryItem('Annulées', cancelledCount.toString(), PdfColors.red700),
          _buildSummaryItem('Gains', _currencyFormat.format(totalEarnings), PdfColors.teal700),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildDeliveriesTable(List<Delivery> deliveries) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(6),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),  // Réf
        1: const pw.FlexColumnWidth(2),    // Pharmacie
        2: const pw.FlexColumnWidth(2),    // Adresse
        3: const pw.FixedColumnWidth(70),  // Date
        4: const pw.FixedColumnWidth(60),  // Statut
        5: const pw.FixedColumnWidth(70),  // Commission
      },
      headers: ['Réf', 'Pharmacie', 'Adresse', 'Date', 'Statut', 'Commission'],
      data: deliveries.map((d) {
        final date = d.createdAt != null 
            ? DateTime.tryParse(d.createdAt!) 
            : null;
        return [
          '#${d.id}',
          d.pharmacyName,
          d.deliveryAddress,
          date != null ? _dateOnlyFormat.format(date) : '-',
          _getStatusLabel(d.status),
          _currencyFormat.format(d.commission ?? 0),
        ];
      }).toList(),
    );
  }

  static String _getStatusLabel(String status) {
    switch (status) {
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      case 'pending': return 'En attente';
      case 'active': return 'En cours';
      default: return status;
    }
  }

  static pw.Widget _buildTotalsSection(double totalEarnings, int totalDeliveries) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Total des commissions: ${_currencyFormat.format(totalEarnings)}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Sur un total de $totalDeliveries livraison${totalDeliveries > 1 ? 's' : ''}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
  }

  /// Génère un fichier CSV de l'historique
  static Future<String> generateHistoryCsv({
    required List<Delivery> deliveries,
  }) async {
    final List<List<dynamic>> rows = [
      // En-têtes
      [
        'ID',
        'Référence',
        'Pharmacie',
        'Adresse Pharmacie',
        'Client',
        'Adresse Livraison',
        'Montant Total',
        'Frais Livraison',
        'Commission',
        'Distance (km)',
        'Statut',
        'Date',
      ],
    ];

    // Données
    for (final delivery in deliveries) {
      rows.add([
        delivery.id,
        delivery.reference,
        delivery.pharmacyName,
        delivery.pharmacyAddress,
        delivery.customerName,
        delivery.deliveryAddress,
        delivery.totalAmount,
        delivery.deliveryFee ?? 0,
        delivery.commission ?? 0,
        delivery.distanceKm ?? 0,
        _getStatusLabel(delivery.status),
        delivery.createdAt ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Sauvegarde et partage un fichier PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Historique des livraisons',
    );
  }

  /// Sauvegarde et partage un fichier CSV
  static Future<void> shareCsv(String csvContent, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Historique des livraisons',
    );
  }

  /// Sauvegarde un fichier PDF localement
  static Future<File> savePdfLocally(Uint8List pdfBytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/exports/$filename');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  /// Liste les exports sauvegardés
  static Future<List<ExportedFile>> listSavedExports() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${directory.path}/exports');
    
    if (!await exportsDir.exists()) {
      return [];
    }

    final files = await exportsDir.list().toList();
    final exports = <ExportedFile>[];

    for (final entity in files) {
      if (entity is File) {
        final stat = await entity.stat();
        exports.add(ExportedFile(
          path: entity.path,
          name: entity.path.split('/').last,
          size: stat.size,
          createdAt: stat.modified,
          type: entity.path.endsWith('.pdf') ? ExportType.pdf : ExportType.csv,
        ));
      }
    }

    exports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return exports;
  }

  /// Supprime un export
  static Future<void> deleteExport(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// Statistiques de l'historique
class HistoryStats {
  final int totalDeliveries;
  final int deliveredCount;
  final int cancelledCount;
  final double totalEarnings;
  final double averageEarnings;
  final double totalDistance;

  const HistoryStats({
    required this.totalDeliveries,
    required this.deliveredCount,
    required this.cancelledCount,
    required this.totalEarnings,
    required this.averageEarnings,
    required this.totalDistance,
  });

  factory HistoryStats.fromDeliveries(List<Delivery> deliveries) {
    final delivered = deliveries.where((d) => d.status == 'delivered').toList();
    final cancelled = deliveries.where((d) => d.status == 'cancelled').toList();
    final totalEarnings = delivered.fold<double>(0, (sum, d) => sum + (d.commission ?? 0));
    final totalDistance = deliveries.fold<double>(0, (sum, d) => sum + (d.distanceKm ?? 0));

    return HistoryStats(
      totalDeliveries: deliveries.length,
      deliveredCount: delivered.length,
      cancelledCount: cancelled.length,
      totalEarnings: totalEarnings,
      averageEarnings: deliveries.isEmpty ? 0 : totalEarnings / deliveries.length,
      totalDistance: totalDistance,
    );
  }
}

/// Fichier exporté
class ExportedFile {
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;
  final ExportType type;

  const ExportedFile({
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
    required this.type,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum ExportType { pdf, csv }

/// Provider pour le service d'export
final deliveryExportServiceProvider = Provider<DeliveryExportService>((ref) {
  return DeliveryExportService();
});

/// Provider pour les exports sauvegardés
final savedExportsProvider = FutureProvider<List<ExportedFile>>((ref) async {
  return DeliveryExportService.listSavedExports();
});
