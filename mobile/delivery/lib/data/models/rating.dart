import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/safe_json.dart';

part 'rating.freezed.dart';
part 'rating.g.dart';

/// Tags prédéfinis pour les évaluations positives
enum PositiveRatingTag {
  @JsonValue('client_aimable')
  clientAimable,
  @JsonValue('facile_trouver')
  facileTrouver,
  @JsonValue('bon_pourboire')
  bonPourboire,
  @JsonValue('reponse_rapide')
  reponseRapide,
}

/// Tags prédéfinis pour les évaluations négatives
enum NegativeRatingTag {
  @JsonValue('difficile_trouver')
  difficileTrouver,
  @JsonValue('pas_reponse')
  pasReponse,
  @JsonValue('adresse_incorrecte')
  adresseIncorrecte,
  @JsonValue('impoli')
  impoli,
}

/// Extension pour obtenir le libellé affiché
extension PositiveRatingTagExtension on PositiveRatingTag {
  String get displayLabel {
    switch (this) {
      case PositiveRatingTag.clientAimable:
        return 'Client aimable';
      case PositiveRatingTag.facileTrouver:
        return 'Facile à trouver';
      case PositiveRatingTag.bonPourboire:
        return 'Bon pourboire';
      case PositiveRatingTag.reponseRapide:
        return 'Réponse rapide';
    }
  }
}

extension NegativeRatingTagExtension on NegativeRatingTag {
  String get displayLabel {
    switch (this) {
      case NegativeRatingTag.difficileTrouver:
        return 'Difficile à trouver';
      case NegativeRatingTag.pasReponse:
        return 'Pas de réponse';
      case NegativeRatingTag.adresseIncorrecte:
        return 'Adresse incorrecte';
      case NegativeRatingTag.impoli:
        return 'Impoli';
    }
  }
}

/// Modèle d'évaluation client par le coursier.
/// 
/// Utilisé pour :
/// - Soumettre une évaluation après livraison
/// - Afficher l'historique des évaluations
/// - Calculer les statistiques de satisfaction
@freezed
abstract class Rating with _$Rating {
  const Rating._();

  const factory Rating({
    /// ID unique de l'évaluation
    @JsonKey(fromJson: safeIntOrNull) int? id,
    
    /// ID de la livraison associée
    @JsonKey(name: 'delivery_id', fromJson: safeInt) required int deliveryId,
    
    /// ID du coursier qui évalue
    @JsonKey(name: 'courier_id', fromJson: safeIntOrNull) int? courierId,
    
    /// ID du client évalué
    @JsonKey(name: 'customer_id', fromJson: safeIntOrNull) int? customerId,
    
    /// Note de 1 à 5 étoiles
    @JsonKey(fromJson: safeInt) required int rating,
    
    /// Commentaire optionnel
    String? comment,
    
    /// Tags sélectionnés (positifs ou négatifs)
    @Default([]) List<String> tags,
    
    /// Date de création
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Rating;

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);

  /// Vérifie si l'évaluation est valide pour soumission
  bool get isValid => rating >= 1 && rating <= 5;

  /// Vérifie si c'est une évaluation positive (>= 4 étoiles)
  bool get isPositive => rating >= 4;

  /// Vérifie si c'est une évaluation négative (<= 2 étoiles)
  bool get isNegative => rating <= 2;

  /// Vérifie si c'est une évaluation neutre (3 étoiles)
  bool get isNeutral => rating == 3;

  /// Emoji correspondant à la note
  String get ratingEmoji {
    switch (rating) {
      case 1:
        return '😞';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '❓';
    }
  }

  /// Label descriptif de la note
  String get ratingLabel {
    switch (rating) {
      case 1:
        return 'Très mauvais';
      case 2:
        return 'Mauvais';
      case 3:
        return 'Correct';
      case 4:
        return 'Bien';
      case 5:
        return 'Excellent';
      default:
        return 'Non noté';
    }
  }

  /// Convertit en Map pour l'envoi API
  Map<String, dynamic> toApiPayload() {
    return {
      'delivery_id': deliveryId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      if (tags.isNotEmpty) 'tags': tags,
    };
  }
}

/// Statistiques d'évaluation pour un coursier
@freezed
abstract class RatingStats with _$RatingStats {
  const factory RatingStats({
    /// Note moyenne (1.0 - 5.0)
    @JsonKey(name: 'average_rating', fromJson: safeDouble) @Default(0.0) double averageRating,
    
    /// Nombre total d'évaluations reçues
    @JsonKey(name: 'total_ratings', fromJson: safeInt) @Default(0) int totalRatings,
    
    /// Répartition par note (index 0 = 1 étoile, index 4 = 5 étoiles)
    @JsonKey(name: 'rating_distribution') @Default([0, 0, 0, 0, 0]) List<int> distribution,
    
    /// Pourcentage d'évaluations positives (>= 4 étoiles)
    @JsonKey(name: 'positive_percentage', fromJson: safeDouble) @Default(0.0) double positivePercentage,
    
    /// Tags les plus fréquents
    @JsonKey(name: 'top_tags') @Default([]) List<String> topTags,
  }) = _RatingStats;

  factory RatingStats.fromJson(Map<String, dynamic> json) =>
      _$RatingStatsFromJson(json);
}
