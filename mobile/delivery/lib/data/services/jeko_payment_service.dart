import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../repositories/jeko_payment_repository.dart';

/// Provider pour le service de paiement JEKO
final jekoPaymentServiceProvider = Provider<JekoPaymentService>((ref) {
  return JekoPaymentService(ref.read(jekoPaymentRepositoryProvider));
});

/// Provider pour écouter les deep links de paiement
final paymentDeepLinkProvider = StreamProvider<PaymentDeepLink?>((ref) {
  return JekoPaymentService.deepLinkStream;
});

/// Modèle pour les deep links de paiement
class PaymentDeepLink {
  final String reference;
  final bool isSuccess;
  final String? errorMessage;

  PaymentDeepLink({
    required this.reference,
    required this.isSuccess,
    this.errorMessage,
  });
}

/// État du paiement en cours
enum PaymentFlowState {
  idle,
  initiating,
  redirecting,
  waitingForCallback,
  verifying,
  success,
  failed,
  timeout,
}

/// Classe pour gérer l'état complet d'un paiement
class PaymentFlowStatus {
  final PaymentFlowState state;
  final String? reference;
  final String? redirectUrl;
  final PaymentStatusResponse? statusResponse;
  final String? errorMessage;
  final int retryCount;

  PaymentFlowStatus({
    this.state = PaymentFlowState.idle,
    this.reference,
    this.redirectUrl,
    this.statusResponse,
    this.errorMessage,
    this.retryCount = 0,
  });

  PaymentFlowStatus copyWith({
    PaymentFlowState? state,
    String? reference,
    String? redirectUrl,
    PaymentStatusResponse? statusResponse,
    String? errorMessage,
    int? retryCount,
  }) {
    return PaymentFlowStatus(
      state: state ?? this.state,
      reference: reference ?? this.reference,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      statusResponse: statusResponse ?? this.statusResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  bool get isLoading => state == PaymentFlowState.initiating ||
      state == PaymentFlowState.redirecting ||
      state == PaymentFlowState.verifying;

  bool get isFinal => state == PaymentFlowState.success ||
      state == PaymentFlowState.failed ||
      state == PaymentFlowState.timeout;

  bool get canRetry => state == PaymentFlowState.failed ||
      state == PaymentFlowState.timeout;
}

/// Service centralisé pour gérer les paiements JEKO
class JekoPaymentService {
  final JekoPaymentRepository _repository;
  
  // Stream controller pour les deep links
  static final StreamController<PaymentDeepLink?> _deepLinkController =
      StreamController<PaymentDeepLink?>.broadcast();
  
  static Stream<PaymentDeepLink?> get deepLinkStream => _deepLinkController.stream;
  
  // Subscription pour les deep links
  static StreamSubscription? _linkSubscription;
  
  // Référence du paiement en cours (pour vérification au retour)
  static String? _pendingPaymentReference;
  
  // Configuration
  static const int maxRetries = 3;
  static const Duration pollingInterval = Duration(seconds: 5);
  static const Duration maxWaitTime = Duration(minutes: 5);
  
  // Deep link scheme
  static const String deepLinkScheme = 'drpharma-courier';
  static const String deepLinkHost = 'payment';

  JekoPaymentService(this._repository);

  /// Nettoyer les messages d'erreur pour l'affichage utilisateur
  String _cleanErrorMessage(dynamic error) {
    String message = error.toString();
    
    // Supprimer les préfixes "Exception:" répétés
    while (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    
    // Messages d'erreur user-friendly
    if (message.contains('connexion') || message.contains('SocketException') || message.contains('XMLHttpRequest')) {
      return 'Impossible de contacter le serveur. Vérifiez votre connexion internet.';
    }
    
    if (message.contains('timeout') || message.contains('Timeout')) {
      return 'La connexion a pris trop de temps. Veuillez réessayer.';
    }
    
    if (message.contains('JEKO') || message.contains('paiement')) {
      // Garder le message JEKO mais le rendre plus lisible
      return message.replaceAll('Erreur lors de la création du paiement JEKO', 
          'Impossible d\'initier le paiement. Veuillez réessayer.');
    }
    
    return message.isNotEmpty ? message : 'Une erreur est survenue. Veuillez réessayer.';
  }

  /// Initialiser l'écoute des deep links (appeler dans main.dart)
  static Future<void> initDeepLinks() async {
    final appLinks = AppLinks();

    // Écouter les deep links entrants (inclut le lien initial)
    _linkSubscription?.cancel();
    _linkSubscription = appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri.toString());
      },
      onError: (err) {
        if (kDebugMode) debugPrint('Deep link error: $err');
      },
    );
  }

  /// Traiter un deep link entrant
  static void _handleDeepLink(String link) {
    if (kDebugMode) debugPrint('Received deep link: $link');
    
    try {
      final uri = Uri.parse(link);
      
      // Vérifier que c'est notre scheme
      if (uri.scheme != deepLinkScheme) return;
      
      // Extraire les paramètres
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isEmpty) return;
      
      final action = pathSegments[0]; // "success" ou "error"
      final reference = uri.queryParameters['reference'] ?? _pendingPaymentReference;
      
      if (reference == null) {
        if (kDebugMode) debugPrint('No reference found in deep link');
        return;
      }
      
      final deepLink = PaymentDeepLink(
        reference: reference,
        isSuccess: action == 'success',
        errorMessage: action == 'error' ? uri.queryParameters['message'] : null,
      );
      
      _deepLinkController.add(deepLink);
      
    } catch (e) {
      if (kDebugMode) debugPrint('Error parsing deep link: $e');
    }
  }

  /// Construire les URLs de callback pour JEKO
  static String get successUrl => '$deepLinkScheme://$deepLinkHost/success';
  static String get errorUrl => '$deepLinkScheme://$deepLinkHost/error';

  /// Initier un rechargement de wallet
  Future<PaymentFlowStatus> initiateWalletTopup({
    required double amount,
    required JekoPaymentMethod method,
    required Function(PaymentFlowStatus) onStatusChange,
  }) async {
    var status = PaymentFlowStatus(state: PaymentFlowState.initiating);
    onStatusChange(status);

    try {
      // 1. Appeler le backend pour initier le paiement
      final response = await _repository.initiateWalletTopup(
        amount: amount,
        method: method,
      );

      _pendingPaymentReference = response.reference;

      status = status.copyWith(
        state: PaymentFlowState.redirecting,
        reference: response.reference,
        redirectUrl: response.redirectUrl,
      );
      onStatusChange(status);

      // 2. Rediriger vers l'URL de paiement (JEKO ou sandbox)
      final uri = Uri.parse(response.redirectUrl);
      
      // Mode sandbox: l'URL contient /sandbox/confirm
      final isSandbox = response.redirectUrl.contains('/sandbox/');
      
      if (kDebugMode) debugPrint('Payment redirect URL: ${response.redirectUrl}');
      if (kDebugMode) debugPrint('Is sandbox mode: $isSandbox');

      try {
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          // Toujours afficher dans l'app pour voir le QR code
          await launchUrl(
            uri, 
            mode: LaunchMode.inAppWebView,
          );
        } else {
          // Fallback: essayer avec inAppWebView
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        }
      } catch (launchError) {
        if (kDebugMode) debugPrint('Error launching URL: $launchError');
        // Continuer quand même au polling - l'utilisateur peut avoir confirmé manuellement
      }

      // 3. Attendre le callback ou timeout
      status = status.copyWith(state: PaymentFlowState.waitingForCallback);
      onStatusChange(status);

      // 4. Démarrer le polling en arrière-plan
      return await _pollPaymentStatus(
        reference: response.reference,
        onStatusChange: onStatusChange,
        initialStatus: status,
      );

    } catch (e) {
      status = status.copyWith(
        state: PaymentFlowState.failed,
        errorMessage: _cleanErrorMessage(e),
      );
      onStatusChange(status);
      return status;
    }
  }

  /// Polling du statut de paiement avec retry
  Future<PaymentFlowStatus> _pollPaymentStatus({
    required String reference,
    required Function(PaymentFlowStatus) onStatusChange,
    required PaymentFlowStatus initialStatus,
  }) async {
    var status = initialStatus;
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      // Attendre avant de vérifier
      await Future.delayed(pollingInterval);

      try {
        status = status.copyWith(state: PaymentFlowState.verifying);
        onStatusChange(status);

        final statusResponse = await _repository.checkPaymentStatus(reference);

        status = status.copyWith(statusResponse: statusResponse);

        if (statusResponse.isSuccess) {
          status = status.copyWith(state: PaymentFlowState.success);
          onStatusChange(status);
          _pendingPaymentReference = null;
          return status;
        }

        if (statusResponse.isFailed) {
          status = status.copyWith(
            state: PaymentFlowState.failed,
            errorMessage: statusResponse.errorMessage ?? 'Paiement échoué',
          );
          onStatusChange(status);
          _pendingPaymentReference = null;
          return status;
        }

        // Toujours en attente, continuer le polling
        status = status.copyWith(state: PaymentFlowState.waitingForCallback);
        onStatusChange(status);

      } catch (e) {
        if (kDebugMode) debugPrint('Error polling payment status: $e');
        // Continuer le polling même en cas d'erreur réseau
      }
    }

    // Timeout atteint
    status = status.copyWith(
      state: PaymentFlowState.timeout,
      errorMessage: 'Délai d\'attente dépassé. Veuillez vérifier votre paiement.',
    );
    onStatusChange(status);
    _pendingPaymentReference = null;
    return status;
  }

  /// Vérifier manuellement le statut d'un paiement
  Future<PaymentStatusResponse> checkStatus(String reference) async {
    return await _repository.checkPaymentStatus(reference);
  }

  /// Réessayer un paiement échoué
  Future<PaymentFlowStatus> retryPayment({
    required double amount,
    required JekoPaymentMethod method,
    required Function(PaymentFlowStatus) onStatusChange,
    int currentRetry = 0,
  }) async {
    if (currentRetry >= maxRetries) {
      return PaymentFlowStatus(
        state: PaymentFlowState.failed,
        errorMessage: 'Nombre maximum de tentatives atteint',
        retryCount: currentRetry,
      );
    }

    return await initiateWalletTopup(
      amount: amount,
      method: method,
      onStatusChange: (status) {
        onStatusChange(status.copyWith(retryCount: currentRetry + 1));
      },
    );
  }

  /// Nettoyer les resources
  static void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}
