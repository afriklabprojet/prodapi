import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';

/// Modèle de préférences de relevés automatiques
class StatementPreference {
  final String frequency;
  final String frequencyLabel;
  final String format;
  final String formatLabel;
  final bool autoSend;
  final String? email;
  final DateTime? nextSendAt;
  final String? nextSendLabel;
  final DateTime? lastSentAt;
  final bool isConfigured;

  StatementPreference({
    required this.frequency,
    required this.frequencyLabel,
    required this.format,
    required this.formatLabel,
    required this.autoSend,
    this.email,
    this.nextSendAt,
    this.nextSendLabel,
    this.lastSentAt,
    required this.isConfigured,
  });

  factory StatementPreference.fromJson(Map<String, dynamic> json) {
    return StatementPreference(
      frequency: json['frequency'] ?? 'monthly',
      frequencyLabel: json['frequency_label'] ?? 'Mensuel',
      format: json['format'] ?? 'pdf',
      formatLabel: json['format_label'] ?? 'PDF',
      autoSend: json['auto_send'] ?? false,
      email: json['email'],
      nextSendAt: json['next_send_at'] != null 
          ? DateTime.tryParse(json['next_send_at']) 
          : null,
      nextSendLabel: json['next_send_label'],
      lastSentAt: json['last_sent_at'] != null 
          ? DateTime.tryParse(json['last_sent_at']) 
          : null,
      isConfigured: json['is_configured'] ?? false,
    );
  }

  /// Valeurs par défaut
  factory StatementPreference.defaults() {
    return StatementPreference(
      frequency: 'monthly',
      frequencyLabel: 'Mensuel',
      format: 'pdf',
      formatLabel: 'PDF',
      autoSend: false,
      isConfigured: false,
    );
  }
}

/// Service pour gérer les préférences de relevés automatiques
class StatementPreferenceService {
  final ApiClient _apiClient;

  StatementPreferenceService(this._apiClient);

  /// Récupérer les préférences actuelles
  Future<StatementPreference> getPreferences() async {
    try {
      final response = await _apiClient.get('/pharmacy/statement-preferences');
      final data = response.data;
      
      if (data is Map<String, dynamic> && data['success'] == true && data['data'] != null) {
        return StatementPreference.fromJson(data['data']);
      }
      
      return StatementPreference.defaults();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching statement preferences: $e');
      return StatementPreference.defaults();
    }
  }

  /// Sauvegarder les préférences
  Future<({bool success, String message, StatementPreference? preference})> savePreferences({
    required String frequency,
    required String format,
    required bool autoSend,
    String? email,
  }) async {
    try {
      final response = await _apiClient.post(
        '/pharmacy/statement-preferences',
        data: {
          'frequency': frequency,
          'format': format,
          'auto_send': autoSend,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      final data = response.data;

      if (data is Map<String, dynamic> && data['success'] == true) {
        return (
          success: true,
          message: (data['message'] ?? 'Préférences enregistrées') as String,
          preference: StatementPreference.fromJson(data['data']),
        );
      } else {
        return (
          success: false,
          message: (data['message'] ?? 'Erreur lors de l\'enregistrement') as String,
          preference: null,
        );
      }
    } catch (e) {
      return (
        success: false,
        message: 'Erreur de connexion: $e',
        preference: null,
      );
    }
  }

  /// Désactiver les relevés automatiques
  Future<bool> disableAutoStatements() async {
    try {
      final response = await _apiClient.delete('/pharmacy/statement-preferences');
      final data = response.data;
      
      if (data is Map<String, dynamic>) {
        return data['success'] == true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Error disabling auto statements: $e');
      return false;
    }
  }

  /// Convertir la fréquence UI vers la valeur API
  static String frequencyToApi(String uiFrequency) {
    return switch (uiFrequency) {
      'Hebdomadaire' => 'weekly',
      'Mensuel' => 'monthly',
      'Trimestriel' => 'quarterly',
      _ => 'monthly',
    };
  }

  /// Convertir la fréquence API vers l'UI
  static String frequencyToUi(String apiFrequency) {
    return switch (apiFrequency) {
      'weekly' => 'Hebdomadaire',
      'monthly' => 'Mensuel',
      'quarterly' => 'Trimestriel',
      _ => 'Mensuel',
    };
  }

  /// Convertir le format UI vers la valeur API
  static String formatToApi(String uiFormat) {
    return uiFormat.toLowerCase();
  }

  /// Convertir le format API vers l'UI
  static String formatToUi(String apiFormat) {
    return apiFormat.toUpperCase();
  }
}

/// Provider pour le service de préférences de relevés
final statementPreferenceServiceProvider = Provider<StatementPreferenceService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StatementPreferenceService(apiClient);
});
