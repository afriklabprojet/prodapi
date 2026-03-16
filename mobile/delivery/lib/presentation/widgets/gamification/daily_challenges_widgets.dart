import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/gamification.dart';
import '../../../data/repositories/gamification_repository.dart';
import '../../../core/theme/theme_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CARTE DE DÉFI QUOTIDIEN ANIMÉE
// ══════════════════════════════════════════════════════════════════════════════

/// Carte de défi quotidien avec animation et progression
class DailyChallengeCard extends StatefulWidget {
  final DailyChallenge challenge;
  final VoidCallback? onClaim;
  final bool isCompact;

  const DailyChallengeCard({
    super.key,
    required this.challenge,
    this.onClaim,
    this.isCompact = false,
  });

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.challenge.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(DailyChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.currentValue != widget.challenge.currentValue) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.challenge.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final challenge = widget.challenge;
    final color = challenge.difficulty.color;

    if (widget.isCompact) {
      return _buildCompactCard(isDark, challenge, color);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: challenge.isCompleted ? 0 : 2,
            color: challenge.isCompleted
                ? (isDark ? Colors.green.shade900 : Colors.green.shade50)
                : (isDark ? Colors.grey.shade900 : Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: challenge.isCompleted
                    ? Colors.green.shade400
                    : color.withValues(alpha: 0.3),
                width: challenge.isCompleted ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: challenge.isCompleted && !challenge.isClaimed
                  ? widget.onClaim
                  : null,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        // Icône avec animation
                        _AnimatedChallengeIcon(
                          icon: challenge.icon,
                          color: color,
                          isCompleted: challenge.isCompleted,
                        ),
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge difficulté
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  challenge.difficulty.label,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                challenge.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: challenge.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Récompenses
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+${challenge.xpReward} XP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (challenge.bonusReward != null)
                              Text(
                                '+${challenge.bonusReward} F',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade600,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      challenge.description,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Barre de progression animée
                    _buildProgressBar(isDark, challenge, color),
                    
                    const SizedBox(height: 8),
                    
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Progression textuelle
                        Text(
                          '${challenge.currentValue} / ${challenge.targetValue}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                        
                        // Timer ou bouton claim
                        if (challenge.isCompleted && !challenge.isClaimed)
                          _ClaimButton(onClaim: widget.onClaim)
                        else if (challenge.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle, 
                                    color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Terminé',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: challenge.timeRemaining.inHours < 2
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                challenge.timeRemainingLabel,
                                style: TextStyle(
                                  color: challenge.timeRemaining.inHours < 2
                                      ? Colors.red
                                      : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactCard(bool isDark, DailyChallenge challenge, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(challenge.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: challenge.progress,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${challenge.xpReward}',
            style: TextStyle(
              color: Colors.amber.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark, DailyChallenge challenge, Color color) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  // Fond
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Progression
                  FractionallySizedBox(
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Icône animée pour les défis
class _AnimatedChallengeIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool isCompleted;

  const _AnimatedChallengeIcon({
    required this.icon,
    required this.color,
    required this.isCompleted,
  });

  @override
  State<_AnimatedChallengeIcon> createState() => _AnimatedChallengeIconState();
}

class _AnimatedChallengeIconState extends State<_AnimatedChallengeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    if (widget.isCompleted) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_AnimatedChallengeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _controller.repeat();
    } else if (!widget.isCompleted && oldWidget.isCompleted) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.isCompleted
                ? Colors.green
                : widget.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isCompleted
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(
                        alpha: 0.3 + (_controller.value * 0.3),
                      ),
                      blurRadius: 8 + (_controller.value * 8),
                      spreadRadius: _controller.value * 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.isCompleted ? Icons.check : widget.icon,
            color: widget.isCompleted ? Colors.white : widget.color,
            size: 24,
          ),
        );
      },
    );
  }
}

/// Bouton de réclamation animé
class _ClaimButton extends StatefulWidget {
  final VoidCallback? onClaim;

  const _ClaimButton({this.onClaim});

  @override
  State<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<_ClaimButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_controller.value * 0.05),
          child: ElevatedButton(
            onPressed: widget.onClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 2 + (_controller.value * 4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.celebration, size: 16),
                SizedBox(width: 6),
                Text('Réclamer', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET DÉFIS QUOTIDIENS POUR HOME
// ══════════════════════════════════════════════════════════════════════════════

/// Widget compact pour l'écran d'accueil montrant les défis
class DailyChallengesHomeWidget extends ConsumerWidget {
  final VoidCallback? onSeeAll;

  const DailyChallengesHomeWidget({super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final challengesAsync = ref.watch(dailyChallengesProvider);

    return challengesAsync.when(
      data: (data) => _buildContent(context, ref, isDark, data),
      loading: () => _buildSkeleton(isDark),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    DailyChallengesData data,
  ) {
    final activeChallenges = data.activeChallenges.take(3).toList();
    if (activeChallenges.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.amber],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Défis du jour',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${data.completedToday}/${data.challenges.length} terminés',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Streak badge
                if (data.currentStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.whatshot,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data.currentStreak}j',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Liste des défis
            ...activeChallenges.map((challenge) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DailyChallengeCard(
                challenge: challenge,
                isCompact: true,
                onClaim: () {
                  ref.read(gamificationRepositoryProvider)
                      .claimChallengeReward(challenge.id);
                  ref.invalidate(dailyChallengesProvider);
                },
              ),
            )),
            
            // Bouton voir tout
            if (data.challenges.length > 3)
              Center(
                child: TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'Voir tous les défis (${data.challenges.length})',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TIMER DE RAFRAÎCHISSEMENT
// ══════════════════════════════════════════════════════════════════════════════

/// Widget affichant le temps jusqu'au prochain rafraîchissement
class ChallengeRefreshTimer extends StatefulWidget {
  final DateTime? nextRefresh;

  const ChallengeRefreshTimer({super.key, this.nextRefresh});

  @override
  State<ChallengeRefreshTimer> createState() => _ChallengeRefreshTimerState();
}

class _ChallengeRefreshTimerState extends State<ChallengeRefreshTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    if (widget.nextRefresh == null) return;
    setState(() {
      _remaining = widget.nextRefresh!.difference(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nextRefresh == null) return const SizedBox.shrink();

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Text(
            'Nouveaux défis dans ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ÉCRAN COMPLET DES DÉFIS
// ══════════════════════════════════════════════════════════════════════════════

/// Écran complet affichant tous les défis quotidiens
class DailyChallengesScreen extends ConsumerWidget {
  const DailyChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final challengesAsync = ref.watch(dailyChallengesProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Défis quotidiens'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: challengesAsync.when(
        data: (data) => _buildContent(context, ref, isDark, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Erreur: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(dailyChallengesProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    DailyChallengesData data,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // En-tête avec stats
        _buildStatsHeader(isDark, data),
        const SizedBox(height: 16),
        
        // Timer de rafraîchissement
        Center(child: ChallengeRefreshTimer(nextRefresh: data.nextRefresh)),
        const SizedBox(height: 24),
        
        // À réclamer
        if (data.claimableChallenges.isNotEmpty) ...[
          _buildSectionHeader('À réclamer', Icons.celebration, Colors.amber),
          ...data.claimableChallenges.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DailyChallengeCard(
              challenge: c,
              onClaim: () {
                ref.read(gamificationRepositoryProvider)
                    .claimChallengeReward(c.id);
                ref.invalidate(dailyChallengesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 +${c.xpReward} XP réclamés !'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          )),
          const SizedBox(height: 16),
        ],
        
        // En cours
        _buildSectionHeader('En cours', Icons.pending_actions, Colors.blue),
        ...data.activeChallenges
            .where((c) => !c.isCompleted)
            .map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DailyChallengeCard(challenge: c),
            )),
        
        const SizedBox(height: 16),
        
        // Terminés
        if (data.completedChallenges.isNotEmpty) ...[
          _buildSectionHeader('Terminés', Icons.check_circle, Colors.green),
          ...data.completedChallenges
              .where((c) => c.isClaimed)
              .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DailyChallengeCard(challenge: c),
              )),
        ],
      ],
    );
  }

  Widget _buildStatsHeader(bool isDark, DailyChallengesData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.amber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Streak
          Expanded(
            child: _buildStatItem(
              Icons.whatshot,
              '${data.currentStreak}',
              'Jour(s) de suite',
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white30,
          ),
          // XP aujourd'hui
          Expanded(
            child: _buildStatItem(
              Icons.auto_awesome,
              '+${data.totalXpEarnedToday}',
              'XP aujourd\'hui',
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white30,
          ),
          // Complétés
          Expanded(
            child: _buildStatItem(
              Icons.check_circle,
              '${data.completedToday}/${data.challenges.length}',
              'Complétés',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
