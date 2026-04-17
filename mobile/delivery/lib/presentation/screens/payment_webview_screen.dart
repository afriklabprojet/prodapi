import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/repositories/jeko_payment_repository.dart';

/// Écran WebView pour le paiement JEKO entièrement in-app.
///
/// Affiche la page de paiement JEKO dans un WebView visible.
/// L'utilisateur entre son numéro, reçoit une notification mobile money,
/// confirme dans son app Wave/Orange, puis le statut est vérifié automatiquement.
///
/// Retourne :
/// - `true`  → paiement confirmé
/// - `false` → paiement échoué
/// - `null`  → utilisateur a fermé (annulation)
class PaymentWebViewScreen extends StatefulWidget {
  final String redirectUrl;
  final String reference;
  final JekoPaymentRepository repository;

  const PaymentWebViewScreen({
    super.key,
    required this.redirectUrl,
    required this.reference,
    required this.repository,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isCheckingStatus = false;
  bool _completed = false;
  bool _waitingForConfirmation = false;
  bool _timedOut = false;
  Timer? _pollingTimer;
  Timer? _timeoutTimer;

  // Timeout de 5 minutes pour le paiement
  static const _paymentTimeout = Duration(minutes: 5);

  static const _successPaths = [
    '/payments/callback/success',
    '/api/payments/callback/success',
    '/sandbox/confirm',
    'payment/success',
  ];
  static const _errorPaths = [
    '/payments/callback/error',
    '/api/payments/callback/error',
    'payment/cancel',
    'payment/failed',
  ];

  // Schémas d'apps mobile money à intercepter (ne pas ouvrir en externe)
  static const _mobileMoneySchemes = [
    'wave',
    'orange',
    'orangemoney',
    'mtn',
    'moov',
    'djamo',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Polling toutes les 5 secondes — identique à la pharmacy app
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkPaymentStatus();
    });

    // Timeout après 5 minutes
    _timeoutTimer = Timer(_paymentTimeout, _handleTimeout);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: _handleNavigation,
          onWebResourceError: (error) {
            // ERR_UNKNOWN_URL_SCHEME est normal quand on ouvre un schéma mobile money
            if (error.description.contains('ERR_UNKNOWN_URL_SCHEME') ||
                error.description.contains('net::ERR_UNKNOWN_URL_SCHEME')) {
              if (mounted) setState(() => _isLoading = false);
              return;
            }
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _handleTimeout() {
    if (_completed || !mounted) return;
    setState(() => _timedOut = true);
    _pollingTimer?.cancel();
  }

  /// Quand l'utilisateur revient de l'app mobile money
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_completed) {
      _checkPaymentStatus();
    }
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final url = request.url;
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? '';

    // Callback succès JEKO — match strict sur path (pas url complet)
    // pour éviter qu'un attaquant injecte un chemin via query/fragment.
    if (uri != null && _matchesPaymentPath(path, _successPaths)) {
      _complete(true);
      return NavigationDecision.prevent;
    }

    // Callback erreur JEKO — match strict
    if (uri != null && _matchesPaymentPath(path, _errorPaths)) {
      _complete(false);
      return NavigationDecision.prevent;
    }

    // Deep links de notre app
    if (uri != null &&
        (uri.scheme == 'drpharma-courier' || uri.scheme == 'drpharma')) {
      final p = uri.path.replaceAll(RegExp(r'^/+'), '');
      _complete(p.contains('success'));
      return NavigationDecision.prevent;
    }

    // Schémas mobile money (wave://, orange://, etc.) → lancer l'app et attendre
    if (uri != null && _mobileMoneySchemes.contains(uri.scheme.toLowerCase())) {
      _launchMobileMoneyApp(url); // Lancer Wave/Orange automatiquement
      return NavigationDecision.prevent;
    }

    // intent:// URL (Android) → intercepter et lancer l'app
    if (uri != null && uri.scheme == 'intent') {
      // Vérifier si c'est un intent mobile money
      final intentScheme = _extractSchemeFromIntent(url);
      if (intentScheme != null &&
          _mobileMoneySchemes.contains(intentScheme.toLowerCase())) {
        _launchMobileMoneyApp(url); // Lancer l'app depuis l'intent
        return NavigationDecision.prevent;
      }
      // Sinon, laisser le WebView gérer
      return NavigationDecision.navigate;
    }

    // Autres schémas non-web → essayer de lancer l'app externe
    if (uri != null &&
        uri.scheme != 'http' &&
        uri.scheme != 'https' &&
        uri.scheme != 'about' &&
        uri.scheme != 'data' &&
        uri.scheme != 'javascript') {
      _launchMobileMoneyApp(url);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  /// Extrait le schéma natif d'une URL intent://
  String? _extractSchemeFromIntent(String intentUrl) {
    try {
      final fragment = Uri.parse(intentUrl).fragment;
      for (final part in fragment.split(';')) {
        if (part.startsWith('scheme=')) {
          return part.substring(7);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Match strict sur le path de l'URL : compare soit égalité exacte,
  /// soit fin de path (pour gérer les variantes `/api/...` vs `/...`).
  /// N'utilise PAS `.contains()` sur l'URL complète pour éviter qu'un
  /// attaquant injecte un chemin de succès via query/fragment.
  bool _matchesPaymentPath(String path, List<String> candidates) {
    if (path.isEmpty) return false;
    for (final candidate in candidates) {
      if (candidate.startsWith('/')) {
        // Path absolu : égalité exacte ou suffixe après normalisation
        if (path == candidate || path.endsWith(candidate)) return true;
      } else {
        // Path relatif (ex: "payment/success") : doit terminer l'URL path
        // précédé d'un séparateur `/` pour éviter collision partielle
        if (path.endsWith('/$candidate') || path == '/$candidate') return true;
      }
    }
    return false;
  }

  /// Affiche un overlay indiquant d'attendre la confirmation mobile money
  void _showWaitingForConfirmation() {
    if (_waitingForConfirmation) return;

    setState(() => _waitingForConfirmation = true);

    // Accélérer le polling pendant l'attente
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkPaymentStatus();
    });
  }

  /// Lance l'application mobile money depuis le WebView in-app.
  Future<void> _launchMobileMoneyApp(String rawUrl) async {
    _showWaitingForConfirmation();

    try {
      Uri? launchUri = Uri.tryParse(rawUrl);

      if (rawUrl.startsWith('intent://')) {
        final scheme = _extractSchemeFromIntent(rawUrl);
        final fallbackMatch = RegExp(
          r'S\.browser_fallback_url=([^;]+)',
        ).firstMatch(rawUrl);

        if (scheme != null) {
          final nativeUrl = rawUrl
              .replaceFirst('intent://', '$scheme://')
              .replaceFirst(RegExp(r'#Intent;.*$'), '');
          launchUri = Uri.tryParse(nativeUrl);
        }

        if ((launchUri == null || !(await canLaunchUrl(launchUri))) &&
            fallbackMatch != null) {
          launchUri = Uri.tryParse(
            Uri.decodeComponent(fallbackMatch.group(1)!),
          );
        }
      }

      if (launchUri == null) {
        throw Exception('Lien de paiement invalide');
      }

      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d\'ouvrir automatiquement l\'app de paiement. Ouvrez-la manuellement pour confirmer.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching mobile money app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d\'ouvrir automatiquement Wave/Orange Money. Ouvrez l\'app manuellement pour confirmer.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_isCheckingStatus || _completed || !mounted) return;
    setState(() => _isCheckingStatus = true);
    try {
      final status = await widget.repository.checkPaymentStatus(
        widget.reference,
      );
      if (!mounted || _completed) return;
      if (status.isSuccess) {
        _complete(true);
      } else if (status.isFailed) {
        _complete(false);
      }
    } catch (_) {
      // Silencieux — on réessaiera au prochain tick
    } finally {
      if (mounted && !_completed) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  void _complete(bool success) {
    if (_completed) return;
    _completed = true;
    _pollingTimer?.cancel();
    _timeoutTimer?.cancel();
    if (mounted) Navigator.of(context).pop(success);
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
          onPressed: () => _showExitConfirmation(),
        ),
        actions: [
          if (_isCheckingStatus)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Overlay de timeout
          if (_timedOut) _buildTimeoutOverlay(),

          // Overlay d'attente de confirmation mobile money
          if (_waitingForConfirmation && !_timedOut) _buildWaitingOverlay(),
        ],
      ),
    );
  }

  /// Overlay affiché quand on attend la confirmation mobile money
  Widget _buildWaitingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6644).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  size: 48,
                  color: Color(0xFF0D6644),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Confirmez le paiement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Une notification a été envoyée sur votre téléphone.\n'
                'Ouvrez votre app Wave/Orange Money et validez le paiement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Indicateur de polling
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Vérification en cours...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Bouton pour revenir au formulaire
              TextButton(
                onPressed: () {
                  setState(() => _waitingForConfirmation = false);
                  // Remettre le polling normal
                  _pollingTimer?.cancel();
                  _pollingTimer = Timer.periodic(const Duration(seconds: 5), (
                    _,
                  ) {
                    _checkPaymentStatus();
                  });
                },
                child: Text(
                  'Modifier le numéro',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Overlay affiché après timeout (5 minutes)
  Widget _buildTimeoutOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_off_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Délai dépassé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Le paiement prend plus de temps que prévu.\n\n'
                'Si vous avez déjà validé dans Wave/Orange Money, '
                'votre solde sera mis à jour automatiquement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Bouton réessayer
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _timedOut = false);
                  _timeoutTimer?.cancel();
                  _timeoutTimer = Timer(_paymentTimeout, _handleTimeout);
                  _pollingTimer?.cancel();
                  _pollingTimer = Timer.periodic(const Duration(seconds: 3), (
                    _,
                  ) {
                    _checkPaymentStatus();
                  });
                  _checkPaymentStatus();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Revérifier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6644),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton fermer
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(
                  'Fermer',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le paiement ?'),
        content: const Text(
          'Si vous avez déjà payé, votre solde sera mis à jour automatiquement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop(null);
            },
            child: const Text('Fermer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
