import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/repositories/jeko_payment_repository.dart';

/// Dialog affichant le statut d'un paiement en cours.
/// Effectue un polling automatique jusqu'à ce que le paiement soit finalisé.
class PaymentStatusDialog extends ConsumerStatefulWidget {
  final String reference;
  final double amount;
  final Function(bool success)? onComplete;

  const PaymentStatusDialog({
    super.key,
    required this.reference,
    required this.amount,
    this.onComplete,
  });

  @override
  ConsumerState<PaymentStatusDialog> createState() =>
      _PaymentStatusDialogState();
}

class _PaymentStatusDialogState extends ConsumerState<PaymentStatusDialog> {
  PaymentStatusResponse? _status;
  bool _isChecking = false;
  int _checkCount = 0;
  static const int _maxChecks = 60; // 5 minutes max (5 sec interval)

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  Future<void> _startPolling() async {
    while (mounted && _checkCount < _maxChecks) {
      await _checkStatus();

      if (_status?.isFinal == true) {
        break;
      }

      await Future.delayed(const Duration(seconds: 5));
      _checkCount++;
    }
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;

    if (!mounted) return;
    setState(() => _isChecking = true);

    try {
      final jekoRepo = ref.read(jekoPaymentRepositoryProvider);
      final status = await jekoRepo.checkPaymentStatus(widget.reference);

      if (!mounted) return;
      setState(() => _status = status);

      if (status.isFinal) {
        widget.onComplete?.call(status.isSuccess);
      }
    } catch (e) {
      // Ignore errors, continue polling
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_status == null || _status!.isPending)
            _buildPendingState()
          else if (_status!.isSuccess)
            _buildSuccessState()
          else if (_status!.isFailed)
            _buildFailedState(),
        ],
      ),
    );
  }

  Widget _buildPendingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        const Text(
          'Paiement en cours...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.amount.formatCurrencyCompact()} FCFA',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Veuillez terminer le paiement dans votre application mobile.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _isChecking ? null : _checkStatus,
          child: const Text('Vérifier le statut'),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Paiement réussi !',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '+${widget.amount.formatCurrencyCompact()} FCFA',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continuer'),
          ),
        ),
      ],
    );
  }

  Widget _buildFailedState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Paiement échoué',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _status!.errorMessage ?? 'Une erreur est survenue',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Fermer'),
          ),
        ),
      ],
    );
  }
}
