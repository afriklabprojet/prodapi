import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../services/pdf_export_service.dart';
import '../providers/wallet_provider.dart';

void showWalletExportSheet(BuildContext parentContext, WidgetRef ref) {
  String selectedFormat = 'PDF';
  String selectedPeriod = 'Ce mois';

  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.download_rounded,
                        color: AppColors.secondary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exporter le releve',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text('Telecharger vos transactions',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Format',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFormatOption('PDF', selectedFormat,
                      Icons.picture_as_pdf_rounded, Colors.red,
                      (val) => setModalState(() => selectedFormat = val)),
                  const SizedBox(width: 12),
                  _buildDisabledFormatOption(
                      'Excel', Icons.table_chart_rounded, Colors.green),
                  const SizedBox(width: 12),
                  _buildDisabledFormatOption(
                      'CSV', Icons.description_rounded, Colors.blue),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Periode',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Cette semaine',
                  'Ce mois',
                  'Ce trimestre',
                  'Cette annee',
                  'Tout'
                ].map((period) {
                  final isSelected = selectedPeriod == period;
                  return Material(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setModalState(() => selectedPeriod = period);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Text(
                          period,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _performWalletExport(
                        parentContext, ref, selectedFormat, selectedPeriod);
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text('Exporter en $selectedFormat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildFormatOption(String format, String selected, IconData icon,
    Color color, Function(String) onSelect) {
  final isSelected = format == selected;
  return Expanded(
    child: Material(
      color: isSelected
          ? color.withValues(alpha: 0.1)
          : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onSelect(format);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? color : Colors.grey.shade200, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? color : Colors.grey.shade400, size: 28),
              const SizedBox(height: 8),
              Text(format,
                  style: TextStyle(
                      color: isSelected ? color : Colors.grey.shade600,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildDisabledFormatOption(
    String format, IconData icon, Color color) {
  return Expanded(
    child: Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 28),
            const SizedBox(height: 4),
            Text(format,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Bientôt',
                  style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _performWalletExport(BuildContext parentContext, WidgetRef ref,
    String format, String period) async {
  final walletAsync = ref.read(walletProvider);

  walletAsync.whenData((wallet) async {
    try {
      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Génération du $format en cours...'),
            ],
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      if (format == 'PDF') {
        final pdfData = await PdfExportService.generateStatement(
          wallet: wallet,
          pharmacyName: ref.read(authProvider).user?.pharmacies.isNotEmpty ==
                  true
              ? (ref.read(authProvider).user!.pharmacies.firstOrNull?.name ??
                  'Ma Pharmacie')
              : 'Ma Pharmacie',
          period: period,
        );

        await PdfExportService.sharePdf(pdfData,
            'releve_drpharma_${DateTime.now().millisecondsSinceEpoch}.pdf');

        if (!parentContext.mounted) return;
        ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('PDF généré avec succès!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        if (!parentContext.mounted) return;
        ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.white),
                const SizedBox(width: 12),
                Text('Export $format bientôt disponible'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white),
              const SizedBox(width: 12),
              Text('Erreur: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  });
}
