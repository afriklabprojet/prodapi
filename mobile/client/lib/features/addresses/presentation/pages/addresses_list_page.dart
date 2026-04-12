import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/addresses_provider.dart';
import '../../domain/entities/address_entity.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../widgets/address_card.dart';

class AddressesListPage extends ConsumerStatefulWidget {
  final bool selectionMode;

  const AddressesListPage({super.key, this.selectionMode = false});

  @override
  ConsumerState<AddressesListPage> createState() => _AddressesListPageState();
}

class _AddressesListPageState extends ConsumerState<AddressesListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    Future.microtask(() {
      ref.read(addressesProvider.notifier).loadAddresses();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nom, adresse, ville...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(
                widget.selectionMode ? 'Choisir une adresse' : 'Mes adresses',
              ),
        leading: IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.arrow_back),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              });
            } else {
              context.canPop() ? context.pop() : context.go('/home');
            }
          },
        ),
        actions: [
          if (!_isSearching && !state.isLoading && state.addresses.length > 3)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              tooltip: 'Rechercher',
            ),
        ],
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/addresses/add'),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Ajouter'),
            ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AddressesState state) {
    if (state.isLoading && state.addresses.isEmpty) {
      return const _AddressListSkeleton();
    }

    if (state.error != null && state.addresses.isEmpty) {
      return _buildErrorState(state.error);
    }

    if (state.addresses.isEmpty) {
      return _buildEmptyState();
    }

    final filteredAddresses = _searchQuery.isEmpty
        ? state.addresses
        : state.addresses.where((address) {
            final query = _searchQuery.toLowerCase();
            return address.label.toLowerCase().contains(query) ||
                address.address.toLowerCase().contains(query) ||
                (address.city?.toLowerCase().contains(query) ?? false);
          }).toList();

    return Column(
      children: [
        if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(addressesProvider.notifier).loadAddresses(),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredAddresses.length,
                  itemBuilder: (context, index) {
                    final address = filteredAddresses[index];
                    final animation = Tween<double>(begin: 0.0, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              (index / filteredAddresses.length) * 0.5,
                              ((index + 1) / filteredAddresses.length) * 0.5 +
                                  0.5,
                              curve: Curves.easeOut,
                            ),
                          ),
                        );

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(
                            begin: const Offset(0.3, 0),
                            end: Offset.zero,
                          ),
                        ),
                        child: AddressCard(
                          key: ValueKey(address.id),
                          address: address,
                          onTap: () => _handleAddressTap(address),
                          onDefault: () => _handleSetDefault(address.id),
                          onDelete: () => _handleDelete(address.id),
                          showActions: !widget.selectionMode,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Impossible de charger vos adresses',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(addressesProvider.notifier).loadAddresses(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_location_alt_outlined,
                size: 70,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Aucune adresse',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ajoutez une adresse de livraison\npour faciliter vos commandes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => context.push('/addresses/add'),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une adresse'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddressTap(AddressEntity address) {
    if (widget.selectionMode) {
      context.pop(address);
    } else {
      context.push('/addresses/${address.id}/edit', extra: address);
    }
  }

  Future<void> _handleSetDefault(int addressId) async {
    await ref.read(addressesProvider.notifier).setDefaultAddress(addressId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Adresse définie par défaut'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDelete(int addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'adresse'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette adresse ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(addressesProvider.notifier).deleteAddress(addressId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Adresse supprimée'),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Widget de skeleton pour le chargement de la liste d'adresses
class _AddressListSkeleton extends StatelessWidget {
  const _AddressListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerLoading(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLoading(width: 150, height: 16),
                          SizedBox(height: 8),
                          ShimmerLoading(width: 100, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const ShimmerLoading(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 200, height: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}
