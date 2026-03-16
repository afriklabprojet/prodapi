import 'package:flutter/material.dart';

/// Modèle représentant un badge de gamification
class GamificationBadge {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int requiredValue;
  final int currentValue;
  final String category;

  const GamificationBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.color,
    this.isUnlocked = false,
    this.unlockedAt,
    this.requiredValue = 1,
    this.currentValue = 0,
    this.category = 'general',
  });

  double get progress => requiredValue > 0 
      ? (currentValue / requiredValue).clamp(0.0, 1.0) 
      : 0.0;

  factory GamificationBadge.fromJson(Map<String, dynamic> json) {
    return GamificationBadge(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['icon'] ?? 'star',
      color: _parseColor(json['color']),
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.tryParse(json['unlocked_at']) 
          : null,
      requiredValue: (json['required_value'] as num?)?.toInt() ?? 1,
      currentValue: (json['current_value'] as num?)?.toInt() ?? 0,
      category: json['category'] ?? 'general',
    );
  }

  static Color _parseColor(String? colorStr) {
    if (colorStr == null) return Colors.blue;
    switch (colorStr.toLowerCase()) {
      case 'gold': return const Color(0xFFFFD700);
      case 'silver': return const Color(0xFFC0C0C0);
      case 'bronze': return const Color(0xFFCD7F32);
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'purple': return Colors.purple;
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      default: return Colors.blue;
    }
  }

  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'star': return Icons.star;
      case 'delivery': return Icons.local_shipping;
      case 'speed': return Icons.speed;
      case 'timer': return Icons.timer;
      case 'fire': return Icons.local_fire_department;
      case 'trophy': return Icons.emoji_events;
      case 'crown': return Icons.workspace_premium;
      case 'medal': return Icons.military_tech;
      case 'rocket': return Icons.rocket_launch;
      case 'lightning': return Icons.bolt;
      case 'heart': return Icons.favorite;
      case 'thumbup': return Icons.thumb_up;
      case 'diamond': return Icons.diamond;
      case 'verified': return Icons.verified;
      case 'streak': return Icons.whatshot;
      default: return Icons.star;
    }
  }
}

/// Modèle représentant le niveau d'un livreur
class CourierLevel {
  final int level;
  final String title;
  final int currentXP;
  final int requiredXP;
  final int totalXP;
  final Color color;
  final List<String> perks;

  const CourierLevel({
    required this.level,
    required this.title,
    required this.currentXP,
    required this.requiredXP,
    required this.totalXP,
    required this.color,
    this.perks = const [],
  });

  double get progress => requiredXP > 0 
      ? (currentXP / requiredXP).clamp(0.0, 1.0) 
      : 0.0;

  int get xpToNextLevel => requiredXP - currentXP;

  factory CourierLevel.fromJson(Map<String, dynamic> json) {
    return CourierLevel(
      level: (json['level'] as num?)?.toInt() ?? 1,
      title: json['title'] ?? 'Débutant',
      currentXP: (json['current_xp'] as num?)?.toInt() ?? 0,
      requiredXP: (json['required_xp'] as num?)?.toInt() ?? 100,
      totalXP: (json['total_xp'] as num?)?.toInt() ?? 0,
      color: _parseColor(json['color']),
      perks: (json['perks'] as List?)?.cast<String>() ?? [],
    );
  }

  static Color _parseColor(String? colorStr) {
    if (colorStr == null) return Colors.grey;
    switch (colorStr.toLowerCase()) {
      case 'bronze': return const Color(0xFFCD7F32);
      case 'silver': return const Color(0xFFC0C0C0);
      case 'gold': return const Color(0xFFFFD700);
      case 'platinum': return const Color(0xFFE5E4E2);
      case 'diamond': return const Color(0xFFB9F2FF);
      default: return Colors.blue;
    }
  }

  /// Icône selon le niveau
  IconData get icon {
    if (level >= 50) return Icons.diamond;
    if (level >= 40) return Icons.workspace_premium;
    if (level >= 30) return Icons.emoji_events;
    if (level >= 20) return Icons.military_tech;
    if (level >= 10) return Icons.star;
    return Icons.star_border;
  }
}

/// Modèle pour le classement
class LeaderboardEntry {
  final int rank;
  final int courierId;
  final String courierName;
  final String? avatarUrl;
  final int deliveriesCount;
  final int score;
  final int level;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.courierId,
    required this.courierName,
    this.avatarUrl,
    required this.deliveriesCount,
    required this.score,
    required this.level,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {bool isCurrentUser = false}) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      courierId: (json['courier_id'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      courierName: json['name'] ?? json['courier_name'] ?? 'Inconnu',
      avatarUrl: json['avatar'] ?? json['avatar_url'],
      deliveriesCount: (json['deliveries_count'] as num?)?.toInt() ?? (json['total_deliveries'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? (json['points'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      isCurrentUser: isCurrentUser,
    );
  }

  Color get rankColor {
    switch (rank) {
      case 1: return const Color(0xFFFFD700); // Gold
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return Colors.grey;
    }
  }

  IconData? get rankIcon {
    switch (rank) {
      case 1: return Icons.emoji_events;
      case 2: return Icons.workspace_premium;
      case 3: return Icons.military_tech;
      default: return null;
    }
  }
}

/// Données complètes de gamification
class GamificationData {
  final CourierLevel level;
  final List<GamificationBadge> badges;
  final List<GamificationBadge> recentBadges;
  final List<LeaderboardEntry> leaderboard;
  final LeaderboardEntry? currentUserRank;
  final Map<String, int> stats;

  const GamificationData({
    required this.level,
    required this.badges,
    this.recentBadges = const [],
    this.leaderboard = const [],
    this.currentUserRank,
    this.stats = const {},
  });

  factory GamificationData.fromJson(Map<String, dynamic> json) {
    final badgesList = (json['badges'] as List?)
        ?.map((b) => GamificationBadge.fromJson(b))
        .toList() ?? [];
    
    final recentList = (json['recent_badges'] as List?)
        ?.map((b) => GamificationBadge.fromJson(b))
        .toList() ?? [];
    
    final leaderboardList = (json['leaderboard'] as List?)
        ?.map((e) => LeaderboardEntry.fromJson(e))
        .toList() ?? [];

    return GamificationData(
      level: CourierLevel.fromJson(json['level'] ?? {}),
      badges: badgesList,
      recentBadges: recentList,
      leaderboard: leaderboardList,
      currentUserRank: json['my_rank'] != null 
          ? LeaderboardEntry.fromJson(json['my_rank'], isCurrentUser: true)
          : null,
      stats: Map<String, int>.from(json['stats'] ?? {}),
    );
  }

  /// Badges débloqués
  List<GamificationBadge> get unlockedBadges => 
      badges.where((b) => b.isUnlocked).toList();

  /// Badges verrouillés
  List<GamificationBadge> get lockedBadges => 
      badges.where((b) => !b.isUnlocked).toList();

  /// Badges par catégorie
  Map<String, List<GamificationBadge>> get badgesByCategory {
    final map = <String, List<GamificationBadge>>{};
    for (final badge in badges) {
      map.putIfAbsent(badge.category, () => []).add(badge);
    }
    return map;
  }
}

/// Définitions des niveaux (pour affichage local)
class LevelDefinitions {
  static const List<Map<String, dynamic>> levels = [
    {'level': 1, 'title': 'Débutant', 'xp': 0, 'color': 'bronze'},
    {'level': 5, 'title': 'Apprenti', 'xp': 500, 'color': 'bronze'},
    {'level': 10, 'title': 'Confirmé', 'xp': 1500, 'color': 'silver'},
    {'level': 15, 'title': 'Expert', 'xp': 3000, 'color': 'silver'},
    {'level': 20, 'title': 'Vétéran', 'xp': 5000, 'color': 'gold'},
    {'level': 30, 'title': 'Maître', 'xp': 10000, 'color': 'gold'},
    {'level': 40, 'title': 'Champion', 'xp': 20000, 'color': 'platinum'},
    {'level': 50, 'title': 'Légende', 'xp': 50000, 'color': 'diamond'},
  ];

  static String getTitleForLevel(int level) {
    for (int i = levels.length - 1; i >= 0; i--) {
      if (level >= levels[i]['level']) {
        return levels[i]['title'];
      }
    }
    return 'Débutant';
  }
}

/// Définitions des badges (pour affichage local)
class BadgeDefinitions {
  static const List<Map<String, dynamic>> badges = [
    // Badges de livraison
    {'id': 'first_delivery', 'name': 'Première Livraison', 'icon': 'delivery', 'color': 'bronze', 'category': 'deliveries'},
    {'id': 'delivery_10', 'name': '10 Livraisons', 'icon': 'delivery', 'color': 'bronze', 'category': 'deliveries'},
    {'id': 'delivery_50', 'name': '50 Livraisons', 'icon': 'delivery', 'color': 'silver', 'category': 'deliveries'},
    {'id': 'delivery_100', 'name': 'Centurion', 'icon': 'delivery', 'color': 'gold', 'category': 'deliveries'},
    {'id': 'delivery_500', 'name': 'Légende', 'icon': 'trophy', 'color': 'gold', 'category': 'deliveries'},
    
    // Badges de vitesse
    {'id': 'speed_demon', 'name': 'Éclair', 'icon': 'lightning', 'color': 'blue', 'category': 'speed'},
    {'id': 'on_time_10', 'name': 'Ponctuel', 'icon': 'timer', 'color': 'green', 'category': 'speed'},
    {'id': 'on_time_50', 'name': 'Fiable', 'icon': 'verified', 'color': 'green', 'category': 'speed'},
    
    // Badges de satisfaction
    {'id': 'five_star', 'name': '5 Étoiles', 'icon': 'star', 'color': 'gold', 'category': 'rating'},
    {'id': 'perfect_week', 'name': 'Semaine Parfaite', 'icon': 'crown', 'color': 'purple', 'category': 'rating'},
    
    // Badges de streak
    {'id': 'streak_3', 'name': '3 Jours', 'icon': 'streak', 'color': 'orange', 'category': 'streak'},
    {'id': 'streak_7', 'name': 'Semaine Active', 'icon': 'fire', 'color': 'orange', 'category': 'streak'},
    {'id': 'streak_30', 'name': 'Mois Complet', 'icon': 'fire', 'color': 'red', 'category': 'streak'},
  ];
}

// ══════════════════════════════════════════════════════════════════════════════
// DÉFIS QUOTIDIENS
// ══════════════════════════════════════════════════════════════════════════════

/// Type de défi
enum ChallengeType {
  deliveries,    // Nombre de livraisons
  earnings,      // Montant gagné
  distance,      // Distance parcourue
  speed,         // Livraisons rapides
  rating,        // Maintenir une note
  streak,        // Jours consécutifs
  special,       // Événements spéciaux
}

/// Difficulté du défi
enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  legendary,
}

/// Extension pour les propriétés de difficulté
extension ChallengeDifficultyConfig on ChallengeDifficulty {
  String get label {
    switch (this) {
      case ChallengeDifficulty.easy: return 'Facile';
      case ChallengeDifficulty.medium: return 'Moyen';
      case ChallengeDifficulty.hard: return 'Difficile';
      case ChallengeDifficulty.legendary: return 'Légendaire';
    }
  }

  Color get color {
    switch (this) {
      case ChallengeDifficulty.easy: return Colors.green;
      case ChallengeDifficulty.medium: return Colors.blue;
      case ChallengeDifficulty.hard: return Colors.orange;
      case ChallengeDifficulty.legendary: return Colors.purple;
    }
  }

  int get xpMultiplier {
    switch (this) {
      case ChallengeDifficulty.easy: return 1;
      case ChallengeDifficulty.medium: return 2;
      case ChallengeDifficulty.hard: return 3;
      case ChallengeDifficulty.legendary: return 5;
    }
  }
}

/// Modèle d'un défi quotidien
class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final int targetValue;
  final int currentValue;
  final int xpReward;
  final int? bonusReward; // Bonus en FCFA
  final DateTime expiresAt;
  final bool isCompleted;
  final bool isClaimed;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.targetValue,
    this.currentValue = 0,
    required this.xpReward,
    this.bonusReward,
    required this.expiresAt,
    this.isCompleted = false,
    this.isClaimed = false,
  });

  double get progress => targetValue > 0 
      ? (currentValue / targetValue).clamp(0.0, 1.0) 
      : 0.0;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  String get timeRemainingLabel {
    final remaining = timeRemaining;
    if (remaining.isNegative) return 'Expiré';
    if (remaining.inHours >= 1) return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    return '${remaining.inMinutes}m';
  }

  IconData get icon {
    switch (type) {
      case ChallengeType.deliveries: return Icons.local_shipping;
      case ChallengeType.earnings: return Icons.attach_money;
      case ChallengeType.distance: return Icons.straighten;
      case ChallengeType.speed: return Icons.bolt;
      case ChallengeType.rating: return Icons.star;
      case ChallengeType.streak: return Icons.local_fire_department;
      case ChallengeType.special: return Icons.auto_awesome;
    }
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: _parseType(json['type']),
      difficulty: _parseDifficulty(json['difficulty']),
      targetValue: (json['target_value'] as num?)?.toInt() ?? 1,
      currentValue: (json['current_value'] as num?)?.toInt() ?? 0,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 50,
      bonusReward: (json['bonus_reward'] as num?)?.toInt(),
      expiresAt: DateTime.tryParse(json['expires_at'] ?? '') ?? 
          DateTime.now().add(const Duration(hours: 24)),
      isCompleted: json['is_completed'] ?? false,
      isClaimed: json['is_claimed'] ?? false,
    );
  }

  static ChallengeType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'deliveries': return ChallengeType.deliveries;
      case 'earnings': return ChallengeType.earnings;
      case 'distance': return ChallengeType.distance;
      case 'speed': return ChallengeType.speed;
      case 'rating': return ChallengeType.rating;
      case 'streak': return ChallengeType.streak;
      case 'special': return ChallengeType.special;
      default: return ChallengeType.deliveries;
    }
  }

  static ChallengeDifficulty _parseDifficulty(String? diff) {
    switch (diff?.toLowerCase()) {
      case 'easy': return ChallengeDifficulty.easy;
      case 'medium': return ChallengeDifficulty.medium;
      case 'hard': return ChallengeDifficulty.hard;
      case 'legendary': return ChallengeDifficulty.legendary;
      default: return ChallengeDifficulty.easy;
    }
  }
}

/// Données des défis quotidiens
class DailyChallengesData {
  final List<DailyChallenge> challenges;
  final int completedToday;
  final int totalXpEarnedToday;
  final int currentStreak;
  final DateTime? nextRefresh;

  const DailyChallengesData({
    required this.challenges,
    this.completedToday = 0,
    this.totalXpEarnedToday = 0,
    this.currentStreak = 0,
    this.nextRefresh,
  });

  factory DailyChallengesData.fromJson(Map<String, dynamic> json) {
    final challengesList = (json['challenges'] as List?)
        ?.map((c) => DailyChallenge.fromJson(c))
        .toList() ?? [];

    return DailyChallengesData(
      challenges: challengesList,
      completedToday: (json['completed_today'] as num?)?.toInt() ?? 0,
      totalXpEarnedToday: (json['total_xp_today'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      nextRefresh: DateTime.tryParse(json['next_refresh'] ?? ''),
    );
  }

  List<DailyChallenge> get activeChallenges => 
      challenges.where((c) => !c.isExpired && !c.isClaimed).toList();

  List<DailyChallenge> get completedChallenges => 
      challenges.where((c) => c.isCompleted).toList();

  List<DailyChallenge> get claimableChallenges => 
      challenges.where((c) => c.isCompleted && !c.isClaimed).toList();
}

/// Définitions des défis (templates)
class ChallengeDefinitions {
  static List<Map<String, dynamic>> getDailyChallenges() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return [
      {
        'id': 'daily_deliveries_3',
        'title': 'Trio du jour',
        'description': 'Effectuez 3 livraisons aujourd\'hui',
        'type': 'deliveries',
        'difficulty': 'easy',
        'target_value': 3,
        'xp_reward': 50,
        'expires_at': endOfDay.toIso8601String(),
      },
      {
        'id': 'daily_deliveries_5',
        'title': 'Main de fer',
        'description': 'Effectuez 5 livraisons aujourd\'hui',
        'type': 'deliveries',
        'difficulty': 'medium',
        'target_value': 5,
        'xp_reward': 100,
        'bonus_reward': 500,
        'expires_at': endOfDay.toIso8601String(),
      },
      {
        'id': 'daily_fast_delivery',
        'title': 'Flash',
        'description': 'Livrez en moins de 20 minutes',
        'type': 'speed',
        'difficulty': 'medium',
        'target_value': 1,
        'xp_reward': 75,
        'expires_at': endOfDay.toIso8601String(),
      },
      {
        'id': 'daily_earnings',
        'title': 'Objectif revenus',
        'description': 'Gagnez 5000 FCFA aujourd\'hui',
        'type': 'earnings',
        'difficulty': 'hard',
        'target_value': 5000,
        'xp_reward': 150,
        'bonus_reward': 1000,
        'expires_at': endOfDay.toIso8601String(),
      },
      {
        'id': 'daily_perfect',
        'title': 'Perfection',
        'description': 'Toutes vos livraisons à 5 ★',
        'type': 'rating',
        'difficulty': 'hard',
        'target_value': 3,
        'xp_reward': 200,
        'expires_at': endOfDay.toIso8601String(),
      },
    ];
  }
}
