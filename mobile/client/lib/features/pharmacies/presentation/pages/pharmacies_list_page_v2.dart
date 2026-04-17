import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/pharmacy_entity.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../providers/pharmacies_state.dart';
import '../widgets/premium_pharmacy_card_wrapper.dart';

// Provider ID for this page
const _searchQueryId = 'pharmacies_v2_search_query';

class PharmaciesListPageV2 extends ConsumerStatefulWidget {
  const PharmaciesListPageV2({super.key});

  @override
  ConsumerState<PharmaciesListPageV2> createState() =>
      _PharmaciesListPageV2State();
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
    HapticFeedback.selectionClick();

    final pharmaciesState = ref.read(pharmaciesProvider);

    switch (_tabController.index) {
      case 0:
        // Ne re-fetch que si pas encore chargé ou en erreur
        if (pharmaciesState.pharmacies.isEmpty ||
            pharmaciesState.status == PharmaciesStatus.error) {
          ref.read(pharmaciesProvider.notifier).fetchPharmacies(refresh: true);
        }
        break;
      case 1:
        // Ne re-fetch que si pas encore chargé ou en erreur
        if (pharmaciesState.nearbyPharmacies.isEmpty ||
            pharmaciesState.status == PharmaciesStatus.error) {
          _fetchNearbyPharmacies();
        }
        break;
      case 2:
        // Ne re-fetch que si pas encore chargé ou en erreur
        if (pharmaciesState.onDutyPharmacies.isEmpty ||
            pharmaciesState.status == PharmaciesStatus.error) {
          _fetchOnDutyPharmacies();
        }
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
      await ref
          .read(pharmaciesProvider.notifier)
          .fetchNearbyPharmacies(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            radius: 25.0,
          );
    } else {
      _showLocationRequiredSnackBar();
    }
  }

  Future<void> _fetchOnDutyPharmacies() async {
    await ref
        .read(pharmaciesProvider.notifier)
        .fetchOnDutyPharmacies(
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
        );
  }

  void _showLocationRequiredSnackBar() {
    AppSnackbar.warning(
      context,
      'Activez la localisation pour cette fonctionnalité',
      actionLabel: 'Activer',
      onAction: () => Geolocator.openLocationSettings(),
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

    final searchQuery =
        ref.read(formFieldsProvider(_searchQueryId))['query'] ?? '';
    if (searchQuery.isEmpty) return sourceList;

    return sourceList.where((pharmacy) {
      final nameLower = pharmacy.name.toLowerCase();
      final addressLower = pharmacy.address.toLowerCase();
      final queryLower = searchQuery.toLowerCase();
      return nameLower.contains(queryLower) ||
          addressLower.contains(queryLower);
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
                      await ref
                          .read(pharmaciesProvider.notifier)
                          .fetchPharmacies(refresh: true);
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
          HapticFeedback.lightImpact();
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
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 70),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône décorative
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_pharmacy_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Trouvez votre pharmacie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPosition != null
                          ? const Color(0xFF4ADE80)
                          : Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_currentPosition != null
                                      ? const Color(0xFF4ADE80)
                                      : Colors.orange)
                                  .withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentPosition != null
                        ? 'Localisation activée'
                        : 'Activez la localisation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient de fond
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
              ),
            ),
            // Motifs décoratifs
            Positioned(
              right: -50,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: 30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
            ),
            dividerColor: Colors.transparent,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            tabs: [
              _buildPremiumTab(Icons.list_alt_rounded, 'Toutes', 0),
              _buildPremiumTab(Icons.near_me_rounded, 'Proximité', 1),
              _buildPremiumTab(Icons.emergency_rounded, 'De garde', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTab(IconData icon, String label, int index) {
    // Tab animation handled by TabBar indicator
    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchQuery =
        ref.watch(formFieldsProvider(_searchQueryId))['query'] ?? '';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref
                    .read(formFieldsProvider(_searchQueryId).notifier)
                    .setField('query', value),
                decoration: InputDecoration(
                  hintText: 'Rechercher une pharmacie...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (searchQuery.isNotEmpty)
              Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(formFieldsProvider(_searchQueryId).notifier)
                            .setField('query', '');
                      },
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(PharmaciesState state) {
    final pharmacies = _getFilteredPharmacies(state);
    final openCount = pharmacies.where((p) => p.isOpen).length;
    final onDutyCount = pharmacies.where((p) => p.isOnDuty == true).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStatChip(
            icon: Icons.local_pharmacy_rounded,
            label: '${pharmacies.length}',
            subtitle: 'Total',
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildStatChip(
            icon: Icons.check_circle_rounded,
            label: '$openCount',
            subtitle: 'Ouvertes',
            color: AppColors.success,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildStatChip(
            icon: Icons.emergency_rounded,
            label: '$onDutyCount',
            subtitle: 'De garde',
            color: AppColors.onDuty,
            isDark: isDark,
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
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: isDark ? 0.15 : 0.08),
              color.withValues(alpha: isDark ? 0.08 : 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white : color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : color.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
      return const ListItemSkeleton(itemCount: 6);
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
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
                  HapticFeedback.lightImpact();
                  switch (_tabController.index) {
                    case 1:
                      _fetchNearbyPharmacies();
                      break;
                    case 2:
                      _fetchOnDutyPharmacies();
                      break;
                    default:
                      ref
                          .read(pharmaciesProvider.notifier)
                          .fetchPharmacies(refresh: true);
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
      itemCount:
          pharmacies.length +
          (!state.hasReachedMax && _tabController.index == 0 ? 1 : 0),
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
    final searchQuery =
        ref.read(formFieldsProvider(_searchQueryId))['query'] ?? '';

    switch (_tabController.index) {
      case 1:
        if (_currentPosition == null) {
          message = 'Localisation désactivée';
          subtitle =
              'Activez la localisation pour trouver les pharmacies à proximité';
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
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[500]
                  : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[500]
                      : Colors.grey[500],
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
    // Determine card accent color based on status
    final Color accentColor = pharmacy.isOnDuty == true
        ? Colors.orange
        : pharmacy.isOpen
        ? AppColors.success
        : Colors.grey;

    final List<Color> gradientColors = pharmacy.isOnDuty == true
        ? [Colors.orange.shade400, Colors.orange.shade600]
        : pharmacy.isOpen
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : [Colors.grey.shade400, Colors.grey.shade500];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: PremiumPharmacyCardWrapper(
        accentColor: accentColor,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.pushToPharmacyDetails(pharmacy.id),
                borderRadius: BorderRadius.circular(20),
                splashColor: accentColor.withValues(alpha: 0.1),
                highlightColor: accentColor.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Premium Avatar with shadow
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  // Decorative pattern
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      pharmacy.name
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  // On duty indicator
                                  if (pharmacy.isOnDuty == true)
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange.withValues(
                                                alpha: 0.4,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.emergency,
                                          size: 14,
                                          color: Colors.orange.shade600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Info Section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name row with On duty badge
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pharmacy.name,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : const Color(0xFF1A1A1A),
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (pharmacy.isOnDuty == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange.shade400,
                                              Colors.orange.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.shield_moon,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Garde',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Address with icon container
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        pharmacy.address,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Status badges row
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    // Open/Closed status badge
                                    _buildStatusBadge(
                                      icon: pharmacy.isOpen
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      label: pharmacy.isOpen
                                          ? 'Ouverte'
                                          : 'Fermée',
                                      color: pharmacy.isOpen
                                          ? AppColors.success
                                          : Colors.red,
                                      hasGlow: pharmacy.isOpen,
                                    ),

                                    // Distance badge
                                    if (pharmacy.distance != null)
                                      _buildStatusBadge(
                                        icon: Icons.near_me_rounded,
                                        label: _formatDistance(
                                          pharmacy.distance!,
                                        ),
                                        color: AppColors.primary,
                                        hasGlow: false,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                accentColor.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Premium Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildPremiumActionButton(
                              icon: Icons.phone_rounded,
                              label: 'Appeler',
                              gradientColors: [
                                const Color(0xFF10B981),
                                const Color(0xFF059669),
                              ],
                              onTap: pharmacy.phone.isNotEmpty
                                  ? () => UrlLauncherService.makePhoneCall(
                                      pharmacy.phone,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPremiumActionButton(
                              icon: Icons.directions_rounded,
                              label: 'Itinéraire',
                              gradientColors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.8),
                              ],
                              onTap:
                                  pharmacy.latitude != null &&
                                      pharmacy.longitude != null
                                  ? () => UrlLauncherService.openMap(
                                      latitude: pharmacy.latitude!,
                                      longitude: pharmacy.longitude!,
                                      label: pharmacy.name,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPremiumActionButton(
                              icon: Icons.arrow_forward_rounded,
                              label: 'Détails',
                              gradientColors: [
                                const Color(0xFF6366F1),
                                const Color(0xFF4F46E5),
                              ],
                              onTap: () =>
                                  context.pushToPharmacyDetails(pharmacy.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool hasGlow,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumActionButton({
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : LinearGradient(
                    colors: [
                      gradientColors[0].withValues(alpha: 0.1),
                      gradientColors[1].withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isDisabled ? Colors.grey.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled
                  ? Colors.grey.withValues(alpha: 0.2)
                  : gradientColors[0].withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isDisabled
                      ? null
                      : LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: isDisabled ? Colors.grey[300] : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isDisabled
                      ? null
                      : [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDisabled ? Colors.grey[400] : Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? Colors.grey[400] : gradientColors[0],
                  letterSpacing: 0.2,
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
