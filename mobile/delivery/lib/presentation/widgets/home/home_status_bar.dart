import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/courier_profile.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/dashboard_tab_provider.dart';
import '../../providers/delivery_providers.dart';
import '../battery/battery_indicator_widget.dart';
import '../notifications/notification_widgets.dart';

/// Barre de statut premium en haut de l'écran d'accueil (solde + profil)
/// Design glassmorphism avec blur et gradients subtils
class HomeStatusBar extends ConsumerWidget {
  final AsyncValue<CourierProfile> profileAsync;

  const HomeStatusBar({super.key, required this.profileAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final actions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BatteryIndicatorWidget(compact: true),
                    const SizedBox(width: 10),
                    const NotificationIconButton(),
                  ],
                );

                if (constraints.maxWidth < 380) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildWalletPill(context, isDark, ref),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadges(isDark, ref),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [actions, _buildProfileInfo(isDark)],
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWalletPill(context, isDark, ref),
                    _buildStatusBadges(isDark, ref),
                    actions,
                    _buildProfileInfo(isDark),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletPill(BuildContext context, bool isDark, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(dashboardTabProvider.notifier).setTab(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignTokens.primary.withValues(alpha: isDark ? 0.3 : 0.15),
              DesignTokens.primaryLight.withValues(alpha: isDark ? 0.2 : 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DesignTokens.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on_rounded,
                size: 16,
                color: isDark
                    ? DesignTokens.primaryLight
                    : DesignTokens.primary,
              ),
            ),
            const SizedBox(width: 8),
            Consumer(
              builder: (context, ref, _) {
                final walletAsync = ref.watch(walletDataProvider);
                return walletAsync.when(
                  data: (walletData) {
                    final gains = walletData?.todayEarnings ?? 0;
                    return _AnimatedEarningsText(
                      targetValue: gains,
                      isDark: isDark,
                    );
                  },
                  loading: () => SizedBox(
                    width: 60,
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      color: DesignTokens.primary,
                      backgroundColor: DesignTokens.primary.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  error: (error, stack) => Text(
                    '--- F',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? DesignTokens.primaryLight
                          : DesignTokens.primary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Badge de statut: Disponible/Hors ligne
  Widget _buildStatusBadges(bool isDark, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge Disponible/Hors ligne
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isOnline
                ? const Color(0xFF059669).withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOnline
                  ? const Color(0xFF059669).withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? const Color(0xFF059669) : Colors.grey,
                  boxShadow: isOnline
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF059669,
                            ).withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'Disponible' : 'Hors ligne',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOnline
                      ? const Color(0xFF059669)
                      : (isDark ? Colors.white60 : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(bool isDark) {
    return profileAsync.when(
      data: (profile) => Row(
        children: [
          Text(
            profile.name.split(' ').first,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : DesignTokens.textDark,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [DesignTokens.primaryLight, DesignTokens.primary],
              ),
            ),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: isDark ? const Color(0xFF1A2A3A) : Colors.white,
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: DesignTokens.primary,
              ),
            ),
          ),
        ],
      ),
      loading: () => SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: DesignTokens.primary,
        ),
      ),
      error: (error, stack) => Icon(
        Icons.error_outline,
        size: 20,
        color: isDark ? Colors.red.shade300 : Colors.red,
      ),
    );
  }
}

/// Widget animé qui fait un count-up du delta quand les gains changent
class _AnimatedEarningsText extends StatefulWidget {
  final num targetValue;
  final bool isDark;

  const _AnimatedEarningsText({
    required this.targetValue,
    required this.isDark,
  });

  @override
  State<_AnimatedEarningsText> createState() => _AnimatedEarningsTextState();
}

class _AnimatedEarningsTextState extends State<_AnimatedEarningsText> {
  double _previousValue = 0;
  double _currentTarget = 0;

  @override
  void initState() {
    super.initState();
    _currentTarget = widget.targetValue.toDouble();
  }

  @override
  void didUpdateWidget(covariant _AnimatedEarningsText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _previousValue = oldWidget.targetValue.toDouble();
      _currentTarget = widget.targetValue.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_currentTarget),
      tween: Tween<double>(begin: _previousValue, end: _currentTarget),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final color = widget.isDark
            ? DesignTokens.primaryLight
            : DesignTokens.primary;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.formatCurrency(symbol: 'F'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'auj.',
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
