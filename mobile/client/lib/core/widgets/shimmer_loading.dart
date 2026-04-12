import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Widget de chargement shimmer pour les listes
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  /// Crée un placeholder rectangulaire shimmer
  factory ShimmerLoading.rectangle({
    double width = double.infinity,
    double height = 16,
    double radius = 4,
  }) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Crée un placeholder circulaire shimmer
  factory ShimmerLoading.circle({double size = 48}) {
    return ShimmerLoading(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: const [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Helper widget pour créer une card shimmer type produit
class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading.rectangle(height: 120, radius: 8),
          const SizedBox(height: 8),
          ShimmerLoading.rectangle(height: 14, width: 100),
          const SizedBox(height: 4),
          ShimmerLoading.rectangle(height: 12, width: 60),
        ],
      ),
    );
  }
}

/// Alias pour compatibilité (utilise ShimmerProductCard)
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerProductCard();
  }
}

/// Skeleton pour une liste de produits (grille 2 colonnes)
class ProductsListSkeleton extends StatelessWidget {
  const ProductsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerProductCard(),
    );
  }
}

/// Skeleton pour la page profil
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 32),
          ShimmerLoading.circle(size: 120),
          const SizedBox(height: 16),
          ShimmerLoading.rectangle(height: 20, width: 150),
          const SizedBox(height: 8),
          ShimmerLoading.rectangle(height: 14, width: 200),
          const SizedBox(height: 32),
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ShimmerLoading.rectangle(height: 56, radius: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton pour la liste de notifications
class NotificationsListSkeleton extends StatelessWidget {
  const NotificationsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ShimmerLoading.circle(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading.rectangle(height: 14, width: 180),
                  const SizedBox(height: 8),
                  ShimmerLoading.rectangle(height: 12),
                  const SizedBox(height: 6),
                  ShimmerLoading.rectangle(height: 10, width: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton pour la page portefeuille
class WalletSkeleton extends StatelessWidget {
  const WalletSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerLoading.rectangle(height: 160, radius: 16),
          const SizedBox(height: 24),
          ShimmerLoading.rectangle(height: 20, width: 150),
          const SizedBox(height: 16),
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerLoading.rectangle(height: 64, radius: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton pour une liste simple (adresses, prescriptions, pharmacies)
class ListItemSkeleton extends StatelessWidget {
  final int itemCount;
  const ListItemSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLoading.rectangle(height: 16, width: 200),
              const SizedBox(height: 10),
              ShimmerLoading.rectangle(height: 12),
              const SizedBox(height: 6),
              ShimmerLoading.rectangle(height: 12, width: 140),
            ],
          ),
        ),
      ),
    );
  }
}
