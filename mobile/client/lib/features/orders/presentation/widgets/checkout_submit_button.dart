import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Bouton de validation de commande (checkout)
class CheckoutSubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final String totalFormatted;
  final VoidCallback onPressed;

  const CheckoutSubmitButton({
    super.key,
    required this.isSubmitting,
    required this.totalFormatted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_checkout, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Commander • $totalFormatted',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
