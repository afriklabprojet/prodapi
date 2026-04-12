import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/loyalty_entity.dart';
import '../providers/loyalty_provider.dart';

class LoyaltyPage extends ConsumerStatefulWidget {
  const LoyaltyPage({super.key});

  @override
  ConsumerState<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends ConsumerState<LoyaltyPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(loyaltyProvider.notifier).loadLoyalty();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programme Fidélité'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(loyaltyProvider.notifier).loadLoyalty(),
        child: loyaltyState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : loyaltyState.hasData
            ? _buildContent(loyaltyState.loyalty!, isDark)
            : _buildEmptyState(isDark),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.card_giftcard,
            size: 80,
            color: Colors.amber.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Programme Fidélité',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Gagnez des points à chaque commande et débloquez des réductions exclusives !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildTierOverview(isDark),
        ],
      ),
    );
  }

  Widget _buildContent(LoyaltyEntity loyalty, bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Tier card
          _buildTierCard(loyalty, isDark),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Points summary
                _buildPointsSummary(loyalty, isDark),
                const SizedBox(height: 24),

                // Progression vers le palier suivant
                if (loyalty.tier != LoyaltyTier.platinum) ...[
                  _buildProgressSection(loyalty, isDark),
                  const SizedBox(height: 24),
                ],

                // Avantages actuels
                _buildBenefitsSection(loyalty, isDark),
                const SizedBox(height: 24),

                // Récompenses disponibles
                if (loyalty.availableRewards.isNotEmpty) ...[
                  _buildRewardsSection(loyalty, isDark),
                  const SizedBox(height: 24),
                ],

                // Aperçu des paliers
                _buildTierOverview(isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(LoyaltyEntity loyalty, bool isDark) {
    final tierColor = _tierColor(loyalty.tier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tierColor, tierColor.withValues(alpha: 0.7)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Icon(_tierIcon(loyalty.tier), size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              loyalty.tier.displayName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${loyalty.totalPoints} points',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            if (loyalty.tier.discountPercent > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '-${loyalty.tier.discountPercent}% sur toutes vos commandes',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPointsSummary(LoyaltyEntity loyalty, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.stars,
            label: 'Points disponibles',
            value: '${loyalty.availablePoints}',
            color: Colors.amber,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.shopping_bag,
            label: 'Commandes',
            value: '${loyalty.totalOrders}',
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(LoyaltyEntity loyalty, bool isDark) {
    final nextTier = LoyaltyTier.values[loyalty.tier.index + 1];
    final tierColor = _tierColor(nextTier);

    return Card(
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? BorderSide(color: Colors.grey[700]!) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: tierColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Progression vers ${nextTier.displayName}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: loyalty.progressToNextTier,
                minHeight: 12,
                backgroundColor: tierColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(tierColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plus que ${loyalty.pointsToNextTier} points pour ${nextTier.displayName}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(LoyaltyEntity loyalty, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos avantages ${loyalty.tier.displayName}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...loyalty.tier.benefits.map(
          (benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    benefit,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsSection(LoyaltyEntity loyalty, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Récompenses à échanger',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...loyalty.availableRewards.map(
          (reward) => _buildRewardCard(reward, loyalty.availablePoints, isDark),
        ),
      ],
    );
  }

  Widget _buildRewardCard(
    LoyaltyReward reward,
    int availablePoints,
    bool isDark,
  ) {
    final canRedeem = availablePoints >= reward.pointsCost;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark ? BorderSide(color: Colors.grey[700]!) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _rewardColor(reward.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _rewardIcon(reward.type),
                color: _rewardColor(reward.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reward.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey[400]
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  '${reward.pointsCost}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: canRedeem ? AppColors.primary : Colors.grey,
                  ),
                ),
                Text(
                  'pts',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                if (canRedeem)
                  GestureDetector(
                    onTap: () => _confirmRedeem(reward),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Échanger',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierOverview(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Les paliers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...LoyaltyTier.values.map((tier) {
          final color = _tierColor(tier);
          final loyaltyState = ref.watch(loyaltyProvider);
          final isCurrentTier = loyaltyState.loyalty?.tier == tier;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isCurrentTier
                  ? color.withValues(alpha: 0.1)
                  : (isDark ? const Color(0xFF2D2D2D) : Colors.grey[50]),
              border: isCurrentTier
                  ? Border.all(color: color, width: 2)
                  : Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
            ),
            child: Row(
              children: [
                Icon(_tierIcon(tier), color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          if (isCurrentTier) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ACTUEL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        tier == LoyaltyTier.bronze
                            ? 'Dès la 1ère commande'
                            : 'À partir de ${tier.requiredPoints} points',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey[400]
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tier.discountPercent > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-${tier.discountPercent}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _confirmRedeem(LoyaltyReward reward) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer l\'échange'),
        content: Text(
          'Échanger ${reward.pointsCost} points contre :\n\n${reward.title}\n\n${reward.description}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(loyaltyProvider.notifier)
                  .redeemReward(reward.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Récompense échangée avec succès !'
                          : 'Impossible d\'échanger cette récompense.',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Color _tierColor(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.bronze:
        return const Color(0xFFCD7F32);
      case LoyaltyTier.silver:
        return const Color(0xFF9E9E9E);
      case LoyaltyTier.gold:
        return const Color(0xFFFFD700);
      case LoyaltyTier.platinum:
        return const Color(0xFF6C63FF);
    }
  }

  IconData _tierIcon(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.bronze:
        return Icons.workspace_premium;
      case LoyaltyTier.silver:
        return Icons.shield;
      case LoyaltyTier.gold:
        return Icons.emoji_events;
      case LoyaltyTier.platinum:
        return Icons.diamond;
    }
  }

  IconData _rewardIcon(String type) {
    switch (type) {
      case 'discount':
        return Icons.percent;
      case 'free_delivery':
        return Icons.local_shipping;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.stars;
    }
  }

  Color _rewardColor(String type) {
    switch (type) {
      case 'discount':
        return AppColors.primary;
      case 'free_delivery':
        return Colors.blue;
      case 'gift':
        return Colors.purple;
      default:
        return Colors.amber;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? BorderSide(color: Colors.grey[700]!) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
