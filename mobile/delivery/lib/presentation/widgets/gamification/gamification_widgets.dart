import 'package:flutter/material.dart';
import '../../../data/models/gamification.dart';

/// Widget affichant le niveau et la barre de progression XP
class LevelProgressWidget extends StatelessWidget {
  final CourierLevel level;
  final bool showDetails;
  final VoidCallback? onTap;

  const LevelProgressWidget({
    super.key,
    required this.level,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              level.color.withValues(alpha: isDark ? 0.3 : 0.15),
              level.color.withValues(alpha: isDark ? 0.1 : 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: level.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icône de niveau
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: level.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: level.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(level.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                
                // Titre et niveau
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Niveau ${level.level}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        level.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // XP total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${level.totalXP} XP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: level.color,
                      ),
                    ),
                    if (showDetails)
                      Text(
                        '${level.xpToNextLevel} XP restants',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            if (showDetails) ...[
              const SizedBox(height: 12),
              
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: level.progress,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(level.color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              
              // Labels XP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${level.currentXP} / ${level.requiredXP} XP',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${(level.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: level.color,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget compact pour afficher le niveau
class LevelBadgeCompact extends StatelessWidget {
  final CourierLevel level;

  const LevelBadgeCompact({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: level.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, color: level.color, size: 16),
          const SizedBox(width: 6),
          Text(
            'Niv. ${level.level}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: level.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget affichant une grille de badges
class BadgesGridWidget extends StatelessWidget {
  final List<GamificationBadge> badges;
  final int crossAxisCount;
  final bool showLocked;
  final VoidCallback? onSeeAll;

  const BadgesGridWidget({
    super.key,
    required this.badges,
    this.crossAxisCount = 4,
    this.showLocked = true,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final displayBadges = showLocked 
        ? badges 
        : badges.where((b) => b.isUnlocked).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Badges (${badges.where((b) => b.isUnlocked).length}/${badges.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: displayBadges.length,
          itemBuilder: (context, index) {
            return BadgeWidget(badge: displayBadges[index]);
          },
        ),
      ],
    );
  }
}

/// Widget individuel pour un badge
class BadgeWidget extends StatelessWidget {
  final GamificationBadge badge;
  final double size;
  final bool showProgress;

  const BadgeWidget({
    super.key,
    required this.badge,
    this.size = 64,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Cercle de fond avec progression
              if (showProgress && !badge.isUnlocked)
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: badge.progress,
                    strokeWidth: 3,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(badge.color.withValues(alpha: 0.5)),
                  ),
                ),
              
              // Badge
              Container(
                width: size - (showProgress && !badge.isUnlocked ? 8 : 0),
                height: size - (showProgress && !badge.isUnlocked ? 8 : 0),
                decoration: BoxDecoration(
                  color: badge.isUnlocked 
                      ? badge.color.withValues(alpha: 0.15)
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badge.isUnlocked 
                        ? badge.color 
                        : (isDark ? Colors.white24 : Colors.grey.shade300),
                    width: 2,
                  ),
                  boxShadow: badge.isUnlocked ? [
                    BoxShadow(
                      color: badge.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Icon(
                  badge.icon,
                  color: badge.isUnlocked 
                      ? badge.color 
                      : (isDark ? Colors.white38 : Colors.grey.shade400),
                  size: size * 0.4,
                ),
              ),
              
              // Icône de verrouillage
              if (!badge.isUnlocked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 12,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: badge.isUnlocked ? FontWeight.w600 : FontWeight.normal,
              color: badge.isUnlocked 
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white38 : Colors.grey),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: badge.isUnlocked 
                    ? badge.color.withValues(alpha: 0.15)
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
                shape: BoxShape.circle,
                border: Border.all(color: badge.color, width: 3),
              ),
              child: Icon(
                badge.icon,
                color: badge.isUnlocked ? badge.color : Colors.grey,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            if (!badge.isUnlocked) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: badge.progress,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${badge.currentValue} / ${badge.requiredValue}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: badge.color,
                ),
              ),
            ],
            if (badge.isUnlocked && badge.unlockedAt != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Débloqué',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

/// Widget pour le classement (leaderboard)
class LeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? currentUser;
  final String title;
  final VoidCallback? onSeeAll;

  const LeaderboardWidget({
    super.key,
    required this.entries,
    this.currentUser,
    this.title = 'Classement',
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Podium (top 3)
        if (entries.length >= 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2ème place
                _PodiumItem(entry: entries[1], height: 80),
                const SizedBox(width: 8),
                // 1ère place
                _PodiumItem(entry: entries[0], height: 100, isFirst: true),
                const SizedBox(width: 8),
                // 3ème place
                _PodiumItem(entry: entries[2], height: 60),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Liste des autres
        ...entries.skip(3).take(7).map((entry) => _LeaderboardRow(entry: entry)),
        
        // Position de l'utilisateur actuel
        if (currentUser != null && (currentUser!.rank > 10))
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('• • •', style: TextStyle(color: Colors.grey)),
              ),
              _LeaderboardRow(entry: currentUser!, highlight: true),
            ],
          ),
      ],
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final bool isFirst;

  const _PodiumItem({
    required this.entry,
    required this.height,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CircleAvatar(
              radius: isFirst ? 32 : 24,
              backgroundColor: entry.rankColor,
              child: Text(
                entry.courierName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isFirst ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (entry.rankIcon != null)
              Positioned(
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: entry.rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(entry.rankIcon, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          entry.courierName.split(' ').first,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isFirst ? 14 : 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${entry.score} pts',
          style: TextStyle(
            color: entry.rankColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        // Podium bar
        Container(
          width: isFirst ? 70 : 60,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                entry.rankColor,
                entry.rankColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool highlight;

  const _LeaderboardRow({
    required this.entry,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight 
            ? Colors.blue.withValues(alpha: 0.1)
            : (entry.isCurrentUser 
                ? Colors.blue.withValues(alpha: 0.1)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50)),
        borderRadius: BorderRadius.circular(12),
        border: (highlight || entry.isCurrentUser)
            ? Border.all(color: Colors.blue.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          // Rang
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: entry.rank <= 3 ? entry.rankColor : Colors.grey,
              ),
            ),
          ),
          
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            child: Text(
              entry.courierName.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          
          // Nom
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.courierName,
                  style: TextStyle(
                    fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '${entry.deliveriesCount} livraisons',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'pts',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
