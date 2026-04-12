import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_logger.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final String? paymentReference;

  const PaymentWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.orderId,
    this.paymentReference,
  });

  /// Shows the payment webview and returns:
  /// - true  = payment confirmed
  /// - false = payment failed
  /// - null  = user closed (will trigger status check)
  static Future<bool?> show(
    BuildContext context, {
    required String paymentUrl,
    required String orderId,
    String? paymentReference,
  }) async {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentWebViewPage(
          paymentUrl: paymentUrl,
          orderId: orderId,
          paymentReference: paymentReference,
        ),
      ),
    );
  }

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  bool _hasNavigatedAway = false;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWebView();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Détecte quand l'app revient au premier plan (après switch app/paiement mobile money)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed &&
        _hasNavigatedAway &&
        !_paymentCompleted) {
      // L'utilisateur revient dans l'app après avoir été ailleurs
      // Cela peut indiquer un paiement effectué dans l'app mobile money
      AppLogger.info(
        '[PaymentWebView] App resumed - user may have completed payment externally',
      );
      _hasNavigatedAway = false;
      // Recharger la page pour vérifier le statut
      _controller.reload();
    } else if (state == AppLifecycleState.paused) {
      _hasNavigatedAway = true;
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            AppLogger.debug('[PaymentWebView] Loading: $url');
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkPaymentResult(url);
          },
          onWebResourceError: (error) {
            AppLogger.error('[PaymentWebView] Error: ${error.description}');
            // ERR_UNKNOWN_URL_SCHEME is expected when we open a custom scheme
            // externally (mobile money app). Don't show an error to the user.
            if (error.description.contains('ERR_UNKNOWN_URL_SCHEME') ||
                error.description.contains('net::ERR_UNKNOWN_URL_SCHEME')) {
              setState(() => _isLoading = false);
              return;
            }
            setState(() {
              _isLoading = false;
              _error = error.description;
            });
          },
          onNavigationRequest: (request) {
            final url = request.url;
            AppLogger.debug('[PaymentWebView] Navigation request: $url');

            // Check for callback URLs
            if (url.contains('payment/success') ||
                url.contains('payment/callback')) {
              _paymentCompleted = true;
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            if (url.contains('payment/cancel') ||
                url.contains('payment/failed')) {
              _paymentCompleted = true;
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }

            // Intercept non-http(s) schemes — open with the OS (mobile money apps,
            // intent://, tel://, market://, etc.) to avoid ERR_UNKNOWN_URL_SCHEME.
            final uri = Uri.tryParse(url);
            if (uri != null && uri.scheme != 'http' && uri.scheme != 'https') {
              AppLogger.info(
                '[PaymentWebView] Custom scheme detected: ${uri.scheme} — launching externally',
              );
              _hasNavigatedAway = true;
              launchUrl(uri, mode: LaunchMode.externalApplication).catchError((
                e,
              ) {
                AppLogger.warning('[PaymentWebView] Could not launch $url: $e');
                return false;
              });
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentResult(String url) {
    if (url.contains('payment/success') || url.contains('status=success')) {
      _paymentCompleted = true;
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(true);
    } else if (url.contains('payment/failed') ||
        url.contains('status=failed')) {
      _paymentCompleted = true;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(false);
    }
  }

  /// Affiche une confirmation avant de fermer pendant un paiement en cours
  Future<bool> _onWillPop() async {
    if (_paymentCompleted) return true;

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le paiement ?'),
        content: const Text(
          'Si vous avez déjà effectué le paiement, '
          'il sera automatiquement détecté.\n\n'
          'Voulez-vous vraiment quitter ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer le paiement'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    return shouldClose ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(
            null,
          ); // null = fermeture manuelle, déclenche vérification statut
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Paiement #${widget.orderId}'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldClose = await _onWillPop();
              if (shouldClose && context.mounted) {
                Navigator.of(context).pop(null);
              }
            },
          ),
          actions: [
            // Bouton refresh manuel
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
              tooltip: 'Actualiser',
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _error = null);
                          _controller.loadRequest(Uri.parse(widget.paymentUrl));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Vérifier le statut du paiement'),
                      ),
                    ],
                  ),
                ),
              )
            else
              WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement du paiement...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
