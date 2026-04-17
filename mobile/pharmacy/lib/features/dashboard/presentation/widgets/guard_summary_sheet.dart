import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../inventory/domain/entities/product_entity.dart';
import '../../../on_call/data/models/on_call_model.dart';

/// Données agrégées pour le bilan de garde.
class GuardSummaryData {
  final OnCallModel shift;
  final Duration duration;
  final int ordersHandledCount;
  final int prescriptionsValidatedCount;
  final List<ProductEntity> criticalProducts;

  const GuardSummaryData({
    required this.shift,
    required this.duration,
    required this.ordersHandledCount,
    required this.prescriptionsValidatedCount,
    required this.criticalProducts,
  });
}

/// Feuille modale affichée automatiquement à la fin d'une garde.
class GuardSummarySheet extends ConsumerStatefulWidget {
  const GuardSummarySheet({super.key, required this.data});

  final GuardSummaryData data;

  @override
  ConsumerState<GuardSummarySheet> createState() => _GuardSummarySheetState();
}

class _GuardSummarySheetState extends ConsumerState<GuardSummarySheet> {
  bool _isExporting = false;

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '$m min';
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();
      final data = widget.data;
      final fmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
      final fmtDate = DateFormat('EEEE d MMMM yyyy', 'fr_FR');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bilan de Garde',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        fmtDate.format(data.shift.startAt),
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      _formatDuration(data.duration),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ),
                ],
              ),

              pw.Divider(color: PdfColors.grey300, height: 24),

              // Period
              pw.Row(children: [
                _pdfLabel('Début : '),
                pw.Text(fmt.format(data.shift.startAt)),
                pw.SizedBox(width: 24),
                _pdfLabel('Fin : '),
                pw.Text(fmt.format(
                    data.shift.startAt.add(data.duration))),
              ]),

              pw.SizedBox(height: 20),

              // Stats
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfStatBox(
                    '${data.ordersHandledCount}',
                    'Commandes traitées',
                    PdfColors.blue700,
                  ),
                  pw.SizedBox(width: 16),
                  _pdfStatBox(
                    '${data.prescriptionsValidatedCount}',
                    'Ordonnances validées',
                    PdfColors.purple700,
                  ),
                  pw.SizedBox(width: 16),
                  _pdfStatBox(
                    '${data.criticalProducts.length}',
                    'Alertes stock',
                    PdfColors.orange700,
                  ),
                ],
              ),

              if (data.criticalProducts.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Produits en alerte',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...data.criticalProducts.take(10).map((p) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(children: [
                        pw.Text('• ', style: const pw.TextStyle(color: PdfColors.orange700)),
                        pw.Text(p.name),
                        pw.Text(
                          '  (stock: ${p.stockQuantity})',
                          style: const pw.TextStyle(color: PdfColors.grey600),
                        ),
                      ]),
                    )),
              ],

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Text(
                'DR-PHARMA · Généré le ${fmt.format(DateTime.now())}',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/bilan_garde_${data.shift.id}.pdf');
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Bilan de garde – ${fmtDate.format(data.shift.startAt)}',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'export PDF.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _pdfLabel(String text) => pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      );

  pw.Widget _pdfStatBox(String value, String label, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F5F5F5'),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isDark = AppColors.isDark(context);
    final fmt = DateFormat('HH:mm', 'fr_FR');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
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
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.emergency_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bilan de garde',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${fmt.format(data.shift.startAt)} → ${fmt.format(data.shift.startAt.add(data.duration))}  ·  ${_formatDuration(data.duration)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _StatCard(
                    value: '${data.ordersHandledCount}',
                    label: 'Commandes',
                    icon: Icons.shopping_bag_rounded,
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    value: '${data.prescriptionsValidatedCount}',
                    label: 'Ordonnances',
                    icon: Icons.medical_services_rounded,
                    color: Colors.purple,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    value: '${data.criticalProducts.length}',
                    label: 'Alertes stock',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                    isDark: isDark,
                  ),
                ],
              ),

              // Critical products (max 3)
              if (data.criticalProducts.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      'Produits en alerte',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...data.criticalProducts.take(3).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${p.stockQuantity} u',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (data.criticalProducts.length > 3)
                  Text(
                    '+ ${data.criticalProducts.length - 3} autre${data.criticalProducts.length - 3 > 1 ? 's' : ''}…',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade500,
                    ),
                  ),
              ],

              const SizedBox(height: 28),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade300),
                      ),
                      child: Text(
                        AppLocalizations.of(context).close,
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportPdf,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.share_rounded, size: 18),
                      label: Text(
                        _isExporting ? 'Export...' : 'Exporter PDF',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withValues(alpha: isDark ? 0.2 : 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
