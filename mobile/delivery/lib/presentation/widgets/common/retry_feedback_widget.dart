import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';

/// Type d'erreur pour adapter le feedback visuel.
enum ErrorType {
  /// Timeout réseau — le serveur n'a pas répondu à temps.
  timeout,
  
  /// Erreur de connexion — pas de réseau ou serveur injoignable.
  network,
  
  /// Erreur serveur (5xx) — problème côté serveur.
  server,
  
  /// Rate limiting (429) — trop de requêtes.
  rateLimited,
  
  /// Erreur générique.
  generic,
}

/// Configuration du retry progressif.
class RetryConfig {
  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelaySeconds = 2,
    this.showProgressBar = true,
    this.autoRetryOnNetwork = true,
  });
  
  /// Nombre maximum de tentatives.
  final int maxRetries;
  
  /// Délai initial avant premier retry (secondes).
  final int initialDelaySeconds;
  
  /// Afficher la barre de progression pendant le délai.
  final bool showProgressBar;
  
  /// Retenter automatiquement quand le réseau revient.
  final bool autoRetryOnNetwork;
  
  /// Configuration par défaut.
  static const standard = RetryConfig();
  
  /// Configuration agressive (plus de retries, délais courts).
  static const aggressive = RetryConfig(maxRetries: 5, initialDelaySeconds: 1);
  
  /// Configuration conservatrice (moins de retries, délais longs).
  static const conservative = RetryConfig(maxRetries: 2, initialDelaySeconds: 5);
}

/// Widget de retry progressif avec feedback visuel clair.
/// 
/// Affiche :
/// - Le type d'erreur avec icône et couleur appropriés
/// - Le nombre de tentatives restantes (2/3)
/// - Une barre de progression pendant le délai de retry
/// - Des conseils contextuels selon le type d'erreur
class RetryFeedbackWidget extends StatefulWidget {
  const RetryFeedbackWidget({
    super.key,
    required this.errorType,
    required this.message,
    this.onRetry,
    this.config = RetryConfig.standard,
    this.onGiveUp,
    this.title,
    this.technicalInfo,
  });
  
  /// Type d'erreur pour adapter le visuel.
  final ErrorType errorType;
  
  /// Message d'erreur à afficher.
  final String message;
  
  /// Callback de retry. Si null, pas de bouton retry.
  final VoidCallback? onRetry;
  
  /// Appelé quand l'utilisateur abandonne après plusieurs échecs.
  final VoidCallback? onGiveUp;
  
  /// Configuration des retries.
  final RetryConfig config;
  
  /// Titre personnalisé (optionnel).
  final String? title;
  
  /// Infos techniques pour debug (mode développeur).
  final String? technicalInfo;

  @override
  State<RetryFeedbackWidget> createState() => _RetryFeedbackWidgetState();
}

class _RetryFeedbackWidgetState extends State<RetryFeedbackWidget>
    with SingleTickerProviderStateMixin {
  int _retryCount = 0;
  bool _isRetrying = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.config.initialDelaySeconds),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startRetryWithDelay() {
    if (_retryCount >= widget.config.maxRetries) return;
    
    setState(() {
      _isRetrying = true;
      // Backoff exponentiel : 2s, 4s, 8s...
      _remainingSeconds = widget.config.initialDelaySeconds * (1 << _retryCount);
    });
    
    _progressController.duration = Duration(seconds: _remainingSeconds);
    _progressController.forward(from: 0);
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _executeRetry();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _executeRetry() {
    setState(() {
      _retryCount++;
      _isRetrying = false;
    });
    widget.onRetry?.call();
  }

  void _cancelRetry() {
    _countdownTimer?.cancel();
    _progressController.stop();
    setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getErrorColors();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône avec badge de retry
            _buildIconWithBadge(colors),
            const SizedBox(height: 20),
            
            // Titre
            Text(
              widget.title ?? _getDefaultTitle(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Message d'erreur
            Text(
              widget.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Conseil contextuel
            _buildContextualTip(colors),
            const SizedBox(height: 24),
            
            // État de retry ou boutons d'action
            if (_isRetrying)
              _buildRetryingState(colors)
            else if (widget.onRetry != null)
              _buildActionButtons(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithBadge(_ErrorColors colors) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            colors.icon,
            size: 48,
            color: colors.primary,
          ),
        ),
        // Badge compteur de retry
        if (_retryCount > 0 && _retryCount < widget.config.maxRetries)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_retryCount/${widget.config.maxRetries}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContextualTip(_ErrorColors colors) {
    final tip = _getContextualTip();
    if (tip == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: context.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryingState(_ErrorColors colors) {
    return Column(
      children: [
        // Barre de progression
        if (widget.config.showProgressBar) ...[
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progressController.value,
                  backgroundColor: colors.background,
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                  minHeight: 6,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        
        // Texte de countdown
        Text(
          'Nouvelle tentative dans $_remainingSeconds s...',
          style: TextStyle(
            fontSize: 14,
            color: context.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        
        // Bouton annuler
        TextButton(
          onPressed: _cancelRetry,
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  Widget _buildActionButtons(_ErrorColors colors) {
    final canRetry = _retryCount < widget.config.maxRetries;
    
    return Column(
      children: [
        if (canRetry) ...[
          // Bouton retry principal
          FilledButton.icon(
            onPressed: _startRetryWithDelay,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(_retryCount == 0 ? 'Réessayer' : 'Réessayer encore'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          
          // Bouton retry immédiat (optionnel)
          if (_retryCount > 0)
            TextButton(
              onPressed: () {
                setState(() => _retryCount++);
                widget.onRetry?.call();
              },
              child: const Text('Retry immédiat'),
            ),
        ] else ...[
          // Tous les retries épuisés
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Toutes les tentatives échouées',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vérifiez votre connexion et réessayez plus tard.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() => _retryCount = 0);
                },
                child: const Text('Recommencer'),
              ),
              if (widget.onGiveUp != null) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: widget.onGiveUp,
                  child: const Text('Annuler'),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  _ErrorColors _getErrorColors() {
    switch (widget.errorType) {
      case ErrorType.timeout:
        return _ErrorColors(
          primary: Colors.orange,
          background: Colors.orange.withValues(alpha: 0.1),
          icon: Icons.timer_off_outlined,
        );
      case ErrorType.network:
        return _ErrorColors(
          primary: Colors.blue,
          background: Colors.blue.withValues(alpha: 0.1),
          icon: Icons.wifi_off_outlined,
        );
      case ErrorType.server:
        return _ErrorColors(
          primary: Colors.red,
          background: Colors.red.withValues(alpha: 0.1),
          icon: Icons.cloud_off_outlined,
        );
      case ErrorType.rateLimited:
        return _ErrorColors(
          primary: Colors.purple,
          background: Colors.purple.withValues(alpha: 0.1),
          icon: Icons.speed_outlined,
        );
      case ErrorType.generic:
        return _ErrorColors(
          primary: Colors.grey,
          background: Colors.grey.withValues(alpha: 0.1),
          icon: Icons.error_outline,
        );
    }
  }

  String _getDefaultTitle() {
    switch (widget.errorType) {
      case ErrorType.timeout:
        return 'Délai d\'attente dépassé';
      case ErrorType.network:
        return 'Problème de connexion';
      case ErrorType.server:
        return 'Erreur serveur';
      case ErrorType.rateLimited:
        return 'Trop de requêtes';
      case ErrorType.generic:
        return 'Une erreur est survenue';
    }
  }

  String? _getContextualTip() {
    switch (widget.errorType) {
      case ErrorType.timeout:
        return 'Le serveur met du temps à répondre. Cela peut être dû à une connexion lente ou une forte charge serveur.';
      case ErrorType.network:
        return 'Vérifiez votre connexion Wi-Fi ou données mobiles.';
      case ErrorType.server:
        return 'Nos équipes sont informées. Le problème devrait être résolu rapidement.';
      case ErrorType.rateLimited:
        return 'Patientez quelques secondes avant de réessayer.';
      case ErrorType.generic:
        return null;
    }
  }
}

class _ErrorColors {
  const _ErrorColors({
    required this.primary,
    required this.background,
    required this.icon,
  });
  
  final Color primary;
  final Color background;
  final IconData icon;
}

/// Helper pour détecter le type d'erreur depuis une exception.
ErrorType detectErrorType(Object error) {
  final errorString = error.toString().toLowerCase();
  
  if (errorString.contains('timeout') || 
      errorString.contains('timed out') ||
      errorString.contains('délai')) {
    return ErrorType.timeout;
  }
  
  if (errorString.contains('socket') ||
      errorString.contains('connection') ||
      errorString.contains('network') ||
      errorString.contains('connexion') ||
      errorString.contains('réseau')) {
    return ErrorType.network;
  }
  
  if (errorString.contains('500') ||
      errorString.contains('502') ||
      errorString.contains('503') ||
      errorString.contains('504') ||
      errorString.contains('server error') ||
      errorString.contains('internal error')) {
    return ErrorType.server;
  }
  
  if (errorString.contains('429') ||
      errorString.contains('rate limit') ||
      errorString.contains('too many')) {
    return ErrorType.rateLimited;
  }
  
  return ErrorType.generic;
}
