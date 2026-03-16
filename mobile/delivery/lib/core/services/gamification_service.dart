import 'package:flutter/material.dart';
import 'package:riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Type de badge
enum BadgeType {
  deliveries,    // Nombre de livraisons
  distance,      // Distance parcourue
  speed,         // Rapidité
  rating,        // Note moyenne
  streak,        // Série de jours
  earnings,      // Gains totaux
  special,       // Événements spéciaux
}

/// Rareté du badge
enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Badge
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconAsset;
  final BadgeType type;
  final BadgeRarity rarity;
  final int requirement;
  final int xpReward;
  final DateTime? unlockedAt;
  final double progress;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.type,
    required this.rarity,
    required this.requirement,
    this.xpReward = 100,
    this.unlockedAt,
    this.progress = 0,
  });

  bool get isUnlocked => unlockedAt != null;

  Badge copyWith({
    DateTime? unlockedAt,
    double? progress,
  }) {
    return Badge(
      id: id,
      name: name,
      description: description,
      iconAsset: iconAsset,
      type: type,
      rarity: rarity,
      requirement: requirement,
      xpReward: xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
    );
  }

  Color get rarityColor {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.uncommon:
        return Colors.green;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.orange;
    }
  }

  String get rarityName {
    switch (rarity) {
      case BadgeRarity.common:
        return 'Commun';
      case BadgeRarity.uncommon:
        return 'Peu commun';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Épique';
      case BadgeRarity.legendary:
        return 'Légendaire';
    }
  }
}

/// Niveau du coursier
class CourierLevel {
  final int level;
  final String title;
  final int minXp;
  final int maxXp;
  final List<String> perks;

  const CourierLevel({
    required this.level,
    required this.title,
    required this.minXp,
    required this.maxXp,
    required this.perks,
  });

  double progressToNext(int currentXp) {
    if (currentXp >= maxXp) return 1.0;
    return (currentXp - minXp) / (maxXp - minXp);
  }

  int xpToNext(int currentXp) {
    return maxXp - currentXp;
  }
}

/// Défi quotidien
class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int current;
  final int xpReward;
  final int bonusReward;
  final DateTime expiresAt;
  final bool isCompleted;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    this.current = 0,
    this.xpReward = 50,
    this.bonusReward = 500,
    required this.expiresAt,
    this.isCompleted = false,
  });

  double get progress => (current / target).clamp(0.0, 1.0);

  String get timeRemaining {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expiré';
    if (diff.inHours > 0) return '${diff.inHours}h restantes';
    return '${diff.inMinutes}min restantes';
  }

  DailyChallenge copyWith({
    int? current,
    bool? isCompleted,
  }) {
    return DailyChallenge(
      id: id,
      title: title,
      description: description,
      icon: icon,
      target: target,
      current: current ?? this.current,
      xpReward: xpReward,
      bonusReward: bonusReward,
      expiresAt: expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Série de jours (streak)
class DailyStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastDeliveryDate;
  final List<DateTime> weekHistory;

  const DailyStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastDeliveryDate,
    this.weekHistory = const [],
  });

  bool get isActiveToday {
    if (lastDeliveryDate == null) return false;
    final today = DateTime.now();
    return lastDeliveryDate!.year == today.year &&
        lastDeliveryDate!.month == today.month &&
        lastDeliveryDate!.day == today.day;
  }

  int get streakMultiplier {
    if (currentStreak >= 30) return 3;
    if (currentStreak >= 14) return 2;
    if (currentStreak >= 7) return 1;
    return 0;
  }
}

/// État de gamification
class GamificationState {
  final int totalXp;
  final CourierLevel currentLevel;
  final List<Badge> badges;
  final List<DailyChallenge> dailyChallenges;
  final DailyStreak streak;
  final int totalDeliveries;
  final double totalDistance;
  final double averageRating;
  final double totalEarnings;

  const GamificationState({
    this.totalXp = 0,
    required this.currentLevel,
    this.badges = const [],
    this.dailyChallenges = const [],
    this.streak = const DailyStreak(),
    this.totalDeliveries = 0,
    this.totalDistance = 0,
    this.averageRating = 0,
    this.totalEarnings = 0,
  });

  GamificationState copyWith({
    int? totalXp,
    CourierLevel? currentLevel,
    List<Badge>? badges,
    List<DailyChallenge>? dailyChallenges,
    DailyStreak? streak,
    int? totalDeliveries,
    double? totalDistance,
    double? averageRating,
    double? totalEarnings,
  }) {
    return GamificationState(
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      badges: badges ?? this.badges,
      dailyChallenges: dailyChallenges ?? this.dailyChallenges,
      streak: streak ?? this.streak,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalDistance: totalDistance ?? this.totalDistance,
      averageRating: averageRating ?? this.averageRating,
      totalEarnings: totalEarnings ?? this.totalEarnings,
    );
  }
}

/// Liste des niveaux
const List<CourierLevel> courierLevels = [
  CourierLevel(
    level: 1,
    title: 'Débutant',
    minXp: 0,
    maxXp: 100,
    perks: ['Accès aux livraisons de base'],
  ),
  CourierLevel(
    level: 2,
    title: 'Novice',
    minXp: 100,
    maxXp: 300,
    perks: ['Badge profil visible', 'Statistiques basiques'],
  ),
  CourierLevel(
    level: 3,
    title: 'Apprenti',
    minXp: 300,
    maxXp: 600,
    perks: ['Priorité moyenne', 'Filtres avancés'],
  ),
  CourierLevel(
    level: 4,
    title: 'Coursier',
    minXp: 600,
    maxXp: 1000,
    perks: ['Livraisons premium', 'Support prioritaire'],
  ),
  CourierLevel(
    level: 5,
    title: 'Expert',
    minXp: 1000,
    maxXp: 1500,
    perks: ['Commission réduite -5%', 'Badge Expert'],
  ),
  CourierLevel(
    level: 6,
    title: 'Maître',
    minXp: 1500,
    maxXp: 2500,
    perks: ['Haute priorité', 'Commission réduite -10%'],
  ),
  CourierLevel(
    level: 7,
    title: 'Champion',
    minXp: 2500,
    maxXp: 4000,
    perks: ['Bonus hebdomadaire', 'Accès VIP'],
  ),
  CourierLevel(
    level: 8,
    title: 'Légende',
    minXp: 4000,
    maxXp: 6000,
    perks: ['Max priorité', 'Tous les avantages'],
  ),
  CourierLevel(
    level: 9,
    title: 'Titan',
    minXp: 6000,
    maxXp: 10000,
    perks: ['Statut Elite', 'Commission -15%'],
  ),
  CourierLevel(
    level: 10,
    title: 'Divin',
    minXp: 10000,
    maxXp: 999999,
    perks: ['Rang suprême', 'Tous les bonus max'],
  ),
];

/// Liste des badges
List<Badge> allBadges = [
  // Livraisons
  const Badge(
    id: 'deliveries_10',
    name: 'Premiers Pas',
    description: 'Effectuer 10 livraisons',
    iconAsset: 'assets/badges/delivery_10.png',
    type: BadgeType.deliveries,
    rarity: BadgeRarity.common,
    requirement: 10,
    xpReward: 50,
  ),
  const Badge(
    id: 'deliveries_50',
    name: 'Coursier Actif',
    description: 'Effectuer 50 livraisons',
    iconAsset: 'assets/badges/delivery_50.png',
    type: BadgeType.deliveries,
    rarity: BadgeRarity.uncommon,
    requirement: 50,
    xpReward: 100,
  ),
  const Badge(
    id: 'deliveries_100',
    name: 'Centurion',
    description: 'Effectuer 100 livraisons',
    iconAsset: 'assets/badges/delivery_100.png',
    type: BadgeType.deliveries,
    rarity: BadgeRarity.rare,
    requirement: 100,
    xpReward: 200,
  ),
  const Badge(
    id: 'deliveries_500',
    name: 'Vétéran',
    description: 'Effectuer 500 livraisons',
    iconAsset: 'assets/badges/delivery_500.png',
    type: BadgeType.deliveries,
    rarity: BadgeRarity.epic,
    requirement: 500,
    xpReward: 500,
  ),
  const Badge(
    id: 'deliveries_1000',
    name: 'Millénaire',
    description: 'Effectuer 1000 livraisons',
    iconAsset: 'assets/badges/delivery_1000.png',
    type: BadgeType.deliveries,
    rarity: BadgeRarity.legendary,
    requirement: 1000,
    xpReward: 1000,
  ),
  
  // Distance
  const Badge(
    id: 'distance_100',
    name: 'Explorateur',
    description: 'Parcourir 100 km',
    iconAsset: 'assets/badges/distance_100.png',
    type: BadgeType.distance,
    rarity: BadgeRarity.common,
    requirement: 100,
    xpReward: 50,
  ),
  const Badge(
    id: 'distance_500',
    name: 'Voyageur',
    description: 'Parcourir 500 km',
    iconAsset: 'assets/badges/distance_500.png',
    type: BadgeType.distance,
    rarity: BadgeRarity.rare,
    requirement: 500,
    xpReward: 200,
  ),
  const Badge(
    id: 'distance_1000',
    name: 'Marathon',
    description: 'Parcourir 1000 km',
    iconAsset: 'assets/badges/distance_1000.png',
    type: BadgeType.distance,
    rarity: BadgeRarity.legendary,
    requirement: 1000,
    xpReward: 500,
  ),
  
  // Série
  const Badge(
    id: 'streak_7',
    name: 'Semaine Parfaite',
    description: 'Livrer 7 jours consécutifs',
    iconAsset: 'assets/badges/streak_7.png',
    type: BadgeType.streak,
    rarity: BadgeRarity.uncommon,
    requirement: 7,
    xpReward: 100,
  ),
  const Badge(
    id: 'streak_30',
    name: 'Mois Incroyable',
    description: 'Livrer 30 jours consécutifs',
    iconAsset: 'assets/badges/streak_30.png',
    type: BadgeType.streak,
    rarity: BadgeRarity.epic,
    requirement: 30,
    xpReward: 300,
  ),
  
  // Note
  const Badge(
    id: 'rating_perfect',
    name: 'Étoile Brillante',
    description: 'Maintenir une note de 5.0',
    iconAsset: 'assets/badges/rating_5.png',
    type: BadgeType.rating,
    rarity: BadgeRarity.rare,
    requirement: 5,
    xpReward: 200,
  ),
  
  // Spéciaux
  const Badge(
    id: 'first_delivery',
    name: 'Première Livraison',
    description: 'Compléter votre première livraison',
    iconAsset: 'assets/badges/first.png',
    type: BadgeType.special,
    rarity: BadgeRarity.common,
    requirement: 1,
    xpReward: 25,
  ),
  const Badge(
    id: 'night_owl',
    name: 'Hibou Nocturne',
    description: 'Effectuer 10 livraisons après 22h',
    iconAsset: 'assets/badges/night.png',
    type: BadgeType.special,
    rarity: BadgeRarity.uncommon,
    requirement: 10,
    xpReward: 100,
  ),
  const Badge(
    id: 'speed_demon',
    name: 'Éclair',
    description: 'Compléter 5 livraisons en moins de 10 min',
    iconAsset: 'assets/badges/speed.png',
    type: BadgeType.speed,
    rarity: BadgeRarity.rare,
    requirement: 5,
    xpReward: 150,
  ),
];

/// Service de gamification
class GamificationService extends StateNotifier<GamificationState> {
  late Box _gamificationBox;
  
  GamificationService() : super(GamificationState(
    currentLevel: courierLevels.first,
  )) {
    _init();
  }

  Future<void> _init() async {
    _gamificationBox = await Hive.openBox('gamification');
    await _loadState();
    await _generateDailyChallenges();
  }

  Future<void> _loadState() async {
    final totalXp = _gamificationBox.get('totalXp', defaultValue: 0) as int;
    final unlockedBadges = _gamificationBox.get('unlockedBadges', defaultValue: <String>[]) as List;
    final streakData = _gamificationBox.get('streak') as Map?;
    
    final level = _getLevelForXp(totalXp);
    
    // Mettre à jour les badges avec leur statut
    final badges = allBadges.map((badge) {
      if (unlockedBadges.contains(badge.id)) {
        return badge.copyWith(unlockedAt: DateTime.now());
      }
      return badge;
    }).toList();
    
    DailyStreak streak = const DailyStreak();
    if (streakData != null) {
      streak = DailyStreak(
        currentStreak: streakData['current'] ?? 0,
        longestStreak: streakData['longest'] ?? 0,
        lastDeliveryDate: streakData['lastDate'] != null 
            ? DateTime.parse(streakData['lastDate']) 
            : null,
      );
    }
    
    state = state.copyWith(
      totalXp: totalXp,
      currentLevel: level,
      badges: badges,
      streak: streak,
      totalDeliveries: _gamificationBox.get('totalDeliveries', defaultValue: 0),
      totalDistance: _gamificationBox.get('totalDistance', defaultValue: 0.0),
      averageRating: _gamificationBox.get('averageRating', defaultValue: 0.0),
      totalEarnings: _gamificationBox.get('totalEarnings', defaultValue: 0.0),
    );
  }

  CourierLevel _getLevelForXp(int xp) {
    for (int i = courierLevels.length - 1; i >= 0; i--) {
      if (xp >= courierLevels[i].minXp) {
        return courierLevels[i];
      }
    }
    return courierLevels.first;
  }

  Future<void> _generateDailyChallenges() async {
    final today = DateTime.now();
    final lastGenDate = _gamificationBox.get('lastChallengeDate');
    
    if (lastGenDate != null && 
        DateTime.parse(lastGenDate).day == today.day) {
      // Charger les défis existants
      final savedChallenges = _gamificationBox.get('dailyChallenges') as List?;
      if (savedChallenges != null) {
        // Restaurer les défis
        return;
      }
    }
    
    // Générer de nouveaux défis
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final challenges = [
      DailyChallenge(
        id: 'daily_deliveries',
        title: 'Coursier Actif',
        description: 'Effectuer 5 livraisons aujourd\'hui',
        icon: Icons.delivery_dining,
        target: 5,
        xpReward: 50,
        bonusReward: 1000,
        expiresAt: endOfDay,
      ),
      DailyChallenge(
        id: 'daily_distance',
        title: 'Sur la Route',
        description: 'Parcourir 20 km aujourd\'hui',
        icon: Icons.route,
        target: 20,
        xpReward: 40,
        bonusReward: 500,
        expiresAt: endOfDay,
      ),
      DailyChallenge(
        id: 'daily_speed',
        title: 'Flash',
        description: 'Compléter une livraison en moins de 15 min',
        icon: Icons.bolt,
        target: 1,
        xpReward: 30,
        bonusReward: 300,
        expiresAt: endOfDay,
      ),
    ];
    
    state = state.copyWith(dailyChallenges: challenges);
    await _gamificationBox.put('lastChallengeDate', today.toIso8601String());
  }

  /// Ajouter de l'XP
  Future<void> addXp(int amount, {String? reason}) async {
    final newXp = state.totalXp + amount;
    final newLevel = _getLevelForXp(newXp);
    
    await _gamificationBox.put('totalXp', newXp);
    
    state = state.copyWith(
      totalXp: newXp,
      currentLevel: newLevel,
    );
    
    // Vérifier si niveau supérieur
    if (newLevel.level > state.currentLevel.level) {
      // Notifier le niveau supérieur
    }
  }

  /// Enregistrer une livraison
  Future<void> recordDelivery({
    required double distance,
    required double earnings,
    required int durationMinutes,
    double? rating,
  }) async {
    // Mettre à jour les statistiques
    final newDeliveries = state.totalDeliveries + 1;
    final newDistance = state.totalDistance + distance;
    final newEarnings = state.totalEarnings + earnings;
    
    await _gamificationBox.put('totalDeliveries', newDeliveries);
    await _gamificationBox.put('totalDistance', newDistance);
    await _gamificationBox.put('totalEarnings', newEarnings);
    
    if (rating != null) {
      final newRating = (state.averageRating * (newDeliveries - 1) + rating) / newDeliveries;
      await _gamificationBox.put('averageRating', newRating);
    }
    
    // Mettre à jour la série
    await _updateStreak();
    
    // XP de base
    int xpEarned = 10;
    
    // Bonus streak
    if (state.streak.streakMultiplier > 0) {
      xpEarned += state.streak.streakMultiplier * 5;
    }
    
    // Bonus rapidité
    if (durationMinutes < 15) {
      xpEarned += 5;
    }
    
    await addXp(xpEarned);
    
    // Mettre à jour les défis
    await _updateChallenges(distance: distance, durationMinutes: durationMinutes);
    
    // Vérifier les badges
    await _checkBadges();
    
    state = state.copyWith(
      totalDeliveries: newDeliveries,
      totalDistance: newDistance,
      totalEarnings: newEarnings,
    );
  }

  Future<void> _updateStreak() async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    int newStreak = state.streak.currentStreak;
    
    if (state.streak.lastDeliveryDate == null) {
      newStreak = 1;
    } else {
      final lastDate = state.streak.lastDeliveryDate!;
      
      // Même jour
      if (lastDate.year == today.year &&
          lastDate.month == today.month &&
          lastDate.day == today.day) {
        return;
      }
      
      // Jour consécutif
      if (lastDate.year == yesterday.year &&
          lastDate.month == yesterday.month &&
          lastDate.day == yesterday.day) {
        newStreak++;
      } else {
        // Série brisée
        newStreak = 1;
      }
    }
    
    final longestStreak = newStreak > state.streak.longestStreak 
        ? newStreak 
        : state.streak.longestStreak;
    
    final newStreakData = {
      'current': newStreak,
      'longest': longestStreak,
      'lastDate': today.toIso8601String(),
    };
    
    await _gamificationBox.put('streak', newStreakData);
    
    state = state.copyWith(
      streak: DailyStreak(
        currentStreak: newStreak,
        longestStreak: longestStreak,
        lastDeliveryDate: today,
      ),
    );
  }

  Future<void> _updateChallenges({
    required double distance,
    required int durationMinutes,
  }) async {
    final updatedChallenges = state.dailyChallenges.map((challenge) {
      if (challenge.isCompleted) return challenge;
      
      int newCurrent = challenge.current;
      
      switch (challenge.id) {
        case 'daily_deliveries':
          newCurrent++;
          break;
        case 'daily_distance':
          newCurrent += distance.round();
          break;
        case 'daily_speed':
          if (durationMinutes < 15) newCurrent++;
          break;
      }
      
      final isCompleted = newCurrent >= challenge.target;
      
      if (isCompleted && !challenge.isCompleted) {
        addXp(challenge.xpReward);
      }
      
      return challenge.copyWith(
        current: newCurrent,
        isCompleted: isCompleted,
      );
    }).toList();
    
    state = state.copyWith(dailyChallenges: updatedChallenges);
  }

  Future<void> _checkBadges() async {
    final unlockedBadges = List<String>.from(
      _gamificationBox.get('unlockedBadges', defaultValue: <String>[]) as List
    );
    
    final updatedBadges = state.badges.map((badge) {
      if (badge.isUnlocked) return badge;
      
      double progress = 0;
      bool shouldUnlock = false;
      
      switch (badge.type) {
        case BadgeType.deliveries:
          progress = state.totalDeliveries / badge.requirement;
          shouldUnlock = state.totalDeliveries >= badge.requirement;
          break;
        case BadgeType.distance:
          progress = state.totalDistance / badge.requirement;
          shouldUnlock = state.totalDistance >= badge.requirement;
          break;
        case BadgeType.streak:
          progress = state.streak.currentStreak / badge.requirement;
          shouldUnlock = state.streak.currentStreak >= badge.requirement;
          break;
        case BadgeType.rating:
          progress = state.averageRating / badge.requirement;
          shouldUnlock = state.averageRating >= badge.requirement;
          break;
        default:
          break;
      }
      
      if (shouldUnlock && !unlockedBadges.contains(badge.id)) {
        unlockedBadges.add(badge.id);
        addXp(badge.xpReward);
        return badge.copyWith(
          unlockedAt: DateTime.now(),
          progress: 1.0,
        );
      }
      
      return badge.copyWith(progress: progress.clamp(0.0, 1.0));
    }).toList();
    
    await _gamificationBox.put('unlockedBadges', unlockedBadges);
    
    state = state.copyWith(badges: updatedBadges);
  }

  /// Obtenir les badges par type
  List<Badge> getBadgesByType(BadgeType type) {
    return state.badges.where((b) => b.type == type).toList();
  }

  /// Obtenir le prochain badge à débloquer
  Badge? getNextBadgeToUnlock() {
    final lockedBadges = state.badges.where((b) => !b.isUnlocked).toList();
    if (lockedBadges.isEmpty) return null;
    
    lockedBadges.sort((a, b) => b.progress.compareTo(a.progress));
    return lockedBadges.first;
  }

  /// Réinitialiser pour tests
  Future<void> reset() async {
    await _gamificationBox.clear();
    state = GamificationState(currentLevel: courierLevels.first);
  }
}

/// Provider pour le service
final gamificationServiceProvider = StateNotifierProvider<GamificationService, GamificationState>((ref) {
  return GamificationService();
});
