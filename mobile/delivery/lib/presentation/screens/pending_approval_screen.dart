import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/secure_token_service.dart';
import '../../core/utils/error_utils.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/router/route_names.dart';
import '../providers/delivery_providers.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  final String status; // 'pending_approval', 'suspended', 'rejected'
  final String message;

  const PendingApprovalScreen({
    super.key,
    required this.status,
    required this.message,
  });

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      ref.invalidate(courierProfileProvider);
      final profile = await ref.read(courierProfileProvider.future);

      if (mounted) {
        final newStatus = profile.kycStatus;
        if (newStatus == 'verified' || newStatus == 'approved') {
          context.go(AppRoutes.dashboard);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Statut vérifié — toujours en attente'),
                  ),
                ],
              ),
              backgroundColor: DesignTokens.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyError(e)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isPending = widget.status == 'pending_approval';
    final isRejected = widget.status == 'rejected';
    // isSuspended utile pour extensions futures

    final Color accentColor = isPending
        ? DesignTokens.primary
        : isRejected
        ? Colors.red.shade600
        : Colors.orange.shade700;
    final IconData statusIcon = isPending
        ? Icons.hourglass_top_rounded
        : isRejected
        ? Icons.error_outline_rounded
        : Icons.block_rounded;
    final String title = isPending
        ? 'Vérification en cours'
        : isRejected
        ? 'Documents refusés'
        : 'Compte suspendu';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0D1117)
            : const Color(0xFFF5F7FA),
        body: CustomScrollView(
          slivers: [
            // ── Header avec gradient ──
            SliverToBoxAdapter(
              child: _buildHeader(
                context,
                isDark,
                accentColor,
                statusIcon,
                title,
              ),
            ),

            // ── Contenu ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Message personnalisé
                  _buildMessageCard(context, isDark),
                  const SizedBox(height: 20),

                  // Stepper de progression
                  if (isPending) ...[
                    _buildProgressStepper(context, isDark),
                    const SizedBox(height: 20),
                  ],

                  // Notification info
                  if (isPending) _buildNotificationCard(context, isDark),

                  // Rejection action
                  if (isRejected) ...[
                    _buildRejectionActionCard(context, isDark),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 20),

                  // Boutons d'action
                  if (isPending) _buildCheckStatusButton(context, isDark),

                  const SizedBox(height: 12),
                  _buildLogoutButton(context, isDark),
                  const SizedBox(height: 12),
                  _buildSupportButton(context, isDark),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color accentColor,
    IconData icon,
    String title,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2940), const Color(0xFF0D1B2A)]
              : [DesignTokens.primary, const Color(0xFF0A5236)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await SecureTokenService.instance.removeToken();
                      if (!context.mounted) return;
                      context.go(AppRoutes.login);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Déconnexion',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Animated icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) =>
                    Transform.scale(scale: _pulseAnimation.value, child: child),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 40),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Délai badge
              if (widget.status == 'pending_approval')
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Validation sous 24-48h ouvrées',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2030) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? DesignTokens.info.withValues(alpha: 0.15)
                  : DesignTokens.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.message,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: context.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStepper(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2030) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.primary.withValues(alpha: 0.2)
                      : DesignTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  size: 18,
                  color: isDark
                      ? DesignTokens.primaryLight
                      : DesignTokens.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Progression',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Étape 1: Documents soumis ✓
          _buildStepItem(
            isDark: isDark,
            step: 1,
            title: 'Documents reçus',
            subtitle: 'Vos documents ont été soumis avec succès',
            isCompleted: true,
            isActive: false,
          ),
          _buildStepConnector(isDark: isDark, isCompleted: true),

          // Étape 2: En cours de vérification
          _buildStepItem(
            isDark: isDark,
            step: 2,
            title: 'Vérification en cours',
            subtitle: 'Notre équipe examine votre dossier',
            isCompleted: false,
            isActive: true,
          ),
          _buildStepConnector(isDark: isDark, isCompleted: false),

          // Étape 3: Activé
          _buildStepItem(
            isDark: isDark,
            step: 3,
            title: 'Compte activé',
            subtitle: 'Vous pourrez commencer à livrer',
            isCompleted: false,
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required bool isDark,
    required int step,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
  }) {
    final Color circleColor;
    final Widget circleChild;

    if (isCompleted) {
      circleColor = DesignTokens.primary;
      circleChild = const Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: 16,
      );
    } else if (isActive) {
      circleColor = Colors.blue;
      circleChild = SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else {
      circleColor = isDark ? const Color(0xFF2D3E4E) : Colors.grey.shade300;
      circleChild = Text(
        '$step',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(child: circleChild),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isCompleted || isActive
                            ? context.primaryText
                            : context.secondaryText,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'En cours',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.secondaryText,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({
    required bool isDark,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: isCompleted
              ? DesignTokens.primary
              : (isDark ? const Color(0xFF2D3E4E) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.primary.withValues(alpha: 0.08)
            : const Color(0xFFF0FAF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? DesignTokens.primary.withValues(alpha: 0.2)
              : DesignTokens.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: isDark ? DesignTokens.primaryLight : DesignTokens.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vous recevrez une notification dès que votre compte sera validé.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? DesignTokens.primaryLight
                    : DesignTokens.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionActionCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withValues(alpha: 0.15)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.red.shade700.withValues(alpha: 0.3)
              : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vos documents ont été refusés. Veuillez les soumettre à nouveau.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.red.shade300 : Colors.red.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.kycResubmission),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(
                'Resoumettre les documents',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.red.shade700
                    : Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckStatusButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: !_isRefreshing
              ? LinearGradient(
                  colors: [DesignTokens.primary, DesignTokens.primaryDark],
                )
              : null,
          color: _isRefreshing
              ? (isDark ? const Color(0xFF2D3E4E) : Colors.grey.shade300)
              : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: !_isRefreshing
              ? [
                  BoxShadow(
                    color: DesignTokens.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isRefreshing ? null : _checkStatus,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: _isRefreshing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Vérification...',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Vérifier mon statut',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          await SecureTokenService.instance.removeToken();
          if (context.mounted) {
            context.go(AppRoutes.login);
          }
        },
        icon: Icon(
          Icons.logout_rounded,
          size: 18,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        label: Text(
          'Retour à la connexion',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? const Color(0xFF2D3E4E) : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportButton(BuildContext context, bool isDark) {
    final isPending = widget.status == 'pending_approval';

    return Center(
      child: TextButton.icon(
        onPressed: () {
          WhatsAppService.contactSupport(
            message: isPending
                ? 'Bonjour, je souhaite avoir des informations sur l\'avancement de ma validation de compte coursier.'
                : 'Bonjour, j\'ai besoin d\'aide avec mon compte coursier (statut: ${widget.status}).',
          );
        },
        icon: Icon(
          isPending ? Icons.help_outline_rounded : Icons.support_agent_rounded,
          size: 18,
          color: DesignTokens.primary,
        ),
        label: Text(
          isPending ? 'Une question ?' : 'Contacter le support',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: DesignTokens.primary,
          ),
        ),
      ),
    );
  }
}
