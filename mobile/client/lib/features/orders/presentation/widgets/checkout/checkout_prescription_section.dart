import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../prescription_requirement_section.dart';

/// Shows the prescription-requirement notice when the cart contains items
/// that require a medical prescription.
///
/// Returns [SizedBox.shrink] when no prescription is needed, so the caller
/// never needs an `if` guard.
class CheckoutPrescriptionSection extends ConsumerWidget {
  const CheckoutPrescriptionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final required = ref.watch(
      cartProvider.select((s) => s.hasPrescriptionRequiredItems),
    );
    if (!required) return const SizedBox.shrink();

    final names = ref.watch(
      cartProvider.select((s) => s.prescriptionRequiredProductNames),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ordonnance médicale',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        PrescriptionRequirementSection(requiredProductNames: names),
        const SizedBox(height: 24),
      ],
    );
  }
}
