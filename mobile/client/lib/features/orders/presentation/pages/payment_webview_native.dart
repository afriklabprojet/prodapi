import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';

/// Native WebView implementation for iOS/Android
class NativePaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String? orderId;

  const NativePaymentWebView({
    super.key,
    required this.paymentUrl,
    this.orderId,
  });

  @override
  State<NativePaymentWebView> createState() => _NativePaymentWebViewState();
}

class _NativePaymentWebViewState extends State<NativePaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _checkForCallbackUrl(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkForCallbackUrl(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_isCallbackUrl(request.url)) {
              _handleCallbackUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isCallbackUrl(String url) {
    return url.contains('/callback/success') ||
        url.contains('/callback/error') ||
        url.contains('payment_status=success') ||
        url.contains('payment_status=error') ||
        url.contains('payment_status=failed');
  }

  void _checkForCallbackUrl(String url) {
    if (_isCallbackUrl(url)) {
      _handleCallbackUrl(url);
    }
  }

  void _handleCallbackUrl(String url) {
    final isSuccess = url.contains('/callback/success') ||
        url.contains('payment_status=success');
    Navigator.of(context).pop(isSuccess);
  }

  Future<void> _refresh() async {
    await _controller.reload();
  }

  Future<void> _showCloseConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le paiement ?'),
        content: const Text(
          'Vous n\'avez pas encore terminé votre paiement. '
          'Voulez-vous vraiment quitter ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer le paiement'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (mounted) Navigator.of(context).pop(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Paiement sécurisé',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showCloseConfirmation,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Security banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.success.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  Icons.lock,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paiement sécurisé par Jeko',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          // Bottom info bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.elevatedBackground,
              border: Border(
                top: BorderSide(color: context.borderColor),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: context.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sélectionnez votre mode de paiement et suivez les instructions',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
