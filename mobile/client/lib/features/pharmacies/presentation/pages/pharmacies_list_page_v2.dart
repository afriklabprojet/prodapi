import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/pharmacy_entity.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/router/app_router.dart';
import '../providers/pharmacies_state.dart';

// Provider ID for this page
const _searchQueryId = 'pharmacies_v2_search_query';

class PharmaciesListPageV2 extends ConsumerStatefulWidget {
  const PharmaciesListPageV2({super.key});

  @override
  ConsumerState<PharmaciesListPageV2> createState() => _PharmaciesListPageV2State();
}

enum PharmacyTab { all, nearby, onDuty }

class _PharmaciesListPageV2State extends ConsumerState<PharmaciesListPageV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  
  // _currentPosition kept as setState (complex GPS type)
  Position? _currentPosition;
  // _searchQuery migrated to formFieldsProvider

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    
    // Fetch pharmacies on initial load
    Future.microtask(() {
      ref.read(pharmaciesProvider.notifier).fetchPharmacies(refresh: true);
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    switch (_tabController.index) {
      case 0:
        ref.read(pharmaciesProvider.notifier).fetchPharmacies(refresh: true);
        break;
      case 1:
        _fetchNearbyPharmacies();
        break;
      case 2:
        _fetchOnDutyPharmacies();
        break;
    }
  }

  void _onScroll() {
    if (_isBottom && _tabController.index == 0) {
      ref.read(pharmaciesProvider.notifier).fetchPharmacies();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 15),
        );
      }

      if (!mounted) return;
      setState(() => _currentPosition = position);
    } catch (e) {
      AppLogger.warning('Error getting location: $e');
    }
  }

  Future<void> _fetchNearbyPharmacies() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    if (_currentPosition != null) {
      await ref.read(pharmaciesProvider.notifier).fetchNearbyPharmacies(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            radius: 25.0,
          );
    } else {
      _showLocationRequiredSnackBar();
    }
  }

  Future<void> _fetchOnDutyPharmacies() async {
    await ref.read(pharmaciesProvider.notifier).fetchOnDutyPharmacies(
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
        );
  }

  void _showLocationRequiredSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.white),
            SizedBox(width: 12),
            Text('Activez la localisation pour cette fonctionnalité'),
          ],
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Activer',
          textColor: Colors.white,
          onPressed: () => Geolocator.openLocationSettings(),
        ),
      ),
    );
  }

  List<PharmacyEntity> _getFilteredPharmacies(PharmaciesState state) {
    List<PharmacyEntity> sourceList;
    
    switch (_tabController.index) {
      case 1:
        sourceList = state.nearbyPharmacies;
        break;
      case 2:
        sourceList = state.onDutyPharmacies;
        break;
      default:
        sourceList = state.pharmacies;
    }

    final searchQuery = ref.read(formFieldsProvider(_searchQueryId))['query'] ?? '';
    if (searchQuery.isEmpty) return sourceList;

    return sourceList.where((pharmacy) {
      final nameLower = pharmacy.name.toLowerCase();
      final addressLower = pharmacy.address.toLowerCase();
      final queryLower = searchQuery.toLowerCase();
      return nameLower.contains(queryLower) || addressLower.contains(queryLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pharmaciesState = ref.watch(pharmaciesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(pharmaciesState),
        ],
        body: Column(
          children: [
            _buildSearchBar(),
            _buildStatsHeader(pharmaciesState),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  switch (_tabController.index) {
                    case 1:
                      await _fetchNearbyPharmacies();
                      break;
                    case 2:
                      await _fetchOnDutyPharmacies();
                      break;
                    default:
                      await ref.read(pharmaciesProvider.notifier).fetchPharmacies(refresh: true);
                  }
                },
                child: _buildPharmacyList(pharmaciesState),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.goToPharmaciesMap(
            pharmacies: _getFilteredPharmacies(pharmaciesState),
            userLatitude: _currentPosition?.latitude,
            userLongitude: _currentPosition?.longitude,
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.map, color: Colors.white),
      ),
    );
  }

  Widget _buildSliverAppBar(PharmaciesState state) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 60),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Trouvez votre pharmacie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _currentPosition != null
                  ? '📍 Localisation activée'
                  : '📍 Activez la localisation',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(
            icon: Icon(Icons.list_alt, size: 20),
            text: 'Toutes',
          ),
          Tab(
            icon: Icon(Icons.near_me, size: 20),
            text: 'Proximité',
          ),
          Tab(
            icon: Icon(Icons.emergency, size: 20),
            text: 'De garde',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchQuery = ref.watch(formFieldsProvider(_searchQueryId))['query'] ?? '';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => ref.read(formFieldsProvider(_searchQueryId).notifier).setField('query', value),
        decoration: InputDecoration(
          hintText: 'Rechercher une pharmacie...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(formFieldsProvider(_searchQueryId).notifier).setField('query', '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(PharmaciesState state) {
    final pharmacies = _getFilteredPharmacies(state);
    final openCount = pharmacies.where((p) => p.isOpen).length;
    final onDutyCount = pharmacies.where((p) => p.isOnDuty).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        children: [
          _buildStatChip(
            icon: Icons.local_pharmacy,
            label: '${pharmacies.length}',
            subtitle: 'Total',
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.check_circle,
            label: '$openCount',
            subtitle: 'Ouvertes',
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.emergency,
            label: '$onDutyCount',
            subtitle: 'De garde',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyList(PharmaciesState state) {
    // Check if the current tab's list is empty while loading
    final isCurrentListEmpty = _tabController.index == 0
        ? state.pharmacies.isEmpty
        : _tabController.index == 1
            ? state.nearbyPharmacies.isEmpty
            : state.onDutyPharmacies.isEmpty;
    
    if (state.status == PharmaciesStatus.loading && isCurrentListEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des pharmacies...'),
          ],
        ),
      );
    }

    // Show error state with retry
    if (state.status == PharmaciesStatus.error && isCurrentListEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Erreur de connexion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? 'Vérifiez votre connexion internet',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  switch (_tabController.index) {
                    case 1:
                      _fetchNearbyPharmacies();
                      break;
                    case 2:
                      _fetchOnDutyPharmacies();
                      break;
                    default:
                      ref.read(pharmaciesProvider.notifier).fetchPharmacies(refresh: true);
                  }
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

    final pharmacies = _getFilteredPharmacies(state);

    if (pharmacies.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: pharmacies.length + (!state.hasReachedMax && _tabController.index == 0 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= pharmacies.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final pharmacy = pharmacies[index];
        return _buildEnhancedPharmacyCard(pharmacy);
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    String? subtitle;
    IconData icon;
    final searchQuery = ref.read(formFieldsProvider(_searchQueryId))['query'] ?? '';
    
    switch (_tabController.index) {
      case 1:
        if (_currentPosition == null) {
          message = 'Localisation désactivée';
          subtitle = 'Activez la localisation pour trouver les pharmacies à proximité';
          icon = Icons.location_off;
        } else {
          message = 'Aucune pharmacie trouvée';
          subtitle = 'Vérifiez votre connexion internet et réessayez';
          icon = Icons.local_pharmacy_outlined;
        }
        break;
      case 2:
        message = 'Aucune pharmacie de garde actuellement';
        icon = Icons.emergency;
        break;
      default:
        message = searchQuery.isNotEmpty
            ? 'Aucun résultat pour "$searchQuery"'
            : 'Aucune pharmacie disponible';
        icon = Icons.search_off;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (_tabController.index == 1) ...[
            const SizedBox(height: 20),
            if (_currentPosition == null)
            ElevatedButton.icon(
              onPressed: () async {
                await _getCurrentLocation();
                if (_currentPosition != null) {
                  _fetchNearbyPharmacies();
                }
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Activer la localisation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            )
            else
              ElevatedButton.icon(
                onPressed: _fetchNearbyPharmacies,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _buildEnhancedPharmacyCard(PharmacyEntity pharmacy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.pushToPharmacyDetails(pharmacy.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: pharmacy.isOnDuty
                              ? [Colors.orange.shade400, Colors.orange.shade600]
                              : pharmacy.isOpen
                                  ? [AppColors.success.withValues(alpha: 0.8), AppColors.success]
                                  : [Colors.grey.shade400, Colors.grey.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          pharmacy.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pharmacy.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (pharmacy.isOnDuty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.emergency,
                                        size: 12,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Garde',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  pharmacy.address,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: pharmacy.isOpen
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: pharmacy.isOpen
                                            ? AppColors.success
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pharmacy.isOpen ? 'Ouverte' : 'Fermée',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: pharmacy.isOpen
                                            ? AppColors.success
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Distance if available
                              if (pharmacy.distance != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.near_me,
                                        size: 12,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDistance(pharmacy.distance!),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Action buttons
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone,
                        label: 'Appeler',
                        color: AppColors.success,
                        onTap: pharmacy.phone != null
                            ? () => UrlLauncherService.makePhoneCall(pharmacy.phone!)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.directions,
                        label: 'Itinéraire',
                        color: AppColors.primary,
                        onTap: pharmacy.latitude != null && pharmacy.longitude != null
                            ? () => UrlLauncherService.openMap(
                                  latitude: pharmacy.latitude!,
                                  longitude: pharmacy.longitude!,
                                  label: pharmacy.name,
                                )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.info_outline,
                        label: 'Détails',
                        color: Colors.grey[700]!,
                        onTap: () => context.pushToPharmacyDetails(pharmacy.id),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    
    return Material(
      color: isDisabled ? Colors.grey[200] : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDisabled ? Colors.grey[400] : color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? Colors.grey[400] : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
