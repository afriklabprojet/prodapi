import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../providers/profile_provider.dart';
import '../../providers/delivery_providers.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/kyc_guard_service.dart';
import '../../../core/utils/snackbar_extension.dart';
import 'profile_avatar.dart';

class ProfileHero extends ConsumerStatefulWidget {
  final User user;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;

  const ProfileHero({
    super.key,
    required this.user,
    this.onNotificationTap,
    this.onSettingsTap,
  });

  @override
  ConsumerState<ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends ConsumerState<ProfileHero> {
  bool isLoading = false;

  bool get isOnline => ref.read(isOnlineProvider);

  @override
  void initState() {
    super.initState();
    // Sync provider from server data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(isOnlineProvider.notifier)
          .set(widget.user.courier?.status == 'available');
    });
  }

  Future<void> _toggleAvailability() async {
    setState(() => isLoading = true);
    try {
      final desiredStatus = isOnline ? 'offline' : 'available';
      final actualStatus = await ref
          .read(deliveryRepositoryProvider)
          .toggleAvailability(desiredStatus: desiredStatus);
      if (!mounted) return;
      ref.read(isOnlineProvider.notifier).set(actualStatus);
      ref.invalidate(profileProvider);
      ref.invalidate(courierProfileProvider);

      // Sync location tracking + Firestore like the home screen does
      final locationService = ref.read(locationServiceProvider);
      if (actualStatus) {
        locationService.startTracking();
        locationService.goOnline();
      } else {
        locationService.stopTracking();
        locationService.goOffline();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        context.showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _vehicleLabel(String? vehicleType) {
    switch (vehicleType?.toLowerCase()) {
      case 'motorcycle':
        return 'Moto';
      case 'car':
        return 'Voiture';
      case 'bicycle':
        return 'Vélo';
      case 'scooter':
        return 'Scooter';
      default:
        return vehicleType ?? 'Transporteur';
    }
  }

  void _showPhotoOptions(BuildContext context) {
    final hasAvatar =
        widget.user.avatar != null && widget.user.avatar!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Photo de profil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D26),
                ),
              ),
              const SizedBox(height: 20),
              _sheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Galerie',
                color: const Color(0xFF6366F1),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
              _sheetOption(
                icon: Icons.camera_alt_rounded,
                label: 'Caméra',
                color: const Color(0xFF059669),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              if (hasAvatar)
                _sheetOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Supprimer la photo',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteAvatar();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color == const Color(0xFFEF4444)
              ? color
              : const Color(0xFF374151),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return;

      if (!mounted) return;
      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Envoi de la photo...'),
            ],
          ),
          duration: Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final bytes = await picked.readAsBytes();
      await ref.read(authRepositoryProvider).uploadAvatar(bytes);

      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        context.showSuccess('Photo de profil mise à jour');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        context.showErrorMessage(msg);
      }
    }
  }

  Future<void> _deleteAvatar() async {
    try {
      await ref.read(authRepositoryProvider).deleteAvatar();
      ref.invalidate(profileProvider);
      if (mounted) {
        context.showSuccess('Photo de profil supprimée');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        context.showErrorMessage(msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final user = widget.user;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(top: topPad + 12, bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAF9), Color(0xFFF2F4F3)],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Profil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D26),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                _iconBtn(
                  Icons.notifications_none_rounded,
                  widget.onNotificationTap,
                ),
                const SizedBox(width: 8),
                _iconBtn(Icons.settings_outlined, widget.onSettingsTap),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Avatar
          ProfileAvatar(
            name: user.name,
            imageUrl: user.avatar,
            size: 92,
            isOnline: isOnline,
            onTap: () => _showPhotoOptions(context),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D26),
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),

          // Pills
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                isOnline ? 'En ligne' : 'Hors ligne',
                isOnline ? const Color(0xFF059669) : const Color(0xFF9CA3AF),
              ),
              if (user.courier?.vehicleType != null)
                _pill(
                  _vehicleLabel(user.courier!.vehicleType),
                  const Color(0xFF6366F1),
                ),
              _kycPill(ref.watch(kycStatusProvider)),
            ],
          ),
          const SizedBox(height: 22),

          // Availability toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF059669).withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isOnline
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      size: 18,
                      color: isOnline
                          ? const Color(0xFF059669)
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline ? 'Disponible' : 'Indisponible',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1D26),
                          ),
                        ),
                        Text(
                          isOnline
                              ? 'Vous recevez des commandes'
                              : 'Activez pour recevoir des commandes',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF059669),
                          ),
                        )
                      : Switch.adaptive(
                          value: isOnline,
                          onChanged: (_) => _toggleAvailability(),
                          activeTrackColor: const Color(0xFF059669),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF374151)),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _kycPill(KycStatus status) {
    final Color color;
    switch (status) {
      case KycStatus.verified:
        color = const Color(0xFF059669); // Vert
      case KycStatus.pendingReview:
        color = const Color(0xFFF59E0B); // Ambre
      case KycStatus.incomplete:
        color = const Color(0xFFEA580C); // Orange
      case KycStatus.rejected:
        color = const Color(0xFFDC2626); // Rouge
      case KycStatus.unknown:
        color = const Color(0xFF6B7280); // Gris
    }
    return _pill(status.label, color);
  }
}
