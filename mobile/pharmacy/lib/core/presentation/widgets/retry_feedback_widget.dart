import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/haptic_service.dart';

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
  static const conservative =
      RetryConfig(maxRetries: 2, initialDelaySeconds: 5);
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

    HapticService.onAction();

    setState(() {
      _isRetrying = true;
      // Backoff exponentiel : 2s, 4s, 8s...
      _remainingSeconds =
          widget.config.initialDelaySeconds * (1 << _retryCount);
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

  void _giveUp() {
    HapticService.onError();
    widget.onGiveUp?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getErrorColors(context);
    final isDark = AppColors.isDark(context);

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
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message d'erreur
            Text(
              widget.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: colors.primary,
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
        if (widget.config.showProgressBar)
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressController.value,
                      backgroundColor: colors.background,
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

        // Texte de compte à rebours
        Text(
          'Nouvelle tentative dans $_remainingSeconds s...',
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Bouton annuler
        TextButton.icon(
          onPressed: _cancelRetry,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Annuler'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(_ErrorColors colors) {
    final hasRetriesLeft = _retryCount < widget.config.maxRetries;

    return Column(
      children: [
        if (hasRetriesLeft)
          ElevatedButton.icon(
            onPressed: _startRetryWithDelay,
            icon: const Icon(Icons.refresh),
            label: Text(_retryCount == 0 ? 'Réessayer' : 'Réessayer encore'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          Column(
            children: [
              Icon(
                Icons.sentiment_dissatisfied,
                size: 32,
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              Text(
                'Toutes les tentatives ont échoué',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.onGiveUp != null)
                OutlinedButton(
                  onPressed: _giveUp,
                  child: const Text('Retour'),
                ),
            ],
          ),
      ],
    );
  }

  _ErrorColors _getErrorColors(BuildContext context) {
    final isDark = AppColors.isDark(context);
    switch (widget.errorType) {
      case ErrorType.timeout:
        return _ErrorColors(
          primary: Colors.orange,
          background:
              isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50,
          icon: Icons.timer_off_outlined,
        );
      case ErrorType.network:
        return _ErrorColors(
          primary: Colors.blue,
          background: isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50,
          icon: Icons.wifi_off_rounded,
        );
      case ErrorType.server:
        return _ErrorColors(
          primary: Colors.red,
          background: isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50,
          icon: Icons.cloud_off_rounded,
        );
      case ErrorType.rateLimited:
        return _ErrorColors(
          primary: Colors.purple,
          background:
              isDark ? Colors.purple.withValues(alpha: 0.15) : Colors.purple.shade50,
          icon: Icons.speed_rounded,
        );
      case ErrorType.generic:
        return _ErrorColors(
          primary: Colors.grey,
          background: isDark ? Colors.grey.withValues(alpha: 0.15) : Colors.grey.shade100,
          icon: Icons.error_outline_rounded,
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
        return 'Le serveur met du temps à répondre. Cela peut être temporaire.';
      case ErrorType.network:
        return 'Vérifiez votre connexion Wi-Fi ou données mobiles.';
      case ErrorType.server:
        return 'Nos équipes sont informées. Réessayez dans quelques minutes.';
      case ErrorType.rateLimited:
        return 'Vous avez effectué trop de requêtes. Patientez un moment.';
      case ErrorType.generic:
        return null;
    }
  }
}

class _ErrorColors {
  final Color primary;
  final Color background;
  final IconData icon;

  const _ErrorColors({
    required this.primary,
    required this.background,
    required this.icon,
  });
}
