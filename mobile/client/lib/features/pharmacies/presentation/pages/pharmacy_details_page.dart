import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _PharmacyDetailsPageState extends ConsumerState<PharmacyDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(pharmaciesProvider.notifier)
          .fetchPharmacyDetails(widget.pharmacyId),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la pharmacie'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(pharmaciesState),
      floatingActionButton:
          pharmaciesState.selectedPharmacy != null &&
              pharmaciesState.selectedPharmacy!.phone != null
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _makePhoneCall(pharmaciesState.selectedPharmacy!.phone!),
              backgroundColor: AppColors.success,
              icon: const Icon(Icons.phone),
              label: const Text('Appeler'),
            )
          : null,
    );
  }

  Widget _buildBody(PharmaciesState state) {
    if (state.status == PharmaciesStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == PharmaciesStatus.error) {
      return _buildError(state.errorMessage ?? 'Une erreur est survenue');
    }

    if (state.selectedPharmacy == null) {
      return _buildError('Pharmacie non trouvée');
    }

    final pharmacy = state.selectedPharmacy!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  pharmacy.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Status Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    // Open/Closed Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: pharmacy.isOpen
                            ? AppColors.success
                            : AppColors.error.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pharmacy.isOpen ? 'Ouverte' : 'Fermée',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // On Duty Badge
                    if (pharmacy.isOnDuty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getDutyLabel(pharmacy.dutyType),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (pharmacy.dutyEndAt != null)
                                  Text(
                                    'Fin: ${_formatTime(pharmacy.dutyEndAt!)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Information Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Card
                _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'Adresse',
                  content: pharmacy.address,
                  color: AppColors.info,
                  onTap: () => _openMap(
                    address: pharmacy.address,
                    latitude: pharmacy.latitude,
                    longitude: pharmacy.longitude,
                  ),
                ),

                // Phone Card
                if (pharmacy.phone != null)
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'Téléphone',
                    content: pharmacy.phone!,
                    color: AppColors.success,
                    onTap: () => _makePhoneCall(pharmacy.phone!),
                  ),

                // Email Card
                if (pharmacy.email != null)
                  _buildInfoCard(
                    icon: Icons.email,
                    title: 'Email',
                    content: pharmacy.email!,
                    color: AppColors.warning,
                    onTap: () => _sendEmail(pharmacy.email!),
                  ),

                // Opening Hours
                if (pharmacy.openingHours != null)
                  _buildInfoCard(
                    icon: Icons.access_time,
                    title: 'Horaires d\'ouverture',
                    content: pharmacy.openingHours!,
                    color: AppColors.primary,
                  ),

                // Description
                if (pharmacy.description != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pharmacy.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Distance
                if (pharmacy.distance != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Distance: ${pharmacy.distanceLabel}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(pharmaciesProvider.notifier)
                    .fetchPharmacyDetails(widget.pharmacyId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
