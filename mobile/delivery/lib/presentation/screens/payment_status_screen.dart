import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/cache_service.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/repositories/jeko_payment_repository.dart';
import '../../core/utils/responsive.dart';
import '../providers/wallet_provider.dart';

/// Écran de statut de paiement JEKO
/// Flux 100% natif : WebView invisible + ouverture automatique de l'app mobile money
class PaymentStatusScreen extends ConsumerStatefulWidget {
  final double amount;
  final JekoPaymentMethod method;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  /// Clé SharedPreferences pour persister la référence de paiement en cours.
  static const _pendingPaymentKey = 'pending_jeko_payment';

  const PaymentStatusScreen({
    super.key,
    required this.amount,
    required this.method,
    this.onSuccess,
    this.onCancel,
  });

  /// Supprime la référence persistée (succès, échec ou expiration).
  static Future<void> clearPendingPayment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingPaymentKey);
  }

  /// Vérifie si un paiement était en cours lors d'un précédent lancement.
  /// Retourne la référence si elle est encore valide (< 15 min), sinon null.
  static Future<Map<String, dynamic>?> getPendingPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingPaymentKey);
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = DateTime.tryParse(data['timestamp'] ?? '');
      if (timestamp == null) {
        await prefs.remove(_pendingPaymentKey);
        return null;
      }
      // Expirer après 15 minutes
      if (DateTime.now().difference(timestamp).inMinutes > 15) {
        await prefs.remove(_pendingPaymentKey);
        return null;
      }
      return data;
    } catch (_) {
      await prefs.remove(_pendingPaymentKey);
      return null;
    }
  }

  @override
  ConsumerState<PaymentStatusScreen> createState() =>
      _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // UI states
  bool _isInitiating = true;
  bool _isVerifying = false;
  bool _isWaitingExternalApp = false;
  bool _showJekoForm = false; // Phase 1 : formulaire JEKO visible
  bool _paymentSuccess = false;
  bool _paymentFailed = false;
  String? _errorMessage;
  String? _reference;
  int _retryCount = 0;
  String _stepMessage = 'Préparation du paiement...';

  // Hidden WebView
  WebViewController? _webViewController;
  Timer? _pollingTimer;
  Timer? _contentWatcherTimer; // Surveille le contenu de la WebView
  bool _externalAppLaunched = false;
  bool _isWebViewLoading = true; // Indicateur de chargement SPA

  static const int maxRetries = 3;

  // Callback paths à intercepter
  static const _successPaths = [
    '/payments/callback/success',
    '/api/payments/callback/success',
    '/sandbox/confirm',
  ];
  static const _errorPaths = [
    '/payments/callback/error',
    '/api/payments/callback/error',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _pollingTimer?.cancel();
    _contentWatcherTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint(
      '[PaymentStatus] Lifecycle: $state, ref=$_reference, success=$_paymentSuccess',
    );

    // Quand l'utilisateur revient dans l'app (de Wave/Orange Money ou autre)
    if (state == AppLifecycleState.resumed &&
        !_paymentSuccess &&
        !_paymentFailed &&
        _reference != null) {
      debugPrint('[PaymentStatus] App resumed - starting aggressive check');

      // Toujours passer en mode vérification au retour
      if (_externalAppLaunched || _showJekoForm) {
        _externalAppLaunched = false;
        setState(() {
          _isWaitingExternalApp = false;
          _showJekoForm = false;
          _isVerifying = true;
          _stepMessage = 'Vérification du paiement...';
        });
      }

      // Vérification agressive au retour (0s, 2s, 5s)
      _aggressiveStatusCheck();
    }
  }

  /// Vérifie le statut de façon agressive au retour de l'app externe
  /// 3 checks rapprochés (0s, 2s, 5s) pour capter le statut dès qu'il est disponible
  Future<void> _aggressiveStatusCheck() async {
    const delays = [Duration.zero, Duration(seconds: 2), Duration(seconds: 5)];
    for (final delay in delays) {
      if (_paymentSuccess || _paymentFailed || !mounted) return;
      if (delay > Duration.zero) await Future.delayed(delay);
      await _checkPaymentStatusOnce();
    }
    // Si toujours pas résolu, lancer le polling régulier
    if (!_paymentSuccess && !_paymentFailed && mounted) {
      _startPolling();
    }
  }

  /// Vérification unique du statut auprès du serveur
  Future<void> _checkPaymentStatusOnce() async {
    if (!mounted || _paymentSuccess || _paymentFailed || _reference == null) {
      return;
    }
    try {
      final repo = ref.read(jekoPaymentRepositoryProvider);
      final status = await repo.checkPaymentStatus(_reference!);
      debugPrint(
        '[PaymentStatus] API response: status=${status.status}, isSuccess=${status.isSuccess}, isFailed=${status.isFailed}',
      );

      if (status.isSuccess) {
        debugPrint('[PaymentStatus] ✅ Payment SUCCESS detected!');
        _onPaymentSuccess();
      } else if (status.isFailed) {
        debugPrint('[PaymentStatus] ❌ Payment FAILED: ${status.errorMessage}');
        _onPaymentFailure(status.errorMessage ?? 'Paiement échoué');
      } else {
        debugPrint('[PaymentStatus] ⏳ Payment still pending...');
      }
    } catch (e) {
      debugPrint('[PaymentStatus] ⚠️ API Error: $e');
      // Ne pas échouer silencieusement - le polling continuera
    }
  }

  Future<void> _initiatePayment() async {
    if (!mounted) return;

    setState(() {
      _isInitiating = true;
      _isVerifying = false;
      _isWaitingExternalApp = false;
      _showJekoForm = false;
      _paymentFailed = false;
      _paymentSuccess = false;
      _errorMessage = null;
      _externalAppLaunched = false;
      _stepMessage = 'Préparation du paiement...';
    });

    try {
      final repository = ref.read(jekoPaymentRepositoryProvider);

      // 1. Appeler l'API pour initier le paiement
      setState(() => _stepMessage = 'Connexion au service de paiement...');
      final response = await repository.initiateWalletTopup(
        amount: widget.amount,
        method: widget.method,
      );

      if (!mounted) return;

      _reference = response.reference;

      // Persister la référence pour pouvoir reprendre le polling
      // si Android tue l'app pendant la redirection vers l'app mobile money
      await _persistPendingPayment();

      // 2. Charger la page JEKO dans une WebView invisible
      setState(() => _stepMessage = 'Ouverture de ${widget.method.label}...');
      _loadHiddenWebView(response.redirectUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitiating = false;
        _paymentFailed = true;
        _errorMessage = ErrorHandler.cleanMessage(e);
      });
    }
  }

  void _loadHiddenWebView(String redirectUrl) {
    _isWebViewLoading = true;
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => _handleNavigation(request),
          onPageFinished: (url) {
            if (!mounted) return;
            // Phase 1 : La page JEKO a chargé → afficher le formulaire
            if (!_externalAppLaunched &&
                !_paymentSuccess &&
                !_paymentFailed &&
                !_showJekoForm) {
              setState(() {
                _isInitiating = false;
                _showJekoForm = true;
                _stepMessage = 'Entrez votre numéro de téléphone';
              });
              // Laisser le SPA s'hydrater avant de retirer le loader
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted && _showJekoForm) {
                  setState(() => _isWebViewLoading = false);
                }
              });
              // Démarrer le polling dès que le formulaire est affiché
              // (comme delivery23 qui polllait dès l'ouverture de la WebView)
              _startPolling();
              // Commencer à surveiller le contenu de la page pour détecter
              // quand JEKO affiche "notification envoyée"
              _startContentWatcher();
            }
          },
          onWebResourceError: (error) {
            debugPrint(
              'WebView error: ${error.description} (${error.errorCode})',
            );
            // Erreur sur le frame principal uniquement
            if (error.isForMainFrame == true && mounted && !_paymentSuccess) {
              _onPaymentFailure('Erreur réseau. Vérifiez votre connexion.');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(redirectUrl));
    setState(() {}); // Rebuild pour inclure la WebView stack
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final url = request.url;
    debugPrint('Hidden WebView: $url');
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? '';

    // Callback succès JEKO
    for (final successPath in _successPaths) {
      if (path == successPath || path.endsWith(successPath)) {
        _onPaymentSuccess();
        return NavigationDecision.prevent;
      }
    }

    // Callback erreur JEKO
    for (final errorPath in _errorPaths) {
      if (path == errorPath || path.endsWith(errorPath)) {
        _onPaymentFailure('Paiement annulé ou échoué');
        return NavigationDecision.prevent;
      }
    }

    // Deep links de notre propre app
    if (uri != null &&
        (uri.scheme == 'drpharma-courier' || uri.scheme == 'drpharma')) {
      final p = uri.path.replaceAll(RegExp(r'^/+'), '');
      if (p.contains('success')) {
        _onPaymentSuccess();
      } else {
        _onPaymentFailure(uri.queryParameters['reason'] ?? 'Paiement échoué');
      }
      return NavigationDecision.prevent;
    }

    // intent:// URL (Android standard pour ouvrir Wave, Orange Money, etc.)
    if (uri != null && uri.scheme == 'intent') {
      _launchIntentUrl(url);
      return NavigationDecision.prevent;
    }

    // Schémas natifs (wave://, orange://, etc.) → ouvrir l'app directement
    if (uri != null &&
        uri.scheme != 'http' &&
        uri.scheme != 'https' &&
        uri.scheme != 'about' &&
        uri.scheme != 'data') {
      _launchNativeApp(uri);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _launchNativeApp(Uri uri) async {
    try {
      _externalAppLaunched = true;
      if (mounted) {
        setState(() {
          _isInitiating = false;
          _showJekoForm = false; // Phase 2 : cacher le formulaire
          _isWaitingExternalApp = true;
          _stepMessage = 'Confirmez le paiement dans ${widget.method.label}';
        });
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Démarrer le polling dès le lancement de l'app externe
      _startPolling();
    } catch (e) {
      debugPrint('Error launching: $e');
      // Si l'app ne s'ouvre pas, revenir au formulaire
      if (mounted) {
        setState(() {
          _isWaitingExternalApp = false;
          _showJekoForm = true;
          _externalAppLaunched = false;
          _stepMessage = 'Entrez votre numéro de téléphone';
        });
      }
    }
  }

  Future<void> _launchIntentUrl(String intentUrl) async {
    try {
      final fragment = Uri.parse(intentUrl).fragment;
      String? targetScheme;
      String? fallbackUrl;

      for (final part in fragment.split(';')) {
        if (part.startsWith('scheme=')) {
          targetScheme = part.substring(7);
        } else if (part.startsWith('S.browser_fallback_url=')) {
          fallbackUrl = Uri.decodeComponent(part.substring(22));
        }
      }

      if (targetScheme != null) {
        final nativeUrl = intentUrl
            .replaceFirst('intent://', '$targetScheme://')
            .replaceFirst(RegExp(r'#Intent;.*$'), '');
        await _launchNativeApp(Uri.parse(nativeUrl));
        return;
      }

      if (fallbackUrl != null) {
        await _launchNativeApp(Uri.parse(fallbackUrl));
        return;
      }

      // Fallback: essayer de lancer l'intent URL directement
      await _launchNativeApp(Uri.parse(intentUrl));
    } catch (e) {
      debugPrint('Error handling intent: $e');
    }
  }

  void _onPaymentSuccess() {
    _pollingTimer?.cancel();
    _contentWatcherTimer?.cancel();
    if (!mounted || _paymentSuccess) return;
    PaymentStatusScreen.clearPendingPayment();

    // Invalider le cache local ET le provider Riverpod pour refresh instantané
    CacheService.instance.invalidateWallet();
    ref.invalidate(walletProvider);
    ref.invalidate(walletDataProvider);

    // Feedback haptique de succès
    HapticFeedback.heavyImpact();

    setState(() {
      _isInitiating = false;
      _isVerifying = false;
      _isWaitingExternalApp = false;
      _paymentSuccess = true;
    });

    // Appeler le callback immédiatement
    widget.onSuccess?.call();

    // Retour automatique après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _paymentSuccess) {
        context.pop(true);
      }
    });
  }

  void _onPaymentFailure(String message) {
    _pollingTimer?.cancel();
    if (!mounted || _paymentSuccess) return;
    PaymentStatusScreen.clearPendingPayment();
    setState(() {
      _isInitiating = false;
      _isVerifying = false;
      _isWaitingExternalApp = false;
      _paymentFailed = true;
      _errorMessage = message;
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    if (_paymentSuccess || _paymentFailed || !mounted) return;

    // Polling toutes les 5 secondes pendant 10 min (comme delivery23 qui marchait)
    int pollCount = 0;
    const maxPolls = 120; // 120 × 5s = 10 min
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      pollCount++;
      if (pollCount >= maxPolls) {
        timer.cancel();
        if (!_paymentSuccess && !_paymentFailed && mounted) {
          _onPaymentFailure(
            'Délai d\'attente dépassé. Vérifiez votre paiement dans l\'historique.',
          );
        }
        return;
      }
      _checkPaymentStatusOnce();
    });
  }

  /// Ouvre l'app mobile money correspondante (Wave, Orange Money, etc.)
  Future<void> _openMobileMoneyApp() async {
    Uri? appUri;

    switch (widget.method) {
      case JekoPaymentMethod.wave:
        // Wave app deep link
        appUri = Uri.parse('wave://');
        break;
      case JekoPaymentMethod.orange:
        // Orange Money deep link
        appUri = Uri.parse('orangemoney://');
        break;
      case JekoPaymentMethod.mtn:
        // MTN Money deep link
        appUri = Uri.parse('mtnmomo://');
        break;
      case JekoPaymentMethod.moov:
        // Moov Money deep link
        appUri = Uri.parse('moovmoney://');
        break;
      case JekoPaymentMethod.djamo:
        // Djamo deep link
        appUri = Uri.parse('djamo://');
        break;
    }

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: tenter d'ouvrir le Play Store / App Store
        final storeUri = _getStoreUri(widget.method);
        if (storeUri != null) {
          await launchUrl(storeUri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Impossible d\'ouvrir ${widget.method.label}'),
                action: SnackBarAction(label: 'OK', onPressed: () {}),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error opening mobile money app: $e');
    }
  }

  /// Retourne l'URI du store pour installer l'app mobile money
  Uri? _getStoreUri(JekoPaymentMethod method) {
    // Package names pour Android
    const packages = {
      JekoPaymentMethod.wave: 'com.wave.personal',
      JekoPaymentMethod.orange: 'com.orange.money.africa',
      JekoPaymentMethod.mtn: 'com.mtn.momo',
      JekoPaymentMethod.moov: 'com.moov.money',
      JekoPaymentMethod.djamo: 'app.djamo',
    };

    final packageName = packages[method];
    if (packageName == null) return null;

    // Play Store URI
    return Uri.parse('market://details?id=$packageName');
  }

  /// Surveille le contenu de la WebView pour détecter quand JEKO
  /// affiche "notification envoyée" ou "confirmez" → passer à l'UI native
  void _startContentWatcher() {
    _contentWatcherTimer?.cancel();
    if (!mounted || !_showJekoForm) return;

    // Vérifier toutes les 2 secondes
    _contentWatcherTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkWebViewContent(),
    );
  }

  /// Vérifie si la page JEKO contient des indicateurs de "notification envoyée"
  Future<void> _checkWebViewContent() async {
    if (!mounted || !_showJekoForm || _webViewController == null) {
      _contentWatcherTimer?.cancel();
      return;
    }

    try {
      // Récupérer le texte de la page
      final result = await _webViewController!.runJavaScriptReturningResult(
        'document.body ? document.body.innerText.toLowerCase() : ""',
      );

      final content = result.toString().toLowerCase();

      // Patterns indiquant que JEKO a envoyé la notification
      final notificationSentPatterns = [
        'notification',
        'envoyée',
        'confirmez le paiement',
        'ouvrez votre app',
        'validez le paiement',
        'vérification en cours',
        'en attente de confirmation',
      ];

      bool notificationSent = false;
      for (final pattern in notificationSentPatterns) {
        if (content.contains(pattern)) {
          notificationSent = true;
          break;
        }
      }

      if (notificationSent && mounted && _showJekoForm) {
        _contentWatcherTimer?.cancel();
        debugPrint('JEKO notification detected - switching to native UI');

        setState(() {
          _showJekoForm = false;
          _isWaitingExternalApp = true;
          _stepMessage = 'Confirmez le paiement dans ${widget.method.label}';
        });

        // Essayer d'ouvrir automatiquement l'app mobile money
        _openMobileMoneyApp();
      }
    } catch (e) {
      debugPrint('Error checking WebView content: $e');
    }
  }

  Future<void> _retryPayment() async {
    if (_retryCount >= maxRetries) return;
    setState(() => _retryCount++);
    await _initiatePayment();
  }

  // ── Persistance de la référence de paiement ─────────────────────────

  /// Sauvegarde la référence en cours pour pouvoir reprendre le polling
  /// si l'app est tuée par le système pendant la redirection mobile money.
  Future<void> _persistPendingPayment() async {
    if (_reference == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PaymentStatusScreen._pendingPaymentKey,
      jsonEncode({
        'reference': _reference,
        'amount': widget.amount,
        'method': widget.method.name,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          !_isInitiating &&
          !_isVerifying &&
          !_isWaitingExternalApp &&
          !_showJekoForm,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBackground,
        body: SafeArea(
          child: Stack(
            children: [
              // Phase 1 : WebView plein écran pour le formulaire JEKO
              if (_webViewController != null && _showJekoForm)
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Stack(
                        children: [
                          WebViewWidget(controller: _webViewController!),
                          // Indicateur de chargement pendant que le SPA s'initialise
                          if (_isWebViewLoading)
                            Container(
                              color: Colors.white,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Chargement du formulaire...',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // JEKO gère l'ouverture de l'app mobile money automatiquement
                  ],
                ),
              // Phase 2 : UI native (initiation, attente app, vérification, résultat)
              if (!_showJekoForm)
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildContent()),
                    _buildActions(),
                  ],
                ),
              // WebView minimale quand on est en phase 2 (pour garder la session active)
              if (_webViewController != null &&
                  !_showJekoForm &&
                  (_isWaitingExternalApp || _isVerifying))
                const Positioned(
                  left: -1,
                  top: -1,
                  width: 1,
                  height: 1,
                  child: SizedBox.shrink(),
                ),
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
          if (_paymentSuccess || _paymentFailed)
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close),
            )
          else if (_showJekoForm)
            IconButton(
              onPressed: () => _showExitConfirmation(),
              icon: const Icon(Icons.arrow_back),
            )
          else
            const SizedBox(width: 48),
          const Expanded(
            child: Text(
              'Paiement',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          _buildStatusIcon(),
          const SizedBox(height: 32),
          Text(
            widget.amount.formatCurrency(),
            style: TextStyle(
              fontSize: context.r.sp(36),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildMethodBadge(),
          const SizedBox(height: 40),
          _buildStatusMessage(),
          const SizedBox(height: 24),
          _buildProgressSteps(),
          if (_errorMessage != null && _paymentFailed) ...[
            const SizedBox(height: 24),
            _buildErrorMessage(),
          ],
          if (_reference != null) ...[
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

    if (_isWaitingExternalApp) {
      color = Colors.blue;
      icon = Icon(_getMethodIcon(widget.method), color: Colors.white, size: 50);
    } else if (_isInitiating || _isVerifying) {
      color = _isVerifying ? Colors.orange : Colors.blue;
      icon = const CircularProgressIndicator(color: Colors.white);
    } else if (_paymentSuccess) {
      color = Colors.green;
      icon = const Icon(Icons.check, color: Colors.white, size: 50);
    } else {
      color = Colors.red;
      icon = const Icon(Icons.close, color: Colors.white, size: 50);
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = (_isInitiating || _isVerifying || _isWaitingExternalApp)
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

  Widget _buildMethodBadge() {
    final color = _getMethodColor(widget.method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getMethodIcon(widget.method), color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            widget.method.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    String title;
    String subtitle;

    if (_isWaitingExternalApp) {
      title = 'En attente de confirmation';
      subtitle = _stepMessage;
    } else if (_isVerifying) {
      title = 'Vérification en cours...';
      subtitle = 'Confirmation du paiement, veuillez patienter';
    } else if (_isInitiating) {
      title = _stepMessage;
      subtitle = 'Veuillez patienter...';
    } else if (_paymentSuccess) {
      title = 'Paiement réussi !';
      subtitle = 'Votre compte a été crédité';
    } else {
      title = 'Paiement échoué';
      subtitle = _errorMessage ?? 'Une erreur est survenue';
    }

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.r.sp(24),
            fontWeight: FontWeight.bold,
            color: _paymentSuccess
                ? Colors.green
                : (_paymentFailed
                      ? Colors.red
                      : (_isWaitingExternalApp
                            ? Colors.blue
                            : context.primaryText)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: context.secondaryText),
        ),
      ],
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      {'label': 'Initié', 'done': true},
      {
        'label': 'Numéro',
        'done': !_isInitiating && !_showJekoForm,
        'verifying': _showJekoForm,
      },
      {
        'label': widget.method.label,
        'done': _paymentSuccess || _isVerifying,
        'verifying': _isWaitingExternalApp,
      },
      {'label': 'Confirmé', 'done': _paymentSuccess, 'verifying': _isVerifying},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isDone = step['done'] as bool;
        final isVerifying = step['verifying'] as bool? ?? false;
        final isLast = index == steps.length - 1;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green
                        : (isVerifying ? Colors.orange : context.dividerColor),
                    shape: BoxShape.circle,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : isVerifying
                      ? const Padding(
                          padding: EdgeInsets.all(5),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
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
            if (!isLast)
              Container(
                width: 40,
                height: 2,
                color: isDone ? Colors.green : context.dividerColor,
                margin: const EdgeInsets.only(bottom: 16),
              ),
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
              _errorMessage ?? 'Une erreur est survenue',
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
            'Réf: $_reference',
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
          if (_paymentSuccess) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSuccess?.call();
                  context.pop(true);
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
          ] else if (_isWaitingExternalApp) ...[
            // Bouton pour ouvrir manuellement l'app mobile money
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openMobileMoneyApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getMethodColor(widget.method),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(_getMethodIcon(widget.method)),
                label: Text(
                  'Ouvrir ${widget.method.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Confirmez le paiement dans l\'app ${widget.method.label}',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.secondaryText, fontSize: 13),
            ),
          ] else if (_isVerifying) ...[
            const SizedBox(
              width: double.infinity,
              height: 52,
              child: Center(
                child: Text(
                  'Vérification du paiement...',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else if (_paymentFailed) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _retryCount < maxRetries ? _retryPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Réessayer (${maxRetries - _retryCount} essais restants)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                widget.onCancel?.call();
                context.pop(false);
              },
              child: const Text('Annuler'),
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
        content: const Text('Le paiement est en cours de préparation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCancel?.call();
              this.context.pop(false);
            },
            child: const Text('Annuler', style: TextStyle(color: Colors.red)),
          ),
        ],
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
