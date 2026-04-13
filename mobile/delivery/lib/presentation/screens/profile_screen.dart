import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_config.dart';
import '../../core/router/route_names.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/models/user.dart';
import '../../data/models/wallet_data.dart';
import '../providers/profile_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/dashboard_tab_provider.dart';
import '../widgets/common/common_widgets.dart';
import '../widgets/profile/logout_button.dart';

class _ProfileColors {
  static const navyDark = Color(0xFF0F1C3F);
  static const navyMedium = Color(0xFF1A2B52);
  static const accentGold = Color(0xFFE5C76B);
  static const accentTeal = Color(0xFF2DD4BF);
  static const accentBlue = Color(0xFF60A5FA);
  static const successGreen = Color(0xFF10B981);
  static const warningOrange = Color(0xFFF59E0B);
  static const softBackground = Color(0xFFF8FAFC);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    final userAsync = ref.watch(profileProvider);
    final walletAsync = ref.watch(walletDataProvider);

    return Scaffold(
      backgroundColor: _ProfileColors.softBackground,
      body: AsyncValueWidget<User>(
        value: userAsync,
        data: (user) {
          final walletData = walletAsync.whenOrNull(data: (d) => d);
          return RefreshIndicator(
            color: _ProfileColors.navyDark,
            onRefresh: () async {
              ref.invalidate(profileProvider);
              ref.invalidate(walletDataProvider);
              await ref.read(profileProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(user: user, walletData: walletData),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SectionCard(
                          title: 'Compte & activité',
                          subtitle:
                              'Vos informations de livraison et votre statut.',
                          child: _AccountOverview(
                            user: user,
                            walletData: walletData,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Informations personnelles',
                          subtitle: 'Coordonnées et données de profil.',
                          child: _PersonalInfo(user: user),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Raccourcis utiles',
                          subtitle:
                              'Accédez rapidement aux sections importantes.',
                          child: _QuickActions(user: user),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const LogoutButton(),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        onRetry: () => ref.refresh(profileProvider),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  final WalletData? walletData;

  const _ProfileHeader({required this.user, required this.walletData});

  @override
  Widget build(BuildContext context) {
    final courier = user.courier;
    final statusColor = _statusColor(courier?.status);
    final vehicle = courier?.vehicleType ?? 'Véhicule non renseigné';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_ProfileColors.navyDark, _ProfileColors.navyMedium],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mon Profil',
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Votre espace personnel livreur',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _HeaderButton(
                    icon: Icons.settings_rounded,
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _ProfileAvatar(user: user),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.sora(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.role == 'courier'
                              ? 'Livreur Dr Pharma'
                              : (user.role ?? 'Utilisateur'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusChip(
                              icon: Icons.verified_rounded,
                              label: _statusLabel(courier?.status),
                              color: statusColor,
                            ),
                            _StatusChip(
                              icon: Icons.two_wheeler_rounded,
                              label: vehicle,
                              color: _ProfileColors.accentTeal,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      label: 'Note',
                      value: (courier?.rating ?? 5).toStringAsFixed(1),
                      icon: Icons.star_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroStat(
                      label: 'Livraisons',
                      value:
                          '${courier?.completedDeliveries ?? walletData?.deliveriesCount ?? 0}',
                      icon: Icons.local_shipping_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroStat(
                      label: 'Gains',
                      value: (walletData?.totalEarnings ?? 0)
                          .formatCurrencyCompact(),
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ProfileColors.navyDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AccountOverview extends StatelessWidget {
  final User user;
  final WalletData? walletData;

  const _AccountOverview({required this.user, required this.walletData});

  @override
  Widget build(BuildContext context) {
    final courier = user.courier;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                label: 'Solde',
                value: (walletData?.balance ?? 0).formatCurrency(),
                color: _ProfileColors.accentBlue,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniMetric(
                label: 'Aujourd’hui',
                value: (walletData?.todayEarnings ?? 0).formatCurrency(),
                color: _ProfileColors.successGreen,
                icon: Icons.bolt_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'Statut du compte',
          value: _statusLabel(courier?.status),
        ),
        _InfoRow(
          icon: Icons.two_wheeler_outlined,
          label: 'Type de véhicule',
          value: courier?.vehicleType ?? 'Non renseigné',
        ),
        _InfoRow(
          icon: Icons.pin_outlined,
          label: 'Immatriculation',
          value: courier?.vehicleNumber ?? 'Non renseignée',
        ),
      ],
    );
  }
}

class _PersonalInfo extends StatelessWidget {
  final User user;

  const _PersonalInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.person_outline_rounded,
          label: 'Nom complet',
          value: user.name,
        ),
        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Téléphone',
          value: user.phone ?? 'Non renseigné',
        ),
      ],
    );
  }
}

class _QuickActions extends ConsumerWidget {
  final User user;

  const _QuickActions({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycStatus = user.courier?.kycStatus ?? 'unknown';
    final kycInfo = _getKycInfo(kycStatus);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Indicateur de statut KYC
        _KycStatusTile(
          status: kycStatus,
          label: kycInfo.label,
          icon: kycInfo.icon,
          color: kycInfo.color,
          onTap: () => _showKycStatusDialog(context, kycStatus, kycInfo),
        ),
        _QuickActionTile(
          icon: Icons.edit_outlined,
          label: 'Modifier',
          color: _ProfileColors.accentBlue,
          onTap: () => context.push(AppRoutes.editProfile, extra: user),
        ),
        _QuickActionTile(
          icon: Icons.bar_chart_rounded,
          label: 'Stats',
          color: _ProfileColors.successGreen,
          onTap: () {
            ref.read(dashboardTabProvider.notifier).setTab(2);
          },
        ),
        _QuickActionTile(
          icon: Icons.history_rounded,
          label: 'Historique',
          color: _ProfileColors.accentGold,
          onTap: () {
            ref.read(dashboardTabProvider.notifier).setTab(1);
          },
        ),
        _QuickActionTile(
          icon: Icons.emoji_events_outlined,
          label: 'Badges',
          color: Colors.purple.shade400,
          onTap: () => context.push(AppRoutes.gamification),
        ),
        _QuickActionTile(
          icon: Icons.calendar_month_rounded,
          label: 'Shifts',
          color: Colors.indigo.shade400,
          onTap: () => context.push(AppRoutes.shifts),
        ),
        _QuickActionTile(
          icon: Icons.settings_outlined,
          label: 'Réglages',
          color: _ProfileColors.accentTeal,
          onTap: () => context.push(AppRoutes.settings),
        ),
        _QuickActionTile(
          icon: Icons.support_agent_rounded,
          label: 'Aide',
          color: _ProfileColors.warningOrange,
          onTap: () => context.push(AppRoutes.helpCenter),
        ),
      ],
    );
  }

  _KycStatusInfo _getKycInfo(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
        return _KycStatusInfo(
          label: 'Vérifié',
          icon: Icons.verified_rounded,
          color: _ProfileColors.successGreen,
          description:
              'Votre identité a été vérifiée avec succès. Vous pouvez effectuer des livraisons sans restriction.',
        );
      case 'pending_review':
        return _KycStatusInfo(
          label: 'En attente',
          icon: Icons.hourglass_top_rounded,
          color: _ProfileColors.warningOrange,
          description:
              'Vos documents sont en cours de vérification. Ce processus prend généralement 24-48h ouvrées.',
        );
      case 'incomplete':
        return _KycStatusInfo(
          label: 'À compléter',
          icon: Icons.warning_amber_rounded,
          color: Colors.red.shade400,
          description:
              'Des documents sont manquants pour valider votre identité. Veuillez compléter votre dossier.',
        );
      case 'rejected':
        return _KycStatusInfo(
          label: 'Refusé',
          icon: Icons.cancel_outlined,
          color: Colors.red.shade600,
          description:
              'Votre vérification a été refusée. Veuillez resoumettre vos documents.',
        );
      default:
        return _KycStatusInfo(
          label: 'Statut',
          icon: Icons.help_outline_rounded,
          color: Colors.grey,
          description: 'Le statut de votre vérification est inconnu.',
        );
    }
  }

  void _showKycStatusDialog(
    BuildContext context,
    String status,
    _KycStatusInfo info,
  ) {
    final needsAction = status == 'incomplete' || status == 'rejected';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(info.icon, color: info.color, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Statut KYC: ${info.label}',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          info.description,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (needsAction)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.kycResubmission);
              },
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Compléter mon dossier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: info.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KycStatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final String description;

  const _KycStatusInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _KycStatusTile extends StatelessWidget {
  final String status;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KycStatusTile({
    required this.status,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = status == 'approved' || status == 'verified';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 106,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          gradient: isVerified
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isVerified ? null : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isVerified ? 0.4 : 0.25),
            width: isVerified ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            if (isVerified) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '✓ KYC',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final User user;

  const _ProfileAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _resolveAvatarUrl(user.avatar);

    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                width: 82,
                height: 82,
                placeholder: (context, url) => Container(
                  color: Colors.white.withValues(alpha: 0.12),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => _AvatarFallback(name: user.name),
              )
            : _AvatarFallback(name: user.name),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;

  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();

    return Container(
      color: Colors.white.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: GoogleFonts.sora(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: _ProfileColors.accentGold),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _ProfileColors.navyDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ProfileColors.navyDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _ProfileColors.navyDark.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _ProfileColors.navyDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ProfileColors.navyDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _resolveAvatarUrl(String? avatar) {
  if (avatar == null || avatar.trim().isEmpty) return null;
  if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
    return avatar;
  }
  if (avatar.startsWith('/')) {
    return '${AppConfig.webBaseUrl}$avatar';
  }
  return avatar;
}

String _statusLabel(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'online':
      return 'En ligne';
    case 'offline':
      return 'Hors ligne';
    case 'busy':
      return 'Occupé';
    case 'available':
      return 'Disponible';
    default:
      return 'Statut inconnu';
  }
}

Color _statusColor(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'online':
    case 'available':
      return _ProfileColors.successGreen;
    case 'busy':
      return _ProfileColors.warningOrange;
    default:
      return _ProfileColors.accentBlue;
  }
}
