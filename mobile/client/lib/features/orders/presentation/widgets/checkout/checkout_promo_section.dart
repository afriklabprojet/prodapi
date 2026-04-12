import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../providers/cart_provider.dart';
import '../../providers/promo_code_provider.dart';

/// Section code promo dans le checkout
class CheckoutPromoSection extends ConsumerStatefulWidget {
  const CheckoutPromoSection({super.key});

  @override
  ConsumerState<CheckoutPromoSection> createState() => _CheckoutPromoSectionState();
}

class _CheckoutPromoSectionState extends ConsumerState<CheckoutPromoSection> {
  final _controller = TextEditingController();

  static final _currency = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promoState = ref.watch(promoCodeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.discount_outlined,
              color: promoState.hasDiscount ? AppColors.success : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              promoState.hasDiscount
                  ? 'Code promo appliqué'
                  : 'Code promo',
              style: TextStyle(
                color: promoState.hasDiscount ? AppColors.success : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (promoState.hasDiscount) ...[
              const Spacer(),
              Text(
                '-${_currency.format(promoState.discount)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Input field - always visible when no discount applied
        if (!promoState.hasDiscount)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Entrez votre code promo',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : AppColors.textHint,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                    errorText: promoState.error,
                    errorMaxLines: 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: promoState.isValidating
                      ? null
                      : () {
                          if (_controller.text.trim().isEmpty) return;
                          final cartTotal = ref.read(cartProvider).total;
                          ref.read(promoCodeProvider.notifier).validate(
                            _controller.text.trim(),
                            cartTotal,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(88, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: promoState.isValidating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Appliquer'),
                ),
              ),
            ],
          ),

        // Applied promo - show code and remove button
        if (promoState.hasDiscount)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promoState.code!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      if (promoState.description != null)
                        Text(
                          promoState.description!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(promoCodeProvider.notifier).clear();
                    _controller.clear();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Retirer'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
