import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/wallet_data.dart';
import '../providers/wallet_provider.dart';

void showWalletWithdrawalThresholdSheet(BuildContext parentContext) {
  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const WithdrawalThresholdContent(),
  );
}

class WithdrawalThresholdContent extends ConsumerStatefulWidget {
  const WithdrawalThresholdContent({super.key});

  @override
  ConsumerState<WithdrawalThresholdContent> createState() =>
      _WithdrawalThresholdContentState();
}

class _WithdrawalThresholdContentState
    extends ConsumerState<WithdrawalThresholdContent> {
  double _threshold = 50000;
  bool _autoWithdraw = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  bool _hasPin = false;
  bool _hasMobileMoney = false;
  WithdrawalConfig _config = WithdrawalConfig.defaults();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await ref
          .read(walletActionsProvider.notifier)
          .getWithdrawalSettings();
      if (mounted) {
        setState(() {
          _threshold = (settings['threshold'] as num?)?.toDouble() ?? 0.0;
          _autoWithdraw = settings['auto_withdraw'] as bool? ?? false;
          _hasPin = settings['has_pin'] as bool? ?? false;
          _hasMobileMoney = settings['has_mobile_money'] as bool? ?? false;
          _config = WithdrawalConfig.fromJson(
            settings['config'] as Map<String, dynamic>? ?? {},
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger les paramètres';
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref
          .read(walletActionsProvider.notifier)
          .setWithdrawalThreshold(
            threshold: _threshold,
            autoWithdraw: _autoWithdraw,
          );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _successMessage =
              'Seuil de ${NumberFormat('#,###', 'fr_FR').format(_threshold)} FCFA enregistré';
        });

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage =
              'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  int get _sliderDivisions {
    return ((_config.maxThreshold - _config.minThreshold) / _config.step)
        .round();
  }

  List<double> get _quickValues {
    final values = <double>[];
    values.add(_config.minThreshold);
    final quarter =
        _config.minThreshold +
        (_config.maxThreshold - _config.minThreshold) * 0.25;
    final half =
        _config.minThreshold +
        (_config.maxThreshold - _config.minThreshold) * 0.5;
    final threeQuarter =
        _config.minThreshold +
        (_config.maxThreshold - _config.minThreshold) * 0.75;
    values.add((quarter / _config.step).round() * _config.step);
    values.add((half / _config.step).round() * _config.step);
    values.add((threeQuarter / _config.step).round() * _config.step);
    return values;
  }

  String _formatQuickValue(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toInt()}K';
    return val.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _errorMessage = null);
                        },
                        customBorder: const CircleBorder(),
                        child: Icon(
                          Icons.close,
                          color: Colors.red.shade400,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seuil de retrait',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Montant minimum pour retrait automatique',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 60),
              const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ),
              const SizedBox(height: 60),
            ] else ...[
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Text(
                      '${NumberFormat('#,###', 'fr_FR').format(_threshold)} FCFA',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Montant minimum de retrait',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Slider(
                value: _threshold.clamp(
                  _config.minThreshold,
                  _config.maxThreshold,
                ),
                min: _config.minThreshold,
                max: _config.maxThreshold,
                divisions: _sliderDivisions,
                label:
                    '${NumberFormat('#,###', 'fr_FR').format(_threshold)} FCFA',
                onChanged: (val) => setState(() => _threshold = val),
                activeColor: Colors.teal,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      NumberFormat(
                        '#,###',
                        'fr_FR',
                      ).format(_config.minThreshold),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###', 'fr_FR').format(_config.maxThreshold)} FCFA',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickValues.map((val) {
                  final isSelected = (_threshold - val).abs() < _config.step;
                  return TextButton(
                    onPressed: () => setState(() => _threshold = val),
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.teal.withValues(alpha: 0.1)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _formatQuickValue(val),
                      style: TextStyle(
                        color: isSelected ? Colors.teal : Colors.grey,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (!_config.autoWithdrawAllowed) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Retrait automatique',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'Désactivé par l\'administrateur',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _autoWithdraw
                        ? Colors.teal.withValues(alpha: 0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _autoWithdraw ? Colors.teal : Colors.grey.shade200,
                      width: _autoWithdraw ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.autorenew_rounded,
                        color: _autoWithdraw ? Colors.teal : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Retrait automatique',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Retirer automatiquement quand le solde dépasse le seuil',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoWithdraw,
                        onChanged: (val) => setState(() => _autoWithdraw = val),
                        activeTrackColor: Colors.teal,
                      ),
                    ],
                  ),
                ),
              ],
              if (_autoWithdraw && _config.requirePin && !_hasPin) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Configurez d\'abord un code PIN de retrait',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_autoWithdraw &&
                  _config.requireMobileMoney &&
                  !_hasMobileMoney) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Configurez d\'abord un compte Mobile Money pour le retrait automatique',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
