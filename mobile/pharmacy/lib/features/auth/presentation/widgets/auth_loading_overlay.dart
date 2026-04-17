import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Full-screen loading overlay for authentication processes.
/// Shows a blurred background with a centered progress indicator and message.
///
/// @deprecated Use [LoadingOverlay] from core/presentation/widgets instead.
/// This widget will be removed in a future version.
@Deprecated('Use LoadingOverlay from core/presentation/widgets instead')
class AuthLoadingOverlay extends StatelessWidget {
  final String? message;
  final Color primaryColor;

  const AuthLoadingOverlay({
    super.key,
    this.message,
    this.primaryColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
