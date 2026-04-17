import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/animations.dart';

/// Skeleton loaders for dashboard financial cards, order rows, and prescription rows.
/// Extracted so they can be reused and tested independently.

class FinancialCardSkeleton extends StatelessWidget {
  const FinancialCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerLoading(width: 36, height: 36, borderRadius: 10),
              Spacer(),
              ShimmerLoading(width: 14, height: 14, borderRadius: 4),
            ],
          ),
          SizedBox(height: 12),
          ShimmerLoading(width: 60, height: 13),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerLoading(width: 80, height: 24),
              SizedBox(width: 4),
              ShimmerLoading(width: 30, height: 11),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderRowSkeleton extends StatelessWidget {
  const OrderRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          ShimmerLoading(width: 44, height: 44, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 100, height: 14),
                SizedBox(height: 6),
                ShimmerLoading(width: 80, height: 12),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerLoading(width: 70, height: 14),
              SizedBox(height: 6),
              ShimmerLoading(width: 60, height: 20, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class PrescriptionRowSkeleton extends StatelessWidget {
  const PrescriptionRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          ShimmerLoading(width: 44, height: 44, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 120, height: 14),
                SizedBox(height: 6),
                ShimmerLoading(width: 100, height: 12),
              ],
            ),
          ),
          ShimmerLoading(width: 70, height: 24, borderRadius: 8),
        ],
      ),
    );
  }
}

/// Generates a repeating list of skeleton rows.
class SkeletonList extends StatelessWidget {
  final int count;
  final Widget Function() itemBuilder;

  const SkeletonList({super.key, this.count = 3, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: itemBuilder(),
        ),
      ),
    );
  }
}
