import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/providers/ui_state_providers.dart';
import '../../../../../core/providers/theme_provider.dart';
import '../../mixins/checkout_logic_mixin.dart';
import '../../providers/cart_provider.dart';
import '../../providers/pricing_provider.dart';

/// Displays available payment modes based on admin config.
/// Single mode → info card. Multiple modes → selector.
class CheckoutPaymentSection extends ConsumerWidget {
  const CheckoutPaymentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentModes = ref.watch(
      pricingProvider.select((s) => s.paymentModes),
    );
    final selectedMode = ref.watch(
      formFieldsProvider(
        checkoutPaymentModeId,
      ).select((m) => m['mode'] ?? AppConstants.paymentModePlatform),
    );

    // Collect enabled modes
    final enabledModes = <_PaymentModeOption>[];
    if (paymentModes.platformEnabled) {
      enabledModes.add(
        _PaymentModeOption(
          value: AppConstants.paymentModePlatform,
          title: 'Paiement en ligne',
          subtitle: 'Payez par mobile money (Orange, MTN, Wave...)',
          icon: Icons.phone_android,
        ),
      );
    }
    if (paymentModes.walletEnabled) {
      enabledModes.add(
        _PaymentModeOption(
          value: AppConstants.paymentModeWallet,
          title: 'Portefeuille DR-Pharma',
          subtitle: 'Payez avec votre solde disponible',
          icon: Icons.account_balance_wallet,
        ),
      );
    }

    // Fallback: at least platform
    if (enabledModes.isEmpty) {
      enabledModes.add(
        _PaymentModeOption(
          value: AppConstants.paymentModePlatform,
          title: 'Paiement en ligne',
          subtitle: 'Payez par mobile money (Orange, MTN, Wave...)',
          icon: Icons.phone_android,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mode de paiement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...enabledModes.map((option) {
          final isSelected =
              enabledModes.length == 1 || selectedMode == option.value;
          return _PaymentModeCard(
            option: option,
            isSelected: isSelected,
            showRadio: enabledModes.length > 1,
            onTap: enabledModes.length > 1
                ? () {
                    ref
                        .read(
                          formFieldsProvider(checkoutPaymentModeId).notifier,
                        )
                        .setField('mode', option.value);
                    ref
                        .read(cartProvider.notifier)
                        .updatePaymentMode(option.value);
                  }
                : null,
          );
        }),
      ],
    );
  }
}

class _PaymentModeOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  const _PaymentModeOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _PaymentModeCard extends StatelessWidget {
  final _PaymentModeOption option;
  final bool isSelected;
  final bool showRadio;
  final VoidCallback? onTap;

  const _PaymentModeCard({
    required this.option,
    required this.isSelected,
    required this.showRadio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primary : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : context.inputFillColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    option.icon,
                    color: isSelected
                        ? AppColors.primary
                        : context.secondaryText,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.primary
                              : context.primaryText,
                        ),
                      ),
                      Text(
                        option.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showRadio)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : context.hintColor,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  )
                else
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
