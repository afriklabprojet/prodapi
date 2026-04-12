import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import '../../../../config/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../providers/pharmacies_state.dart';

class PharmacyDetailsPage extends ConsumerStatefulWidget {
  final int pharmacyId;

  const PharmacyDetailsPage({super.key, required this.pharmacyId});

  @override
  ConsumerState<PharmacyDetailsPage> createState() =>
      _PharmacyDetailsPageState();
}

class _PharmacyDetailsPageState extends ConsumerState<PharmacyDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    Future.microtask(() {
      ref
          .read(pharmaciesProvider.notifier)
          .fetchPharmacyDetails(widget.pharmacyId);
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Partager les infos de la pharmacie
  Future<void> _sharePharmacy(dynamic pharmacy) async {
    final StringBuffer text = StringBuffer();
    text.writeln('🏥 ${pharmacy.name}');
    text.writeln();
    text.writeln('📍 Adresse : ${pharmacy.address}');
    if (pharmacy.phone.isNotEmpty) {
      text.writeln('📞 Tél : ${pharmacy.phone}');
    }
    if (pharmacy.email != null) {
      text.writeln('✉️ Email : ${pharmacy.email}');
    }
    if (pharmacy.openingHours != null) {
      text.writeln('🕐 Horaires : ${pharmacy.openingHours}');
    }
    if (pharmacy.isOpen) {
      text.writeln('✅ Actuellement ouverte');
    }
    text.writeln();
    text.writeln('Partagé via DR-PHARMA');

    await Share.share(text.toString(), subject: pharmacy.name);
  }

  /// Lancer un appel téléphonique
  Future<void> _makePhoneCall(String phoneNumber) async {
    final success = await UrlLauncherService.makePhoneCall(phoneNumber);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de lancer l\'appel téléphonique'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Envoyer un email
  Future<void> _sendEmail(String email) async {
    final success = await UrlLauncherService.sendEmail(
      email: email,
      subject: 'Demande d\'information - DR-PHARMA',
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'application email'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Ouvrir l'adresse dans Google Maps
  Future<void> _openMap({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    bool success = false;

    // Si on a les coordonnées GPS, les utiliser en priorité
    if (latitude != null && longitude != null) {
      success = await UrlLauncherService.openMap(
        latitude: latitude,
        longitude: longitude,
        label: address,
      );
    } else {
      // Sinon, utiliser l'adresse textuelle
      success = await UrlLauncherService.openMapWithAddress(address);
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'application de navigation'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getDutyLabel(String? type) {
    if (type == null) return 'Garde';
    switch (type.toLowerCase()) {
      case 'night':
        return 'Garde de Nuit';
      case 'weekend':
        return 'Garde de Weekend';
      case 'holiday':
        return 'Garde Férié';
      default:
        return 'Garde $type';
    }
  }

  String _formatTime(String timeStr) {
    try {
      if (timeStr.contains(' ')) {
        final parts = timeStr.split(' ');
        if (parts.length > 1) {
          final timeParts = parts[1].split(':');
          if (timeParts.length >= 2) {
            return '${timeParts[0]}:${timeParts[1]}';
          }
        }
      } else {
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          return '${timeParts[0]}:${timeParts[1]}';
        }
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmaciesState = ref.watch(pharmaciesProvider);
    final pharmacy = pharmaciesState.selectedPharmacy;
    final showFallbackAppBar =
        pharmaciesState.status == PharmaciesStatus.loading ||
        pharmaciesState.status == PharmaciesStatus.error ||
        pharmacy == null;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8FAFC),
      appBar: showFallbackAppBar
          ? AppBar(
              title: const Text('Détails pharmacie'),
              leading: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            )
          : null,
      body: _buildBody(pharmaciesState),
      floatingActionButton: pharmacy != null && pharmacy.phone.isNotEmpty
          ? _buildPremiumFAB(pharmacy.phone)
          : null,
    );
  }

  Widget _buildPremiumFAB(String phone) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _makePhoneCall(phone),
        backgroundColor: Colors.transparent,
        elevation: 0,
        extendedPadding: EdgeInsets.zero,
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.success,
                AppColors.success.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Appeler maintenant',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(PharmaciesState state) {
    if (state.status == PharmaciesStatus.loading) {
      return _buildPremiumLoading();
    }

    if (state.status == PharmaciesStatus.error) {
      return _buildError(state.errorMessage ?? 'Une erreur est survenue');
    }

    if (state.selectedPharmacy == null) {
      return _buildError('Pharmacie non trouvée');
    }

    final pharmacy = state.selectedPharmacy!;

    // Determine colors based on status
    final Color accentColor = pharmacy.isOnDuty == true
        ? Colors.orange
        : pharmacy.isOpen
        ? AppColors.success
        : Colors.grey;

    final List<Color> headerGradient = pharmacy.isOnDuty == true
        ? [const Color(0xFFF97316), const Color(0xFFEA580C)]
        : pharmacy.isOpen
        ? [AppColors.primary, const Color(0xFF0E7490)]
        : [const Color(0xFF6B7280), const Color(0xFF4B5563)];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Premium Sliver App Bar
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          stretch: true,
          backgroundColor: headerGradient[0],
          leading: _buildBackButton(),
          actions: [_buildShareButton(pharmacy.name)],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildPremiumHeader(
              pharmacy,
              headerGradient,
              accentColor,
            ),
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions Row
                    _buildQuickActionsRow(pharmacy, accentColor),

                    const SizedBox(height: 24),

                    // Section Title
                    _buildSectionTitle(
                      'Informations',
                      Icons.info_outline_rounded,
                    ),

                    const SizedBox(height: 16),

                    // Premium Info Cards
                    _buildPremiumInfoCard(
                      icon: Icons.location_on_rounded,
                      title: 'Adresse',
                      content: pharmacy.address,
                      gradientColors: [
                        const Color(0xFF3B82F6),
                        const Color(0xFF2563EB),
                      ],
                      onTap: () => _openMap(
                        address: pharmacy.address,
                        latitude: pharmacy.latitude,
                        longitude: pharmacy.longitude,
                      ),
                      actionIcon: Icons.directions_rounded,
                      actionLabel: 'Itinéraire',
                    ),

                    if (pharmacy.phone.isNotEmpty)
                      _buildPremiumInfoCard(
                        icon: Icons.phone_rounded,
                        title: 'Téléphone',
                        content: pharmacy.phone,
                        gradientColors: [
                          const Color(0xFF10B981),
                          const Color(0xFF059669),
                        ],
                        onTap: () => _makePhoneCall(pharmacy.phone),
                        actionIcon: Icons.call_rounded,
                        actionLabel: 'Appeler',
                      ),

                    if (pharmacy.email != null)
                      _buildPremiumInfoCard(
                        icon: Icons.email_rounded,
                        title: 'Email',
                        content: pharmacy.email!,
                        gradientColors: [
                          const Color(0xFFF59E0B),
                          const Color(0xFFD97706),
                        ],
                        onTap: () => _sendEmail(pharmacy.email!),
                        actionIcon: Icons.send_rounded,
                        actionLabel: 'Envoyer',
                      ),

                    if (pharmacy.openingHours != null) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Horaires', Icons.schedule_rounded),
                      const SizedBox(height: 16),
                      _buildScheduleCard(pharmacy),
                    ],

                    if (pharmacy.description != null) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('À propos', Icons.description_rounded),
                      const SizedBox(height: 16),
                      _buildDescriptionCard(pharmacy.description!),
                    ],

                    if (pharmacy.distance != null) ...[
                      const SizedBox(height: 24),
                      _buildDistanceCard(pharmacy),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chargement...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(String name) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {
              final pharmacy = ref.read(pharmaciesProvider).selectedPharmacy;
              if (pharmacy != null) _sharePharmacy(pharmacy);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(
    dynamic pharmacy,
    List<Color> gradient,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Premium Avatar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  (pharmacy.name.trim().isNotEmpty
                                          ? pharmacy.name.trim()[0]
                                          : 'P')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                              // Status indicator
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    pharmacy.isOnDuty == true
                                        ? Icons.shield_moon_rounded
                                        : pharmacy.isOpen
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 20,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Name
                  Text(
                    pharmacy.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Status Badges
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildHeaderBadge(
                        icon: pharmacy.isOpen
                            ? Icons.check_circle
                            : Icons.cancel,
                        label: pharmacy.isOpen ? 'Ouverte' : 'Fermée',
                        color: pharmacy.isOpen ? AppColors.success : Colors.red,
                      ),
                      if (pharmacy.isOnDuty == true)
                        _buildHeaderBadge(
                          icon: Icons.shield_moon_rounded,
                          label: _getDutyLabel(pharmacy.dutyType),
                          color: Colors.orange,
                          isHighlighted: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge({
    required IconData icon,
    required String label,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isHighlighted ? 0.5 : 0.3),
          width: 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(dynamic pharmacy, Color accentColor) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.phone_rounded,
            label: 'Appeler',
            gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
            onTap: pharmacy.phone.isNotEmpty
                ? () => _makePhoneCall(pharmacy.phone)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.directions_rounded,
            label: 'Itinéraire',
            gradientColors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
            onTap: () => _openMap(
              address: pharmacy.address,
              latitude: pharmacy.latitude,
              longitude: pharmacy.longitude,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.share_rounded,
            label: 'Partager',
            gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
            onTap: () => _sharePharmacy(pharmacy),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled
                  ? Colors.grey.withValues(alpha: 0.2)
                  : gradientColors[0].withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDisabled
                    ? Colors.grey.withValues(alpha: 0.1)
                    : gradientColors[0].withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isDisabled
                      ? null
                      : LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: isDisabled ? Colors.grey[300] : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isDisabled
                      ? null
                      : [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isDisabled ? Colors.grey[400] : Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.grey[400]
                      : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required List<Color> gradientColors,
    VoidCallback? onTap,
    IconData? actionIcon,
    String? actionLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradientColors[0].withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: gradientColors[0].withValues(alpha: 0.1),
          highlightColor: gradientColors[0].withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action button
                if (onTap != null && actionIcon != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: gradientColors[0].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(actionIcon, size: 16, color: gradientColors[0]),
                        if (actionLabel != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            actionLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: gradientColors[0],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(dynamic pharmacy) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horaires d\'ouverture',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pharmacy.openingHours ?? 'Non disponible',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (pharmacy.isOnDuty == true && pharmacy.dutyEndAt != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.1),
                      Colors.orange.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_moon_rounded,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fin de garde',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[700],
                          ),
                        ),
                        Text(
                          _formatTime(pharmacy.dutyEndAt!),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[300]
              : Colors.grey[700],
          height: 1.6,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildDistanceCard(dynamic pharmacy) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.social_distance_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pharmacy.distanceLabel ?? '${pharmacy.distance} km',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _openMap(
                    address: pharmacy.address,
                    latitude: pharmacy.latitude,
                    longitude: pharmacy.longitude,
                  ),
                  child: Text(
                    'Y aller',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.error.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oups !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(pharmaciesProvider.notifier)
                      .fetchPharmacyDetails(widget.pharmacyId);
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Réessayer',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
