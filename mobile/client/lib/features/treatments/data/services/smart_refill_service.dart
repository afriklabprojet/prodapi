import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/treatment_entity.dart';
import '../../presentation/providers/treatments_provider.dart';
import 'treatment_notification_service.dart';

/// État des suggestions Smart Refill
class SmartRefillState {
  final List<RefillSuggestion> suggestions;
  final bool isLoading;
  final DateTime? lastChecked;

  const SmartRefillState({
    this.suggestions = const [],
    this.isLoading = false,
    this.lastChecked,
  });

  SmartRefillState copyWith({
    List<RefillSuggestion>? suggestions,
    bool? isLoading,
    DateTime? lastChecked,
  }) {
    return SmartRefillState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  /// Suggestions urgentes (date dépassée ou dans 3 jours)
  List<RefillSuggestion> get urgentSuggestions =>
      suggestions.where((s) => s.urgency == RefillUrgency.urgent).toList();

  /// Suggestions à venir (dans 7 jours)
  List<RefillSuggestion> get upcomingSuggestions =>
      suggestions.where((s) => s.urgency == RefillUrgency.upcoming).toList();

  bool get hasUrgent => urgentSuggestions.isNotEmpty;
  bool get hasAny => suggestions.isNotEmpty;
}

/// Niveau d'urgence pour le renouvellement
enum RefillUrgency {
  urgent, // <= 3 jours ou dépassé
  upcoming, // 4-7 jours
  normal, // > 7 jours
}

/// Suggestion de renouvellement
class RefillSuggestion {
  final TreatmentEntity treatment;
  final int daysRemaining;
  final RefillUrgency urgency;
  final String message;
  final bool wasDismissed;

  RefillSuggestion({
    required this.treatment,
    required this.daysRemaining,
    required this.urgency,
    required this.message,
    this.wasDismissed = false,
  });

  RefillSuggestion copyWith({bool? wasDismissed}) {
    return RefillSuggestion(
      treatment: treatment,
      daysRemaining: daysRemaining,
      urgency: urgency,
      message: message,
      wasDismissed: wasDismissed ?? this.wasDismissed,
    );
  }
}

/// Provider pour les suggestions Smart Refill
final smartRefillProvider =
    StateNotifierProvider<SmartRefillNotifier, SmartRefillState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SmartRefillNotifier(prefs, ref);
    });

class SmartRefillNotifier extends StateNotifier<SmartRefillState> {
  final SharedPreferences _prefs;
  final Ref _ref;
  Timer? _checkTimer;

  static const _dismissedKey = 'smart_refill_dismissed';

  SmartRefillNotifier(this._prefs, this._ref)
    : super(const SmartRefillState()) {
    // Vérifier toutes les 6 heures
    _checkTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => checkRefills(),
    );
  }

  /// Charge et analyse les traitements pour générer des suggestions
  Future<void> checkRefills() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      // Utiliser le repository via le provider (datasource déjà initialisé au démarrage)
      final repository = _ref.read(treatmentsRepositoryProvider);
      final result = await repository.getTreatments();

      result.fold(
        (failure) {
          AppLogger.error('Failed to load treatments for Smart Refill');
          state = state.copyWith(isLoading: false);
        },
        (treatments) {
          final suggestions = _generateSuggestions(treatments);
          state = SmartRefillState(
            suggestions: suggestions,
            isLoading: false,
            lastChecked: DateTime.now(),
          );
          AppLogger.info(
            'Smart Refill: ${suggestions.length} suggestions generated',
          );
        },
      );
    } catch (e) {
      AppLogger.error('Smart Refill check failed', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Génère les suggestions de renouvellement
  List<RefillSuggestion> _generateSuggestions(
    List<TreatmentEntity> treatments,
  ) {
    final dismissedIds = _getDismissedIds();
    final suggestions = <RefillSuggestion>[];

    for (final treatment in treatments) {
      if (!treatment.isActive || treatment.nextRenewalDate == null) continue;

      final days = treatment.daysUntilRenewal ?? 0;

      // Ne pas suggérer si > 7 jours
      if (days > 7) continue;

      // Ne pas suggérer si récemment ignoré (24h)
      if (dismissedIds.contains(treatment.id)) continue;

      final urgency = _calculateUrgency(days);
      final message = _generateMessage(treatment, days);

      suggestions.add(
        RefillSuggestion(
          treatment: treatment,
          daysRemaining: days,
          urgency: urgency,
          message: message,
        ),
      );
    }

    // Trier par urgence puis par jours restants
    suggestions.sort((a, b) {
      final urgencyCompare = a.urgency.index.compareTo(b.urgency.index);
      if (urgencyCompare != 0) return urgencyCompare;
      return a.daysRemaining.compareTo(b.daysRemaining);
    });

    return suggestions;
  }

  RefillUrgency _calculateUrgency(int daysRemaining) {
    if (daysRemaining <= 3) return RefillUrgency.urgent;
    if (daysRemaining <= 7) return RefillUrgency.upcoming;
    return RefillUrgency.normal;
  }

  String _generateMessage(TreatmentEntity treatment, int days) {
    if (days < 0) {
      final overdueDays = days.abs();
      return 'Votre ${treatment.productName} aurait dû être renouvelé il y a $overdueDays jour${overdueDays > 1 ? 's' : ''}';
    }
    if (days == 0) {
      return 'Dernière chance : votre ${treatment.productName} doit être renouvelé aujourd\'hui';
    }
    if (days == 1) {
      return 'Votre ${treatment.productName} doit être renouvelé demain';
    }
    if (days <= 3) {
      return 'Plus que $days jours pour renouveler votre ${treatment.productName}';
    }
    return 'Votre ${treatment.productName} arrive à échéance dans $days jours';
  }

  /// Ignore temporairement une suggestion (24h)
  Future<void> dismissSuggestion(String treatmentId) async {
    final dismissedIds = _getDismissedIds();
    dismissedIds.add(treatmentId);
    await _prefs.setStringList(_dismissedKey, dismissedIds.toList());

    // Mettre à jour l'état local
    final updatedSuggestions = state.suggestions
        .where((s) => s.treatment.id != treatmentId)
        .toList();
    state = state.copyWith(suggestions: updatedSuggestions);

    // Supprimer automatiquement après 24h
    Future.delayed(const Duration(hours: 24), () {
      _removeDismissed(treatmentId);
    });
  }

  Set<String> _getDismissedIds() {
    return (_prefs.getStringList(_dismissedKey) ?? []).toSet();
  }

  Future<void> _removeDismissed(String treatmentId) async {
    final dismissedIds = _getDismissedIds();
    dismissedIds.remove(treatmentId);
    await _prefs.setStringList(_dismissedKey, dismissedIds.toList());
  }

  /// Marque une commande comme passée et met à jour le traitement
  Future<void> markAsOrdered(String treatmentId) async {
    // Utiliser le repository via le provider
    final repository = _ref.read(treatmentsRepositoryProvider);

    // Trouver le traitement
    final suggestion = state.suggestions.firstWhere(
      (s) => s.treatment.id == treatmentId,
      orElse: () => throw Exception('Treatment not found'),
    );

    // Calculer la prochaine date de renouvellement
    final nextDate = DateTime.now().add(
      Duration(days: suggestion.treatment.renewalPeriodDays),
    );

    // Mettre à jour le traitement
    final updated = suggestion.treatment.copyWith(
      lastOrderedAt: DateTime.now(),
      nextRenewalDate: nextDate,
    );

    await repository.updateTreatment(updated);

    // Replanifier la notification
    await TreatmentNotificationService().scheduleRenewalReminder(updated);

    // Supprimer la suggestion
    final updatedSuggestions = state.suggestions
        .where((s) => s.treatment.id != treatmentId)
        .toList();
    state = state.copyWith(suggestions: updatedSuggestions);

    AppLogger.info(
      'Treatment $treatmentId marked as ordered, next renewal: $nextDate',
    );
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
