import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/celebration_service.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/biometric_service.dart';
import '../../domain/entities/wallet_entity.dart';
import '../providers/wallet_notifier.dart';
import '../providers/wallet_provider.dart';
import '../providers/wallet_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  TransactionCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(walletProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    ref.listen<WalletState>(walletProvider, (previous, next) {
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(walletProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(walletProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Portefeuille'), centerTitle: true),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(WalletState state) {
    if (state.status == WalletStatus.loading && state.wallet == null) {
      return const WalletSkeleton();
    }

    if (state.status == WalletStatus.error && state.wallet == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Erreur de chargement',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(walletProvider.notifier).loadAll(),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(walletProvider.notifier).loadAll(),
      child: CustomScrollView(
        slivers: [
          // Balance Card
          if (state.wallet != null)
            SliverToBoxAdapter(
              child: BalanceCard(
                wallet: state.wallet!,
                onTopUp: () => context.push(AppRoutes.walletTopUp),
                onWithdraw: () => context.push(AppRoutes.walletWithdraw),
              ),
            ),

          // Statistics
          if (state.wallet != null)
            SliverToBoxAdapter(child: _buildStatistics(state.wallet!)),

          // Category filter
          SliverToBoxAdapter(child: _buildCategoryFilter()),

          // Transactions header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Historique',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),

          // Transactions list
          if (_filteredTransactions(state.transactions).isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Aucune transaction',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final txns = _filteredTransactions(state.transactions);
                return TransactionTile(transaction: txns[index]);
              }, childCount: _filteredTransactions(state.transactions).length),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  List<WalletTransactionEntity> _filteredTransactions(
    List<WalletTransactionEntity> transactions,
  ) {
    if (_selectedCategory == null) return transactions;
    return transactions.where((t) => t.category == _selectedCategory).toList();
  }

  Widget _buildStatistics(WalletEntity wallet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(
            label: 'Commandes payées',
            value: '${wallet.statistics.ordersPaid}',
            icon: Icons.shopping_bag_outlined,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Rechargements',
            value: '${wallet.statistics.totalTopups.toInt()} F',
            icon: Icons.add_circle_outline,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _FilterChip(
            label: 'Tout',
            isSelected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          ...TransactionCategory.values.map((cat) {
            final label = switch (cat) {
              TransactionCategory.topup => 'Rechargements',
              TransactionCategory.orderPayment => 'Paiements',
              TransactionCategory.refund => 'Remboursements',
              TransactionCategory.withdrawal => 'Retraits',
            };
            return _FilterChip(
              label: label,
              isSelected: _selectedCategory == cat,
              onTap: () => setState(() => _selectedCategory = cat),
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}

/// Internal route wrappers — used from BalanceCard actions
/// ─── Top Up Page ───
class TopUpPage extends ConsumerStatefulWidget {
  const TopUpPage({super.key});

  @override
  ConsumerState<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends ConsumerState<TopUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedOperator;
  bool _isSubmitting = false;

  static const _quickAmounts = [500, 1000, 2000, 5000, 10000, 25000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharger')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick amounts
              const Text(
                'Montant rapide',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((amount) {
                  return ActionChip(
                    label: Text('$amount F'),
                    onPressed: () {
                      _amountController.text = amount.toString();
                    },
                    backgroundColor: AppColors.primarySurface,
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant (F CFA)',
                  hintText: 'Ex: 5000',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount < 100) {
                    return 'Le montant minimum est de 100 F CFA';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Operator selector
              _OperatorSelectorInline(
                selectedOperator: _selectedOperator,
                onSelected: (op) => setState(() => _selectedOperator = op),
              ),
              const SizedBox(height: 24),

              // Info message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vous serez redirigé vers la page de paiement sécurisée.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Submit
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTopUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
                      : const Text(
                          'Recharger',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTopUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un opérateur'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Initier le paiement via Jeko
    final paymentInit = await ref
        .read(walletProvider.notifier)
        .initiateTopUp(
          amount: double.parse(_amountController.text),
          paymentMethod: _selectedOperator!,
        );

    if (!mounted) return;

    if (paymentInit == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    setState(() => _isSubmitting = false);

    // Ouvrir le paiement Jeko dans un WebView intégré (sans quitter l'app)
    // Navigator.push<bool> intentionnel : _JekoPaymentWebView est un widget
    // privé qui retourne un résultat booléen — non registered dans GoRouter.
    // ignore: use_build_context_synchronously
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _JekoPaymentWebView(
          redirectUrl: paymentInit.redirectUrl,
          reference: paymentInit.reference,
          walletNotifier: ref.read(walletProvider.notifier),
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      // Déclencher la célébration
      ref.read(celebrationProvider.notifier).triggerFirstWalletTopUp();

      // Rafraîchir le wallet et retourner
      await ref.read(walletProvider.notifier).loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rechargement effectué avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } else if (result == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le paiement a échoué ou a été annulé.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// WebView intégré pour le paiement Jeko — tout se passe dans l'app
class _JekoPaymentWebView extends StatefulWidget {
  final String redirectUrl;
  final String reference;
  final WalletNotifier walletNotifier;

  const _JekoPaymentWebView({
    required this.redirectUrl,
    required this.reference,
    required this.walletNotifier,
  });

  @override
  State<_JekoPaymentWebView> createState() => _JekoPaymentWebViewState();
}

class _JekoPaymentWebViewState extends State<_JekoPaymentWebView>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isCheckingStatus = false;
  bool _completed = false;
  Timer? _pollingTimer;

  static const _successPath = '/payments/callback/success';
  static const _errorPath = '/payments/callback/error';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Polling toutes les 5 secondes — couvre le cas où Wave ouvre le callback
    // dans le navigateur externe et l'utilisateur revient dans l'app
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkPaymentStatus();
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final url = request.url;

            // Intercepter le callback succès (si le WebView reçoit la redirection)
            if (url.contains(_successPath)) {
              _completed = true;
              _pollingTimer?.cancel();
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            // Intercepter le callback erreur
            if (url.contains(_errorPath)) {
              _completed = true;
              _pollingTimer?.cancel();
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }

            // Intercepter les schémas non-web (wave://, orange://, mtn://, etc.)
            // et les déléguer au système (qui ouvrira l'app correspondante)
            final uri = Uri.tryParse(url);
            if (uri != null &&
                uri.scheme != 'http' &&
                uri.scheme != 'https' &&
                uri.scheme != 'about') {
              launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              ).catchError((_) => false);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Appelé quand l'utilisateur revient dans l'app (ex: après Wave)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_completed) {
      _checkPaymentStatus();
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_isCheckingStatus || _completed || !mounted) return;
    setState(() => _isCheckingStatus = true);
    try {
      final status = await widget.walletNotifier.checkPaymentStatus(
        widget.reference,
      );
      if (!mounted || _completed) return;
      if (status != null) {
        if (status.isSuccess) {
          _completed = true;
          _pollingTimer?.cancel();
          Navigator.of(context).pop(true);
        } else if (status.isFinal) {
          _completed = true;
          _pollingTimer?.cancel();
          Navigator.of(context).pop(false);
        }
      }
    } finally {
      if (mounted && !_completed) setState(() => _isCheckingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Annuler',
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          if (_isCheckingStatus)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

/// Dialogue d'attente de confirmation de paiement
class _PaymentWaitDialog extends StatefulWidget {
  final String reference;
  final WalletNotifier walletNotifier;

  const _PaymentWaitDialog({
    required this.reference,
    required this.walletNotifier,
  });

  @override
  State<_PaymentWaitDialog> createState() => _PaymentWaitDialogState();
}

class _PaymentWaitDialogState extends State<_PaymentWaitDialog>
    with WidgetsBindingObserver {
  bool _checking = false;
  String _statusText = 'En attente du paiement...';
  bool _isSuccess = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Démarrer le polling automatique toutes les 5 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_checking && !_isSuccess) {
        _checkStatus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quand l'utilisateur revient dans l'app après avoir payé
    if (state == AppLifecycleState.resumed && !_checking && !_isSuccess) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);

    final status = await widget.walletNotifier.checkPaymentStatus(
      widget.reference,
    );

    if (!mounted) return;

    if (status == null) {
      setState(() {
        _checking = false;
        _statusText = 'Impossible de vérifier. Réessayez.';
      });
      return;
    }

    if (status.isSuccess) {
      setState(() {
        _checking = false;
        _isSuccess = true;
        _statusText = 'Paiement confirmé !';
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
      return;
    }

    if (status.isFailed) {
      setState(() {
        _checking = false;
        _statusText = status.errorMessage ?? 'Le paiement a échoué';
      });
      return;
    }

    // Encore en cours
    setState(() {
      _checking = false;
      _statusText = 'Paiement en cours de traitement...';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechargement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSuccess)
            const Icon(Icons.check_circle, color: AppColors.success, size: 64)
          else
            const Icon(Icons.hourglass_top, color: AppColors.primary, size: 48),
          const SizedBox(height: 16),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (_checking) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        if (!_isSuccess) ...[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _checking ? null : _checkStatus,
            child: Text(_checking ? 'Vérification...' : 'J\'ai payé'),
          ),
        ],
      ],
    );
  }
}

/// ─── Withdraw Page ───
class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedOperator;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Retrait')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Available balance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: state.availableBalance < 500
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: state.availableBalance < 500
                      ? Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: state.availableBalance < 500
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Solde disponible',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${state.availableBalance.toInt()} F CFA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: state.availableBalance < 500
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),
                          if (state.availableBalance < 500)
                            const Text(
                              'Minimum requis: 500 F CFA',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                enabled: state.availableBalance >= 500,
                decoration: InputDecoration(
                  labelText: 'Montant à retirer (F CFA)',
                  hintText: 'Ex: 5000',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: state.availableBalance >= 500
                      ? 'Maximum: ${state.availableBalance.toInt()} F CFA'
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 500) {
                    return 'Le montant minimum est de 500 F CFA';
                  }
                  if (amount > state.availableBalance) {
                    return 'Solde insuffisant (disponible: ${state.availableBalance.toInt()} F)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Operator
              _OperatorSelectorInline(
                selectedOperator: _selectedOperator,
                onSelected: state.availableBalance >= 500
                    ? (op) => setState(() => _selectedOperator = op)
                    : (_) {},
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: state.availableBalance >= 500,
                decoration: InputDecoration(
                  labelText: 'Numéro de réception',
                  hintText: 'Ex: 07 07 07 07 07',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro';
                  }
                  if (value.replaceAll(RegExp(r'\s'), '').length < 8) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || state.availableBalance < 500)
                      ? null
                      : _submitWithdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
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
                      : Text(
                          state.availableBalance < 500
                              ? 'Solde insuffisant'
                              : 'Demander le retrait',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Le retrait sera envoyé directement sur votre mobile money.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textHint, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitWithdraw() async {
    // Double-check balance before submission
    final walletState = ref.read(walletProvider);
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount > walletState.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solde insuffisant (disponible: ${walletState.availableBalance.toInt()} F)',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un opérateur'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Authentification biométrique avant retrait
    final authenticated = await BiometricService.authenticateForTransaction();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentification requise pour effectuer un retrait'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(walletProvider.notifier)
        .withdraw(
          amount: double.parse(_amountController.text),
          paymentMethod: _selectedOperator!,
          phoneNumber: _phoneController.text.replaceAll(RegExp(r'\s'), ''),
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }
}

/// ─── Inline Operator Selector ───
class _OperatorSelectorInline extends StatelessWidget {
  final String? selectedOperator;
  final ValueChanged<String> onSelected;

  const _OperatorSelectorInline({
    required this.selectedOperator,
    required this.onSelected,
  });

  static const _operators = [
    ('orange', 'Orange Money', AppColors.operatorOrange),
    ('mtn', 'MTN MoMo', AppColors.operatorMtn),
    ('moov', 'Moov Money', AppColors.operatorMoov),
    ('wave', 'Wave', AppColors.operatorWave),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opérateur de paiement',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _operators.map((op) {
            final isSelected = selectedOperator == op.$1;
            return ChoiceChip(
              label: Text(op.$2),
              selected: isSelected,
              onSelected: (_) => onSelected(op.$1),
              selectedColor: op.$3.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? op.$3 : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(color: isSelected ? op.$3 : AppColors.border),
            );
          }).toList(),
        ),
      ],
    );
  }
}
