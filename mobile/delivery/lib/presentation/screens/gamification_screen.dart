import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../data/models/gamification.dart';
import '../widgets/gamification/gamification_widgets.dart';
import '../widgets/gamification/daily_challenges_widgets.dart';
import '../widgets/common/common_widgets.dart';
import '../../core/utils/responsive.dart';

class GamificationScreen extends ConsumerStatefulWidget {
  const GamificationScreen({super.key});

  @override
  ConsumerState<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends ConsumerState<GamificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _leaderboardPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final isDark = context.isDark;
    final gamificationAsync = ref.watch(gamificationProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      body: gamificationAsync.when(
        data: (data) => _buildContent(context, data),
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(gamificationProvider),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GamificationData data) {
    final isDark = context.isDark;
    
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // Header avec niveau
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    data.level.color.withValues(alpha: 0.9),
                    data.level.color.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progression',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.r.sp(28),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Streak badge
                        if (data.stats['current_streak'] != null && data.stats['current_streak']! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '${data.stats['current_streak']} jours',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Niveau card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Icône niveau
                          Container(
                            width: context.r.dp(60),
                            height: context.r.dp(60),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              data.level.icon,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Info niveau
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Niveau ${data.level.level}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  data.level.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Barre XP
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: data.level.progress,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data.level.currentXP} / ${data.level.requiredXP} XP',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // XP total
                          Column(
                            children: [
                              Text(
                                '${data.level.totalXP}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.r.sp(24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'XP Total',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Stats row
                    Row(
                      children: [
                        _StatCard(
                          icon: Icons.local_shipping,
                          value: '${data.stats['total_deliveries'] ?? 0}',
                          label: 'Livraisons',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.verified,
                          value: '${data.unlockedBadges.length}/${data.badges.length}',
                          label: 'Badges',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.leaderboard,
                          value: '#${data.currentUserRank?.rank ?? '-'}',
                          label: 'Classement',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Daily Challenges Section
          SliverToBoxAdapter(
            child: DailyChallengesHomeWidget(
              onSeeAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DailyChallengesScreen(),
                  ),
                );
              },
            ),
          ),
          
          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: isDark ? Colors.white : Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: data.level.color,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.military_tech), text: 'Badges'),
                  Tab(icon: Icon(Icons.leaderboard), text: 'Classement'),
                  Tab(icon: Icon(Icons.history), text: 'Historique'),
                ],
              ),
              isDark: isDark,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Badges
          _BadgesTab(badges: data.badges),
          
          // Onglet Classement
          _LeaderboardTab(
            leaderboard: data.leaderboard,
            currentUser: data.currentUserRank,
            period: _leaderboardPeriod,
            onPeriodChanged: (period) {
              setState(() => _leaderboardPeriod = period);
              ref.invalidate(leaderboardProvider(_leaderboardPeriod));
            },
          ),
          
          // Onglet Historique XP
          _XPHistoryTab(stats: data.stats),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this.tabBar, {required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || isDark != oldDelegate.isDark;
  }
}

class _BadgesTab extends StatelessWidget {
  final List<GamificationBadge> badges;

  const _BadgesTab({required this.badges});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categorized = <String, List<GamificationBadge>>{};
    
    for (final badge in badges) {
      categorized.putIfAbsent(badge.category, () => []).add(badge);
    }

    final categoryNames = {
      'deliveries': '🚚 Livraisons',
      'speed': '⚡ Rapidité',
      'rating': '⭐ Satisfaction',
      'streak': '🔥 Régularité',
      'general': '🏆 Général',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Récapitulatif
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BadgeCountItem(
                count: badges.where((b) => b.isUnlocked).length,
                total: badges.length,
                label: 'Débloqués',
                color: Colors.green,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              _BadgeCountItem(
                count: badges.where((b) => !b.isUnlocked && b.progress > 0.5).length,
                total: badges.where((b) => !b.isUnlocked).length,
                label: 'En cours',
                color: Colors.orange,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              _BadgeCountItem(
                count: badges.where((b) => !b.isUnlocked && b.progress == 0).length,
                total: badges.length,
                label: 'À découvrir',
                color: Colors.grey,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Badges par catégorie
        ...categorized.entries.map((entry) {
          final categoryBadges = entry.value;
          final unlockedCount = categoryBadges.where((b) => b.isUnlocked).length;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    categoryNames[entry.key] ?? entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$unlockedCount/${categoryBadges.length}',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: categoryBadges.length,
                itemBuilder: (context, index) {
                  return BadgeWidget(badge: categoryBadges[index]);
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        }),
      ],
    );
  }
}

class _BadgeCountItem extends StatelessWidget {
  final int count;
  final int total;
  final String label;
  final Color color;

  const _BadgeCountItem({
    required this.count,
    required this.total,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: context.r.sp(24),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final List<LeaderboardEntry> leaderboard;
  final LeaderboardEntry? currentUser;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  const _LeaderboardTab({
    required this.leaderboard,
    this.currentUser,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sélecteur de période
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _PeriodChip(
                label: 'Semaine',
                isSelected: period == 'week',
                onTap: () => onPeriodChanged('week'),
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: 'Mois',
                isSelected: period == 'month',
                onTap: () => onPeriodChanged('month'),
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: 'Tous les temps',
                isSelected: period == 'all',
                onTap: () => onPeriodChanged('all'),
              ),
            ],
          ),
        ),
        
        // Liste du classement
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (leaderboard.isNotEmpty)
                LeaderboardWidget(
                  entries: leaderboard,
                  currentUser: currentUser,
                  title: '',
                ),
              
              if (leaderboard.isEmpty)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Classement non disponible',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue 
              : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : (isDark ? Colors.white70 : Colors.grey.shade700),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _XPHistoryTab extends StatelessWidget {
  final Map<String, int> stats;

  const _XPHistoryTab({required this.stats});

  Color _getLevelColor(String? colorStr) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Liste des sources de XP
    final xpSources = [
      {'icon': Icons.local_shipping, 'name': 'Livraison complétée', 'xp': 10},
      {'icon': Icons.thumb_up, 'name': 'Note 5 étoiles', 'xp': 5},
      {'icon': Icons.speed, 'name': 'Livraison rapide (<15 min)', 'xp': 3},
      {'icon': Icons.verified, 'name': 'Défi complété', 'xp': 50},
      {'icon': Icons.military_tech, 'name': 'Badge débloqué', 'xp': 25},
      {'icon': Icons.whatshot, 'name': 'Streak journalier', 'xp': 2},
    ];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Comment gagner des XP
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Comment gagner des XP ?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...xpSources.map((source) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        source['icon'] as IconData,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        source['name'] as String,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${source['xp']} XP',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Niveaux à débloquer
        Text(
          'Niveaux',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        ...LevelDefinitions.levels.map((levelDef) {
          final isUnlocked = (stats['total_xp'] ?? 0) >= (levelDef['xp'] as int);
          final levelColor = _getLevelColor(levelDef['color'] as String?);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked 
                  ? Colors.green.withValues(alpha: 0.1)
                  : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
              border: isUnlocked 
                  ? Border.all(color: Colors.green.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? levelColor
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${levelDef['level']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelDef['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${levelDef['xp']} XP requis',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnlocked)
                  const Icon(Icons.check_circle, color: Colors.green)
                else
                  Icon(Icons.lock_outline, color: Colors.grey.shade400),
              ],
            ),
          );
        }),
      ],
    );
  }
}
