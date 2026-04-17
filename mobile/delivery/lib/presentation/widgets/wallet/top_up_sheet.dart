import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/repositories/jeko_payment_repository.dart';
import '../../screens/payment_status_screen.dart';

/// Bottom sheet pour recharger le portefeuille via JEKO.
class TopUpSheet extends ConsumerStatefulWidget {
  final String? preselectedMethod;
  final VoidCallback? onSuccess;

  const TopUpSheet({super.key, this.preselectedMethod, this.onSuccess});

  @override
  ConsumerState<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<TopUpSheet> {
  final List<int> _amounts = [500, 1000, 2000, 5000, 10000];
  int? _selectedAmount;
  JekoPaymentMethod _selectedMethod = JekoPaymentMethod.wave;

  // Pour le montant personnalisé
  final TextEditingController _customAmountController = TextEditingController();
  final FocusNode _customAmountFocus = FocusNode();
  bool _isCustomAmount = false;
  String? _customAmountError;

  // Limites de montant
  static const int minAmount = 500;
  static const int maxAmount = 1000000;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedMethod != null) {
      _selectedMethod = _methodFromString(widget.preselectedMethod!);
    }
    _customAmountController.addListener(_onCustomAmountChanged);
  }

  @override
  void dispose() {
    _customAmountController.removeListener(_onCustomAmountChanged);
    _customAmountController.dispose();
    _customAmountFocus.dispose();
    super.dispose();
  }

  void _onCustomAmountChanged() {
    if (_isCustomAmount) {
      final text = _customAmountController.text;
      final amount = int.tryParse(text.replaceAll(RegExp(r'[^\d]'), ''));

      setState(() {
        if (text.isEmpty) {
          _selectedAmount = null;
          _customAmountError = null;
        } else if (amount == null) {
          _selectedAmount = null;
          _customAmountError = 'Montant invalide';
        } else if (amount < minAmount) {
          _selectedAmount = null;
          _customAmountError = 'Minimum $minAmount FCFA';
        } else if (amount > maxAmount) {
          _selectedAmount = null;
          _customAmountError =
              'Maximum ${maxAmount.formatCurrencyCompact()} FCFA';
        } else {
          _selectedAmount = amount;
          _customAmountError = null;
        }
      });
    }
  }

  void _selectPresetAmount(int amount) {
    setState(() {
      _isCustomAmount = false;
      _selectedAmount = amount;
      _customAmountController.clear();
      _customAmountError = null;
    });
    FocusScope.of(context).unfocus();
  }

  void _enableCustomAmount() {
    setState(() {
      _isCustomAmount = true;
      _selectedAmount = null;
    });
    _customAmountFocus.requestFocus();
  }

  JekoPaymentMethod _methodFromString(String value) {
    return JekoPaymentMethod.values.firstWhere(
      (m) => m.value == value || value.contains(m.value),
      orElse: () => JekoPaymentMethod.wave,
    );
  }

  bool _isSubmitting = false;

  Future<void> _openPaymentScreen() async {
    if (_selectedAmount == null || _isSubmitting) return;

    // Valider le montant personnalisé
    if (_isCustomAmount && _customAmountError != null) {
      HapticFeedback.heavyImpact();
      return;
    }

    final amount = _selectedAmount!.toDouble();
    final method = _selectedMethod;
    final messenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      // Fermer le bottom sheet puis ouvrir le flux 100% in-app
      Navigator.of(context).pop();
      await Future<void>.delayed(Duration.zero);

      final result = await rootNavigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentStatusScreen(
            amount: amount,
            method: method,
            onSuccess: widget.onSuccess,
          ),
        ),
      );

      if (result == true) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Rechargement effectué avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result == false) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Le paiement a échoué ou a été annulé.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔴 [TOP_UP] $e');
        debugPrintStack(stackTrace: stackTrace, maxFrames: 5);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Text(
            'Paiement sécurisé via JEKO',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildPaymentMethodSection(),
          const SizedBox(height: 20),
          _buildAmountSection(),
          const SizedBox(height: 24),
          _buildInfoBanner(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.add_circle_outline, color: Colors.green.shade700),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Recharger mon compte',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Moyen de paiement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: JekoPaymentMethod.values.map(_buildMethodChip).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Montant', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        // Preset amounts
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _amounts.map((amount) {
            final isSelected = !_isCustomAmount && _selectedAmount == amount;
            return ChoiceChip(
              label: Text('${amount.formatCurrencyCompact()} FCFA'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _selectPresetAmount(amount);
              },
              selectedColor: Colors.green.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.green.shade800 : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Custom amount option
        _buildCustomAmountField(),
      ],
    );
  }

  Widget _buildCustomAmountField() {
    return GestureDetector(
      onTap: _enableCustomAmount,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isCustomAmount ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isCustomAmount
                ? Colors.green.shade400
                : Colors.grey.shade200,
            width: _isCustomAmount ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit,
                  size: 18,
                  color: _isCustomAmount
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Montant personnalisé',
                  style: TextStyle(
                    fontWeight: _isCustomAmount
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _isCustomAmount
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            if (_isCustomAmount) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customAmountController,
                focusNode: _customAmountFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                decoration: InputDecoration(
                  hintText: 'Entrez le montant',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.red.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  suffixText: 'FCFA',
                  errorText: _customAmountError,
                  helperText: 'Min. $minAmount FCFA',
                  helperStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vous serez redirigé vers ${_selectedMethod.label} pour finaliser le paiement.',
              style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_selectedAmount == null || _isSubmitting)
            ? null
            : _openPaymentScreen,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Payer ${_selectedAmount != null ? _selectedAmount!.formatCurrencyCompact() : ''} FCFA',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMethodChip(JekoPaymentMethod method) {
    final isSelected = _selectedMethod == method;
    final color = _getMethodColor(method);

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getMethodIcon(method),
              color: isSelected ? color : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              method.label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
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

  IconData _getMethodIcon(JekoPaymentMethod method) {
    return switch (method) {
      JekoPaymentMethod.wave => Icons.waves,
      JekoPaymentMethod.orange => Icons.phone_android,
      JekoPaymentMethod.mtn => Icons.phone_android,
      JekoPaymentMethod.moov => Icons.phone_android,
      JekoPaymentMethod.djamo => Icons.credit_card,
    };
  }
}
