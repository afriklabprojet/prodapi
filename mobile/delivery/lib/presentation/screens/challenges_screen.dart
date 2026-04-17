import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/challenge_repository.dart';
import '../widgets/common/common_widgets.dart';
import '../../core/utils/responsive.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);
    // Écouter les changements de thème
    ref.watch(themeProvider);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FD),
      body: AsyncValueWidget<Map<String, dynamic>>(
        value: challengesAsync,
        data: (data) => _ChallengesContent(data: data, ref: ref),
        onRetry: () => ref.invalidate(challengesProvider),
      ),
    );
  }
}

// Provider pour les challenges
final challengesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.read(challengeRepositoryProvider);
  return repo.getChallenges();
});

class _ChallengesContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final WidgetRef ref;

  const _ChallengesContent({required this.data, required this.ref});

  @override
  Widget build(BuildContext context) {
    final challenges = data['challenges'] as Map<String, dynamic>? ?? {};
    final inProgress =
        (challenges['in_progress'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
    final completed =
        (challenges['completed'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rewarded =
        (challenges['rewarded'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final activeBonuses =
        (data['active_bonuses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    return CustomScrollView(
      slivers: [
        // Header avec statistiques
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Défis & Bonus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${stats['rewarded_count'] ?? 0}',
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatBadge(
                        icon: Icons.play_arrow,
                        label: 'En cours',
                        value: '${stats['in_progress_count'] ?? 0}',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        icon: Icons.check_circle,
                        label: 'À réclamer',
                        value: '${stats['can_claim_count'] ?? 0}',
                        color: Colors.green,
                      ),
                      const Spacer(),
                      // Bouton vers Gamification
                      InkWell(
                        onTap: () => context.push(AppRoutes.gamification),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.leaderboard,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Classement',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bonus actifs
        if (activeBonuses.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                '🔥 Bonus Actifs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: activeBonuses.length,
                itemBuilder: (context, index) {
                  final bonus = activeBonuses[index];
                  return _BonusCard(bonus: bonus);
                },
              ),
            ),
          ),
        ],

        // Défis à réclamer
        if (completed.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                '🎉 À Réclamer !',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: _ChallengeCard(
                  challenge: completed[index],
                  canClaim: true,
                  onClaim: () => _claimReward(context, completed[index], ref),
                ),
              ),
              childCount: completed.length,
            ),
          ),
        ],

        // Défis en cours
        if (inProgress.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                '⏳ En Cours',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: _ChallengeCard(challenge: inProgress[index]),
              ),
              childCount: inProgress.length,
            ),
          ),
        ],

        // Défis complétés (historique)
        if (rewarded.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Text(
                    '✅ Complétés',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: _ChallengeCard(
                  challenge: rewarded[index],
                  isRewarded: true,
                ),
              ),
              childCount: rewarded.length,
            ),
          ),
        ],

        // Empty state
        if (inProgress.isEmpty && completed.isEmpty && rewarded.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun défi disponible',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Future<void> _claimReward(
    BuildContext context,
    Map<String, dynamic> challenge,
    WidgetRef ref,
  ) async {
    final challengeId = challenge['id'];
    if (challengeId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identifiant du défi invalide.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final repo = ref.read(challengeRepositoryProvider);
      final result = await repo.claimReward(challengeId as int);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${result['reward_amount']} FCFA',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result['message'] ?? 'Bonus ajouté à votre wallet !',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.invalidate(challengesProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Super !'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BonusCard extends StatelessWidget {
  final Map<String, dynamic> bonus;

  const _BonusCard({required this.bonus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.r.dp(200),
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  bonus['name'] ?? 'Bonus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bonus['description'] ?? '',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final bool canClaim;
  final bool isRewarded;
  final VoidCallback? onClaim;

  const _ChallengeCard({
    required this.challenge,
    this.canClaim = false,
    this.isRewarded = false,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "fr_FR");
    final progress = (challenge['progress_percent'] ?? 0).toDouble();
    final currentProgress = challenge['current_progress'] ?? 0;
    final targetValue = challenge['target_value'] ?? 1;
    final rewardAmount = challenge['reward_amount'] ?? 0;
    final colorName = challenge['color'] ?? 'amber';
    final color = _getColor(colorName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: canClaim ? Border.all(color: Colors.green, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isRewarded
                      ? Colors.grey.shade100
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(challenge['icon']),
                  color: isRewarded ? Colors.grey : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge['title'] ?? 'Défi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isRewarded ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isRewarded
                                ? Colors.grey.shade100
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${currencyFormat.format(rewardAmount)} F',
                            style: TextStyle(
                              color: isRewarded
                                  ? Colors.grey
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge['description'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isRewarded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        canClaim ? Colors.green : color,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$currentProgress / $targetValue',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: canClaim ? Colors.green : Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          if (canClaim && onClaim != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onClaim,
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: const Text('Réclamer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          if (isRewarded) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.grey.shade400, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Réclamé',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor(String colorName) {
    return switch (colorName) {
      'amber' => Colors.amber.shade700,
      'blue' => Colors.blue.shade600,
      'green' => Colors.green.shade600,
      'orange' => Colors.orange.shade700,
      'purple' => Colors.purple.shade600,
      'red' => Colors.red.shade600,
      'teal' => Colors.teal.shade600,
      _ => Colors.amber.shade700,
    };
  }

  IconData _getIcon(String? iconName) {
    return switch (iconName) {
      'star' => Icons.star,
      'local_fire_department' => Icons.local_fire_department,
      'speed' => Icons.speed,
      'emoji_events' => Icons.emoji_events,
      'calendar_today' => Icons.calendar_today,
      'rocket_launch' => Icons.rocket_launch,
      'military_tech' => Icons.military_tech,
      'workspace_premium' => Icons.workspace_premium,
      _ => Icons.star,
    };
  }
}
