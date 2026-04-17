import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class OtpBackgroundDecor extends StatelessWidget {
  final bool isDark;
  const OtpBackgroundDecor({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        AppColors.primary.withValues(alpha: 0.08),
                        Colors.transparent,
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        AppColors.primary.withValues(alpha: 0.05),
                        Colors.transparent,
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
