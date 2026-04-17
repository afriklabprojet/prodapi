import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/jeko_payment_repository.dart';
import '../../../data/repositories/wallet_repository.dart';

/// Bottom sheet pour retirer des fonds du portefeuille.
class WithdrawSheet extends ConsumerStatefulWidget {
  final double maxAmount;
  final VoidCallback? onSuccess;

  const WithdrawSheet({super.key, required this.maxAmount, this.onSuccess});

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  JekoPaymentMethod _selectedMethod = JekoPaymentMethod.orange;
  bool _isLoading = false;
  String? _phoneError;
  String? _amountError;

  // Montants minimum et maximum pour le retrait
  static const int minWithdrawAmount = 500;
  static const int maxWithdrawAmount = 500000;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Détecte l'opérateur basé sur le préfixe téléphone CI
  JekoPaymentMethod? _detectOperatorFromPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 2) return null;

    final prefix = digits.substring(0, 2);
    switch (prefix) {
      case '07':
      case '08':
        return JekoPaymentMethod.orange;
      case '05':
        return JekoPaymentMethod.mtn;
      case '01':
        return JekoPaymentMethod.moov;
      default:
        return null;
    }
  }

  /// Vérifie si le téléphone correspond au mode de paiement sélectionné
  bool _isPhoneMethodMismatch() {
    final detectedMethod = _detectOperatorFromPhone(_phoneController.text);
    if (detectedMethod == null) return false;
    if (_selectedMethod == JekoPaymentMethod.wave ||
        _selectedMethod == JekoPaymentMethod.djamo) {
      return false;
    }
    return detectedMethod != _selectedMethod;
  }

  /// Valide et normalise le numéro de téléphone
  String? _validateAndNormalizePhone(String phone) {
    final sanitized = InputSanitizer.sanitizePhone(phone);

    if (sanitized.length < 10) {
      return 'Le numéro doit contenir 10 chiffres';
    }

    final result = Validators.validatePhone(sanitized);
    if (!result.isValid) {
      return result.errorMessage;
    }

    return null;
  }

  /// Valide le montant
  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le montant est requis';
    }

    final amount = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
    if (amount == null) {
      return 'Montant invalide';
    }

    if (amount < minWithdrawAmount) {
      return 'Montant minimum: $minWithdrawAmount FCFA';
    }

    if (amount > maxWithdrawAmount) {
      return 'Montant maximum: ${maxWithdrawAmount.formatCurrencyCompact()} FCFA';
    }

    if (amount > widget.maxAmount) {
      return 'Solde insuffisant (${widget.maxAmount.formatCurrencyCompact()} FCFA disponible)';
    }

    return null;
  }

  /// Affiche le dialog de confirmation avant retrait
  Future<bool> _showConfirmationDialog(int amount, String phone) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                const Text('Confirmer le retrait'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vous êtes sur le point de retirer:'),
                const SizedBox(height: 16),
                _buildConfirmRow(
                  'Montant',
                  '${amount.formatCurrencyCompact()} FCFA',
                ),
                _buildConfirmRow('Vers', _selectedMethod.label),
                _buildConfirmRow('Numéro', phone),
                const Divider(height: 24),
                _buildConfirmRow('Frais estimés', '1-2%'),
                _buildConfirmRow(
                  'Vous recevrez',
                  '~${(amount * 0.98).round().formatCurrencyCompact()} FCFA',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Les frais de transfert varient selon l\'opérateur (1-2%). Cette action est irréversible.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer le retrait'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Formate le numéro de téléphone pour l'affichage
  String _formatPhoneForDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)}';
    }
    return phone;
  }

  Future<void> _doWithdraw() async {
    final sanitizedPhone = InputSanitizer.sanitizePhone(_phoneController.text);
    final phoneError = _validateAndNormalizePhone(_phoneController.text);
    final amountError = _validateAmount(_amountController.text);

    setState(() {
      _phoneError = phoneError;
      _amountError = amountError;
    });

    if (phoneError != null || amountError != null) {
      HapticFeedback.heavyImpact();
      return;
    }

    final amount = int.parse(
      _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
    );

    final normalizedPhone = Validators.normalizePhone(sanitizedPhone);
    final displayPhone = _formatPhoneForDisplay(sanitizedPhone);
    final confirmed = await _showConfirmationDialog(amount, displayPhone);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(walletRepositoryProvider);
      await repo.requestPayout(
        amount: amount.toDouble(),
        paymentMethod: _selectedMethod.value,
        phoneNumber: normalizedPhone,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de retrait enregistrée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔴 [WITHDRAW] $e');
        debugPrintStack(stackTrace: stackTrace, maxFrames: 5);
      }
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildPaymentMethodSection(),
            const SizedBox(height: 20),
            _buildPhoneField(),
            if (_isPhoneMethodMismatch()) _buildPhoneMismatchWarning(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Retrait de fonds',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Solde disponible: ${widget.maxAmount.formatCurrencyCompact()} FCFA',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vers', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: JekoPaymentMethod.values.map(_buildMethodChip).toList(),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d+\s\-]')),
        LengthLimitingTextInputFormatter(15),
      ],
      onChanged: (_) {
        setState(() => _phoneError = null);
      },
      decoration: InputDecoration(
        hintText: 'Ex: 07 12 34 56 78',
        labelText: 'Numéro de téléphone',
        helperText: 'Orange (07/08), MTN (05), Moov (01)',
        helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        prefixIcon: const Icon(Icons.phone),
        errorText: _phoneError,
      ),
    );
  }

  Widget _buildPhoneMismatchWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: Colors.amber.shade800,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ce numéro semble être un numéro ${_detectOperatorFromPhone(_phoneController.text)?.label ?? ''}',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(7),
      ],
      onChanged: (_) {
        if (_amountError != null) {
          setState(() => _amountError = null);
        }
      },
      decoration: InputDecoration(
        hintText: 'Ex: 5000',
        labelText: 'Montant à retirer',
        helperText:
            'Min. $minWithdrawAmount FCFA - Max. ${NumberFormat("#,##0").format(maxWithdrawAmount)} FCFA',
        helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        prefixIcon: const Icon(Icons.money),
        suffixText: 'FCFA',
        errorText: _amountError,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _doWithdraw,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Confirmer le retrait'),
      ),
    );
  }

  Widget _buildMethodChip(JekoPaymentMethod method) {
    final isSelected = _selectedMethod == method;
    final color = _getMethodColor(method);
    return FilterChip(
      label: Text(method.label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedMethod = method);
      },
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Color _getMethodColor(JekoPaymentMethod method) {
    return switch (method) {
      JekoPaymentMethod.wave => Colors.blue,
      JekoPaymentMethod.orange => Colors.orange,
      JekoPaymentMethod.mtn => Colors.amber.shade700,
      JekoPaymentMethod.moov => Colors.green,
      JekoPaymentMethod.djamo => Colors.purple,
    };
  }
}
