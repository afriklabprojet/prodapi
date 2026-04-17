import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/safe_json_utils.dart';

final livenessRepositoryProvider = Provider<LivenessRepository>((ref) {
  return LivenessRepository(ref.read(dioProvider));
});

/// Résultat d'une session de liveness
class LivenessSession {
  final String sessionId;
  final List<String> challenges;
  final int timeout;

  const LivenessSession({
    required this.sessionId,
    required this.challenges,
    required this.timeout,
  });

  factory LivenessSession.fromJson(Map<String, dynamic> json) {
    return LivenessSession(
      sessionId: json['session_id'] as String? ?? '',
      challenges:
          (json['challenges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['blink', 'smile', 'turn_left'],
      timeout: json['timeout'] as int? ?? 60,
    );
  }
}

/// Résultat de la validation liveness
class LivenessResult {
  final bool success;
  final double confidence;
  final String? message;
  final String? error;

  const LivenessResult({
    required this.success,
    required this.confidence,
    this.message,
    this.error,
  });

  factory LivenessResult.fromJson(Map<String, dynamic> json) {
    return LivenessResult(
      success: json['success'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}

/// Statut d'une session liveness
enum LivenessSessionStatus { pending, processing, completed, failed, expired }

class LivenessStatusResult {
  final LivenessSessionStatus status;
  final double? confidence;
  final String? message;

  const LivenessStatusResult({
    required this.status,
    this.confidence,
    this.message,
  });

  factory LivenessStatusResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    final status = switch (statusStr) {
      'completed' => LivenessSessionStatus.completed,
      'processing' => LivenessSessionStatus.processing,
      'failed' => LivenessSessionStatus.failed,
      'expired' => LivenessSessionStatus.expired,
      _ => LivenessSessionStatus.pending,
    };
    return LivenessStatusResult(
      status: status,
      confidence: (json['confidence'] as num?)?.toDouble(),
      message: json['message'] as String?,
    );
  }
}

class LivenessRepository {
  final Dio _dio;

  LivenessRepository(this._dio);

  /// Démarrer une session de liveness verification
  Future<LivenessSession> startSession() async {
    try {
      final response = await _dio.post(
        ApiConstants.livenessStart,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final data = SafeJsonUtils.safeMap(response.data);
      final sessionData = data['data'] ?? data;
      return LivenessSession.fromJson(
        Map<String, dynamic>.from(sessionData as Map),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Backend pas encore prêt — session locale de démonstration
        return const LivenessSession(
          sessionId: 'local_demo',
          challenges: ['blink', 'smile', 'turn_left'],
          timeout: 90,
        );
      }
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors du démarrage de la vérification',
        ),
      );
    }
  }

  /// Valider une image de liveness (selfie prise pendant le challenge)
  Future<LivenessResult> validateImage({
    required String sessionId,
    required File imageFile,
    required String challenge,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'session_id': sessionId,
        'challenge': challenge,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename:
              'liveness_${challenge}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post(
        ApiConstants.livenessValidateFile,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = SafeJsonUtils.safeMap(response.data);
      final resultData = data['data'] ?? data;
      return LivenessResult.fromJson(
        Map<String, dynamic>.from(resultData as Map),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        return const LivenessResult(
          success: false,
          confidence: 0,
          error: 'Image non valide. Veuillez réessayer.',
        );
      }
      if (e.response?.statusCode == 404) {
        return const LivenessResult(
          success: false,
          confidence: 0,
          error: 'Service temporairement indisponible.',
        );
      }
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connexion lente. Vérifiez votre réseau et réessayez.');
      }
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors de la validation',
        ),
      );
    }
  }

  /// Vérifier le statut d'une session
  Future<LivenessStatusResult> getSessionStatus(String sessionId) async {
    try {
      final response = await _dio.get(ApiConstants.livenessStatus(sessionId));
      final data = SafeJsonUtils.safeMap(response.data);
      final statusData = data['data'] ?? data;
      return LivenessStatusResult.fromJson(
        Map<String, dynamic>.from(statusData as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors de la vérification du statut',
        ),
      );
    }
  }

  /// Annuler une session de liveness
  Future<void> cancelSession(String sessionId) async {
    try {
      await _dio.post(ApiConstants.livenessCancel(sessionId));
    } catch (_) {
      // Ignorer les erreurs d'annulation
    }
  }

  /// Score de confiance global d'une session
  Future<LivenessScore> getScore(String sessionId) async {
    try {
      final response = await _dio.get(ApiConstants.livenessScore(sessionId));
      final data = SafeJsonUtils.safeMap(response.data);
      final scoreData = data['data'] ?? data;
      return LivenessScore.fromJson(
        Map<String, dynamic>.from(scoreData as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors de la récupération du score',
        ),
      );
    }
  }

  /// Historique des vérifications liveness du coursier
  Future<List<LivenessHistoryEntry>> getHistory() async {
    try {
      final response = await _dio.get(ApiConstants.livenessHistory);
      final data = SafeJsonUtils.safeMap(response.data);
      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .map(
            (e) => LivenessHistoryEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage:
              'Erreur lors de la récupération de l\'historique liveness',
        ),
      );
    }
  }
}

/// Score de confiance global d'une session liveness
class LivenessScore {
  final String sessionId;
  final double overallScore;
  final Map<String, double> challengeScores;
  final bool passed;
  final DateTime? evaluatedAt;

  const LivenessScore({
    required this.sessionId,
    required this.overallScore,
    required this.challengeScores,
    required this.passed,
    this.evaluatedAt,
  });

  factory LivenessScore.fromJson(Map<String, dynamic> json) {
    final scoresRaw = json['challenge_scores'] as Map<String, dynamic>? ?? {};
    final scores = scoresRaw.map(
      (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0),
    );
    return LivenessScore(
      sessionId: json['session_id'] as String? ?? '',
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      challengeScores: scores,
      passed: json['passed'] as bool? ?? false,
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.tryParse(json['evaluated_at'] as String)
          : null,
    );
  }
}

/// Entrée d'historique liveness
class LivenessHistoryEntry {
  final String sessionId;
  final LivenessSessionStatus status;
  final double? score;
  final DateTime createdAt;
  final DateTime? completedAt;

  const LivenessHistoryEntry({
    required this.sessionId,
    required this.status,
    this.score,
    required this.createdAt,
    this.completedAt,
  });

  factory LivenessHistoryEntry.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    final status = switch (statusStr) {
      'completed' => LivenessSessionStatus.completed,
      'processing' => LivenessSessionStatus.processing,
      'failed' => LivenessSessionStatus.failed,
      'expired' => LivenessSessionStatus.expired,
      _ => LivenessSessionStatus.pending,
    };
    return LivenessHistoryEntry(
      sessionId: json['session_id'] as String? ?? '',
      status: status,
      score: (json['score'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }
}
