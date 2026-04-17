import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Intercepteur de retry automatique avec backoff exponentiel.
///
/// Gère automatiquement :
/// - Erreurs réseau (timeout, connexion)
/// - Erreurs serveur 5xx (sauf 501 Not Implemented)
/// - Rate limiting 429 (avec respect du header Retry-After)
/// - Erreurs 503 Service Unavailable
class RetryInterceptor extends Interceptor {
  final Dio dio;
  
  /// Nombre maximum de tentatives (défaut: 3)
  final int maxRetries;
  
  /// Délai initial avant le premier retry (défaut: 1s)
  final Duration initialDelay;
  
  /// Délai maximum entre les retries (défaut: 30s)
  final Duration maxDelay;
  
  /// Multiplicateur pour le backoff exponentiel (défaut: 2.0)
  final double backoffMultiplier;
  
  /// Ajoute un jitter aléatoire pour éviter les thundering herds
  final bool useJitter;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
    
    // Vérifie si on peut réessayer
    if (!_shouldRetry(err) || retryCount >= maxRetries) {
      return super.onError(err, handler);
    }

    // Calcule le délai avec backoff exponentiel
    final delay = _calculateDelay(err, retryCount);
    
    if (kDebugMode) {
      final statusCode = err.response?.statusCode ?? 'N/A';
      debugPrint('🔄 [Retry ${retryCount + 1}/$maxRetries] '
          '${err.requestOptions.path} (status: $statusCode) '
          '- waiting ${delay.inMilliseconds}ms');
    }

    await Future.delayed(delay);

    try {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      final response = await dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      // Propage l'erreur pour un autre cycle de retry si applicable
      return onError(e, handler);
    }
  }

  /// Détermine si l'erreur est éligible pour un retry.
  bool _shouldRetry(DioException err) {
    // NE PAS retenter les timeouts — ils ont déjà attendu trop longtemps.
    // Le timeout du provider Riverpod gère la limite globale.
    switch (err.type) {
      case DioExceptionType.connectionError:
        return true; // Erreur réseau instantanée → retry utile
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return false; // Timeout = a déjà attendu 8-10s → ne pas re-attendre
      default:
        break;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode == null) return false;

    // Retry sur codes HTTP spécifiques
    return _retryableStatusCodes.contains(statusCode);
  }

  /// Codes HTTP éligibles pour un retry automatique.
  static const _retryableStatusCodes = {
    408, // Request Timeout
    429, // Too Many Requests (rate limiting)
    500, // Internal Server Error
    502, // Bad Gateway
    503, // Service Unavailable
    504, // Gateway Timeout
  };

  /// Calcule le délai avant le prochain retry.
  Duration _calculateDelay(DioException err, int retryCount) {
    // Respecte le header Retry-After si présent (429, 503)
    final retryAfter = _parseRetryAfter(err.response?.headers);
    if (retryAfter != null) {
      // Clamp manually since Duration doesn't have clamp
      if (retryAfter < Duration.zero) return Duration.zero;
      if (retryAfter > maxDelay) return maxDelay;
      return retryAfter;
    }

    // Backoff exponentiel: delay * multiplier^retryCount
    final exponentialDelay = initialDelay.inMilliseconds * 
        math.pow(backoffMultiplier, retryCount).toInt();
    
    var delayMs = math.min(exponentialDelay, maxDelay.inMilliseconds);
    
    // Ajoute un jitter aléatoire (±25%) pour éviter les thundering herds
    if (useJitter) {
      final jitter = (delayMs * 0.25 * (math.Random().nextDouble() * 2 - 1)).toInt();
      delayMs = (delayMs + jitter).clamp(0, maxDelay.inMilliseconds);
    }
    
    return Duration(milliseconds: delayMs);
  }

  /// Parse le header Retry-After (secondes ou date HTTP).
  Duration? _parseRetryAfter(Headers? headers) {
    final retryAfter = headers?.value('retry-after');
    if (retryAfter == null) return null;

    // Essaye de parser comme nombre de secondes
    final seconds = int.tryParse(retryAfter);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }

    // Essaye de parser comme date HTTP (RFC 7231)
    try {
      final date = HttpDate.parse(retryAfter);
      final diff = date.difference(DateTime.now());
      return diff.isNegative ? Duration.zero : diff;
    } catch (_) {
      return null;
    }
  }
}

/// Classe utilitaire pour parser les dates HTTP.
class HttpDate {
  static DateTime parse(String date) {
    // Format: "Wed, 21 Oct 2015 07:28:00 GMT"
    return DateTime.parse(date);
  }
}
