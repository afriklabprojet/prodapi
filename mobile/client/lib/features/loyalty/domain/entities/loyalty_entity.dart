import 'package:equatable/equatable.dart';

/// Palier de fidélité
enum LoyaltyTier {
  bronze,
  silver,
  gold,
  platinum;

  String get displayName {
    switch (this) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Silver';
      case LoyaltyTier.gold:
        return 'Gold';
      case LoyaltyTier.platinum:
        return 'Platinum';
    }
  }

  /// Points nécessaires pour atteindre ce palier
  int get requiredPoints {
    switch (this) {
      case LoyaltyTier.bronze:
        return 0;
      case LoyaltyTier.silver:
        return 500;
      case LoyaltyTier.gold:
        return 2000;
      case LoyaltyTier.platinum:
        return 5000;
    }
  }

  /// Points pour le palier suivant (null si platinum)
  int? get nextTierPoints {
    switch (this) {
      case LoyaltyTier.bronze:
        return LoyaltyTier.silver.requiredPoints;
      case LoyaltyTier.silver:
        return LoyaltyTier.gold.requiredPoints;
      case LoyaltyTier.gold:
        return LoyaltyTier.platinum.requiredPoints;
      case LoyaltyTier.platinum:
        return null;
    }
  }

  /// Réduction en pourcentage pour ce palier
  int get discountPercent {
    switch (this) {
      case LoyaltyTier.bronze:
        return 0;
      case LoyaltyTier.silver:
        return 5;
      case LoyaltyTier.gold:
        return 10;
      case LoyaltyTier.platinum:
        return 15;
    }
  }

  /// Avantages du palier
  List<String> get benefits {
    switch (this) {
      case LoyaltyTier.bronze:
        return ['1 point par 100 F dépensés', 'Accès aux promotions'];
      case LoyaltyTier.silver:
        return [
          '5% de réduction permanente',
          '2 points par 100 F dépensés',
          'Livraison gratuite 1x/mois',
        ];
      case LoyaltyTier.gold:
        return [
          '10% de réduction permanente',
          '3 points par 100 F dépensés',
          'Livraison gratuite illimitée',
          'Service prioritaire',
        ];
      case LoyaltyTier.platinum:
        return [
          '15% de réduction permanente',
          '5 points par 100 F dépensés',
          'Livraison gratuite illimitée',
          'Service prioritaire',
          'Offres exclusives',
          'Support dédié',
        ];
    }
  }

  static LoyaltyTier fromPoints(int points) {
    if (points >= LoyaltyTier.platinum.requiredPoints) return LoyaltyTier.platinum;
    if (points >= LoyaltyTier.gold.requiredPoints) return LoyaltyTier.gold;
    if (points >= LoyaltyTier.silver.requiredPoints) return LoyaltyTier.silver;
    return LoyaltyTier.bronze;
  }

  static LoyaltyTier fromString(String? value) {
    switch (value) {
      case 'silver':
        return LoyaltyTier.silver;
      case 'gold':
        return LoyaltyTier.gold;
      case 'platinum':
        return LoyaltyTier.platinum;
      default:
        return LoyaltyTier.bronze;
    }
  }
}

/// Entité de fidélité utilisateur
class LoyaltyEntity extends Equatable {
  final int totalPoints;
  final int availablePoints;
  final LoyaltyTier tier;
  final int totalOrders;
  final double totalSpent;
  final int pointsToNextTier;
  final List<LoyaltyReward> availableRewards;

  const LoyaltyEntity({
    required this.totalPoints,
    required this.availablePoints,
    required this.tier,
    required this.totalOrders,
    required this.totalSpent,
    required this.pointsToNextTier,
    this.availableRewards = const [],
  });

  double get progressToNextTier {
    if (tier == LoyaltyTier.platinum) return 1.0;
    final nextPoints = tier.nextTierPoints!;
    final currentMin = tier.requiredPoints;
    final range = nextPoints - currentMin;
    if (range <= 0) return 1.0;
    return ((totalPoints - currentMin) / range).clamp(0.0, 1.0);
  }

  factory LoyaltyEntity.fromJson(Map<String, dynamic> json) {
    final rewards = (json['available_rewards'] as List<dynamic>?)
            ?.map((r) => LoyaltyReward.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return LoyaltyEntity(
      totalPoints: json['total_points'] as int? ?? 0,
      availablePoints: json['available_points'] as int? ?? 0,
      tier: LoyaltyTier.fromString(json['tier']?.toString()),
      totalOrders: json['total_orders'] as int? ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      pointsToNextTier: json['points_to_next_tier'] as int? ?? 0,
      availableRewards: rewards,
    );
  }

  @override
  List<Object?> get props =>
      [totalPoints, availablePoints, tier, totalOrders, totalSpent];
}

/// Récompense échangeable
class LoyaltyReward extends Equatable {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String type; // 'discount', 'free_delivery', 'gift'

  const LoyaltyReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.type,
  });

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) {
    return LoyaltyReward(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pointsCost: json['points_cost'] as int? ?? 0,
      type: json['type']?.toString() ?? 'discount',
    );
  }

  @override
  List<Object?> get props => [id, title, pointsCost, type];
}
