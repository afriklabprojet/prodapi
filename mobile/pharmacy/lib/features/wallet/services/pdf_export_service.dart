import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/wallet_data.dart';

class PdfExportService {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  /// Génère un PDF de relevé de compte
  static Future<Uint8List> generateStatement({
    required WalletData wallet,
    required String pharmacyName,
    required String period,
    List<WalletTransaction>? transactions,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Filtrer les transactions selon la période
    final filteredTransactions = _filterTransactionsByPeriod(
      transactions ?? wallet.transactions,
      period,
    );

    // Calculer les totaux
    final totalCredits = filteredTransactions
        .where((t) => t.type == 'credit')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalDebits = filteredTransactions
        .where((t) => t.type == 'debit')
        .fold<double>(0, (sum, t) => sum + t.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(pharmacyName, period, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Résumé du compte
          _buildAccountSummary(wallet, totalCredits, totalDebits),
          pw.SizedBox(height: 30),

          // Tableau des transactions
          _buildTransactionsTable(filteredTransactions),
          pw.SizedBox(height: 20),

          // Totaux
          _buildTotalsSection(totalCredits, totalDebits),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String pharmacyName, String period, DateTime now) {
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
                  'Relevé de compte',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  pharmacyName,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Généré le ${DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(now)}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Période: $period',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.teal700, thickness: 2),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'DR PHARMA - Votre santé, notre priorité',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber}/${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAccountSummary(
    WalletData wallet,
    double totalCredits,
    double totalDebits,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Solde actuel', _currencyFormat.format(wallet.balance), PdfColors.teal700),
          _buildSummaryItem('Total crédits', '+${_currencyFormat.format(totalCredits)}', PdfColors.green700),
          _buildSummaryItem('Total débits', '-${_currencyFormat.format(totalDebits)}', PdfColors.red700),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionsTable(List<WalletTransaction> transactions) {
    if (transactions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Center(
          child: pw.Text(
            'Aucune transaction pour cette période',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.teal700),
          children: [
            _buildTableHeader('Date'),
            _buildTableHeader('Description'),
            _buildTableHeader('Référence'),
            _buildTableHeader('Montant'),
          ],
        ),
        // Data rows
        ...transactions.map((tx) => pw.TableRow(
          children: [
            _buildTableCell(tx.date ?? '-'),
            _buildTableCell(tx.description ?? '-'),
            _buildTableCell(tx.reference ?? '-'),
            _buildTableCellAmount(tx.amount, tx.type),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _buildTableCellAmount(double amount, String type) {
    final isCredit = type == 'credit';
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        '${isCredit ? '+' : '-'}${_currencyFormat.format(amount)}',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: isCredit ? PdfColors.green700 : PdfColors.red700,
        ),
      ),
    );
  }

  static pw.Widget _buildTotalsSection(double totalCredits, double totalDebits) {
    final netBalance = totalCredits - totalDebits;
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total crédits:', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  '+${_currencyFormat.format(totalCredits)}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.green700, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total débits:', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  '-${_currencyFormat.format(totalDebits)}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.red700, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Solde net:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  _currencyFormat.format(netBalance),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: netBalance >= 0 ? PdfColors.green700 : PdfColors.red700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static List<WalletTransaction> _filterTransactionsByPeriod(
    List<WalletTransaction> transactions,
    String period,
  ) {
    // Note: Le filtrage par période devrait être fait côté API pour de meilleures performances
    // Ici on retourne toutes les transactions car le filtrage est déjà fait par l'API
    return transactions;
  }

  /// Sauvegarde le PDF et retourne le chemin du fichier
  static Future<String> savePdf(Uint8List pdfData, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfData);
    return file.path;
  }

  /// Partage le PDF via le système de partage
  static Future<void> sharePdf(Uint8List pdfData, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfData);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Relevé de compte DR PHARMA',
      text: 'Voici votre relevé de compte DR PHARMA',
    );
  }

  /// Imprime directement le PDF
  static Future<void> printPdf(Uint8List pdfData) async {
    await Printing.layoutPdf(onLayout: (format) async => pdfData);
  }

  /// Affiche un aperçu du PDF avec options d'impression/partage
  static Future<void> previewPdf(Uint8List pdfData) async {
    await Printing.sharePdf(bytes: pdfData, filename: 'releve_drpharma.pdf');
  }
}
