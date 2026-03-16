import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/error_handler.dart';
import '../../data/repositories/jeko_payment_repository.dart';
import '../../data/services/jeko_payment_service.dart';
import '../../core/utils/responsive.dart';

/// Écran de statut de paiement JEKO
/// Affiche l'état du paiement avec UX claire et retry
class PaymentStatusScreen extends ConsumerStatefulWidget {
  final double amount;
  final JekoPaymentMethod method;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const PaymentStatusScreen({
    super.key,
    required this.amount,
    required this.method,
    this.onSuccess,
    this.onCancel,
  });

  @override
  ConsumerState<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  PaymentFlowStatus _status = PaymentFlowStatus();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Démarrer le paiement
    _initiatePayment();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (_isDisposed) return;
    
    final service = ref.read(jekoPaymentServiceProvider);
    
    await service.initiateWalletTopup(
      amount: widget.amount,
      method: widget.method,
      onStatusChange: (status) {
        if (!_isDisposed && mounted) {
          setState(() => _status = status);
        }
      },
    );
  }

  Future<void> _retryPayment() async {
    if (_isDisposed) return;
    
    final service = ref.read(jekoPaymentServiceProvider);
    
    await service.retryPayment(
      amount: widget.amount,
      method: widget.method,
      currentRetry: _status.retryCount,
      onStatusChange: (status) {
        if (!_isDisposed && mounted) {
          setState(() => _status = status);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _status.isFinal || _status.state == PaymentFlowState.idle,
      onPopInvokedWithResult: (didPop, result) {
        // Empêcher le retour pendant le paiement en cours
        if (!didPop && (_status.isLoading || _status.state == PaymentFlowState.waitingForCallback)) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: _buildContent(),
              ),
              
              // Actions
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_status.isFinal || _status.state == PaymentFlowState.idle)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            )
          else
            const SizedBox(width: 48),
          const Expanded(
            child: Text(
              'Paiement',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Status Icon with Animation
          _buildStatusIcon(),
          
          const SizedBox(height: 32),
          
          // Amount
          Text(
            '${NumberFormat("#,##0", "fr_FR").format(widget.amount)} FCFA',
            style: TextStyle(
              fontSize: context.r.sp(36),
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Payment Method
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getMethodColor(widget.method).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getMethodIcon(widget.method),
                  color: _getMethodColor(widget.method),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.method.label,
                  style: TextStyle(
                    color: _getMethodColor(widget.method),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Status Message
          _buildStatusMessage(),
          
          const SizedBox(height: 24),
          
          // Progress Steps
          _buildProgressSteps(),
          
          // Error Message
          if (_status.errorMessage != null && _status.isFinal) ...[
            const SizedBox(height: 24),
            _buildErrorMessage(),
          ],
          
          // Reference
          if (_status.reference != null) ...[
            const SizedBox(height: 24),
            _buildReference(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    Widget icon;
    Color color;

    switch (_status.state) {
      case PaymentFlowState.idle:
      case PaymentFlowState.initiating:
        color = Colors.blue;
        icon = const CircularProgressIndicator(color: Colors.white);
        break;
      case PaymentFlowState.redirecting:
      case PaymentFlowState.waitingForCallback:
        color = Colors.orange;
        icon = const Icon(Icons.phone_android, color: Colors.white, size: 40);
        break;
      case PaymentFlowState.verifying:
        color = Colors.blue;
        icon = const CircularProgressIndicator(color: Colors.white, strokeWidth: 3);
        break;
      case PaymentFlowState.success:
        color = Colors.green;
        icon = const Icon(Icons.check, color: Colors.white, size: 50);
        break;
      case PaymentFlowState.failed:
      case PaymentFlowState.timeout:
        color = Colors.red;
        icon = const Icon(Icons.close, color: Colors.white, size: 50);
        break;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = _status.isLoading || 
            _status.state == PaymentFlowState.waitingForCallback
            ? _pulseAnimation.value
            : 1.0;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(child: icon),
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage() {
    String title;
    String subtitle;

    switch (_status.state) {
      case PaymentFlowState.idle:
        title = 'Préparation...';
        subtitle = 'Initialisation du paiement';
        break;
      case PaymentFlowState.initiating:
        title = 'Connexion...';
        subtitle = 'Création de la demande de paiement';
        break;
      case PaymentFlowState.redirecting:
        title = 'Redirection...';
        subtitle = 'Ouverture de ${widget.method.label}';
        break;
      case PaymentFlowState.waitingForCallback:
        title = 'En attente...';
        subtitle = 'Terminez le paiement dans votre application';
        break;
      case PaymentFlowState.verifying:
        title = 'Vérification...';
        subtitle = 'Confirmation du paiement en cours';
        break;
      case PaymentFlowState.success:
        title = 'Paiement réussi !';
        subtitle = 'Votre compte a été crédité';
        break;
      case PaymentFlowState.failed:
        title = 'Paiement échoué';
        subtitle = _status.errorMessage != null 
            ? ErrorHandler.cleanMessage(_status.errorMessage!) 
            : 'Une erreur est survenue';
        break;
      case PaymentFlowState.timeout:
        title = 'Délai dépassé';
        subtitle = 'Le paiement n\'a pas été confirmé à temps';
        break;
    }

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.r.sp(24),
            fontWeight: FontWeight.bold,
            color: _status.state == PaymentFlowState.success
                ? Colors.green
                : _status.isFinal
                    ? Colors.red
                    : context.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: context.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      {'label': 'Initié', 'done': _status.state != PaymentFlowState.idle},
      {'label': 'Redirection', 'done': _status.state.index >= PaymentFlowState.waitingForCallback.index},
      {'label': 'Paiement', 'done': _status.state.index >= PaymentFlowState.verifying.index},
      {'label': 'Confirmé', 'done': _status.state == PaymentFlowState.success},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isDone = step['done'] as bool;
        final isLast = index == steps.length - 1;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green : context.dividerColor,
                    shape: BoxShape.circle,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  step['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDone ? Colors.green : Colors.grey,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (!isLast) ...[
              Container(
                width: 40,
                height: 2,
                color: isDone ? Colors.green : context.dividerColor,
                margin: const EdgeInsets.only(bottom: 16),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _status.errorMessage != null 
                  ? ErrorHandler.cleanMessage(_status.errorMessage!)
                  : 'Une erreur est survenue',
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReference() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 16, color: context.secondaryText),
          const SizedBox(width: 8),
          Text(
            'Réf: ${_status.reference}',
            style: TextStyle(
              color: context.secondaryText,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_status.state == PaymentFlowState.success) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSuccess?.call();
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ] else if (_status.canRetry) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _status.retryCount < JekoPaymentService.maxRetries
                    ? _retryPayment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Réessayer (${JekoPaymentService.maxRetries - _status.retryCount} essais restants)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                widget.onCancel?.call();
                Navigator.pop(context, false);
              },
              child: const Text('Annuler'),
            ),
          ] else if (_status.state == PaymentFlowState.waitingForCallback) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Revenez ici une fois le paiement terminé dans ${widget.method.label}',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _showExitConfirmation(),
              icon: const Icon(Icons.close),
              label: const Text('Annuler le paiement'),
            ),
          ],
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le paiement ?'),
        content: const Text(
          'Le paiement est en cours. Si vous annulez maintenant, '
          'vous devrez recommencer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _cancelPayment();
            },
            child: const Text('Annuler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelPayment() async {
    if (_status.reference == null) {
      widget.onCancel?.call();
      Navigator.pop(context, false);
      return;
    }

    try {
      final repository = ref.read(jekoPaymentRepositoryProvider);
      await repository.cancelPayment(_status.reference!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement annulé'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onCancel?.call();
        Navigator.pop(context, false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.cleanMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
        // Fermer quand même l'écran
        widget.onCancel?.call();
        Navigator.pop(context, false);
      }
    }
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
