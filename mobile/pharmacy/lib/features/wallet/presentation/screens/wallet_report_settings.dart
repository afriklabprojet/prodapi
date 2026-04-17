import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class AutoReportSettingsContent extends StatefulWidget {
  final String initialFrequency;
  final String initialFormat;
  final bool initialAutoSend;
  final String? nextSendLabel;
  final Future<void> Function(String frequency, String format, bool autoSend)
  onSave;

  const AutoReportSettingsContent({
    super.key,
    required this.initialFrequency,
    required this.initialFormat,
    required this.initialAutoSend,
    this.nextSendLabel,
    required this.onSave,
  });

  @override
  State<AutoReportSettingsContent> createState() =>
      _AutoReportSettingsContentState();
}

class _AutoReportSettingsContentState extends State<AutoReportSettingsContent> {
  late String _frequency;
  late String _format;
  late bool _autoSend;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialFrequency;
    _format = widget.initialFormat;
    _autoSend = widget.initialAutoSend;
  }

  String _calculateNextSendLabel() {
    if (!_autoSend) return 'Désactivé';
    if (widget.nextSendLabel != null && _frequency == widget.initialFrequency) {
      return widget.nextSendLabel!;
    }

    final now = DateTime.now();
    return switch (_frequency) {
      'Hebdomadaire' => 'Lundi prochain',
      'Mensuel' =>
        '1er ${_getMonthName(now.month == 12 ? 1 : now.month + 1)} ${now.month == 12 ? now.year + 1 : now.year}',
      'Trimestriel' =>
        '1er ${_getQuarterStartMonth(now)} ${_getQuarterYear(now)}',
      _ => '1er du mois prochain',
    };
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month - 1];
  }

  String _getQuarterStartMonth(DateTime now) {
    final currentQuarter = (now.month - 1) ~/ 3;
    final nextQuarter = (currentQuarter + 1) % 4;
    return _getMonthName(nextQuarter * 3 + 1);
  }

  int _getQuarterYear(DateTime now) {
    final currentQuarter = (now.month - 1) ~/ 3;
    return currentQuarter == 3 ? now.year + 1 : now.year;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.indigo,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relevés automatiques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Recevez vos relevés par email',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Fréquence d'envoi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Hebdomadaire', 'Mensuel', 'Trimestriel'].map((f) {
              final isSelected = _frequency == f;
              return ChoiceChip(
                label: Text(f),
                selected: isSelected,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (selected) {
                  if (selected) setState(() => _frequency = f);
                },
                selectedColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Format du document',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['PDF', 'Excel', 'CSV'].map((f) {
              final isSelected = _format == f;
              return ChoiceChip(
                label: Text(f),
                selected: isSelected,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (selected) {
                  if (selected) setState(() => _format = f);
                },
                selectedColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Envoi automatique',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Recevoir par email automatiquement',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _autoSend,
                  onChanged: (val) => setState(() => _autoSend = val),
                  activeTrackColor: Colors.indigo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _autoSend ? Colors.indigo.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _autoSend ? Icons.info_outline : Icons.block,
                  color: _autoSend ? Colors.indigo.shade700 : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prochain relevé: ${_calculateNextSendLabel()}',
                    style: TextStyle(
                      fontSize: 13,
                      color: _autoSend ? Colors.indigo.shade700 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      await widget.onSave(_frequency, _format, _autoSend);
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context).save,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
