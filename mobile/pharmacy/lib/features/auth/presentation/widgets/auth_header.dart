import 'package:flutter/material.dart';

/// Reusable header widget for authentication pages (login/register).
/// Displays the DR-PHARMA logo and brand name with optional subtitle.
class AuthHeader extends StatelessWidget {
  final String subtitle;
  final double logoSize;

  const AuthHeader({
    super.key,
    this.subtitle = 'Espace Pharmacie',
    this.logoSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 760 || size.width < 380;
    final effectiveLogoSize = isCompact ? logoSize * 0.82 : logoSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.png',
            width: effectiveLogoSize,
            height: effectiveLogoSize,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: isCompact ? 16 : 20),
        Text(
          'DR-PHARMA',
          style: TextStyle(
            fontSize: isCompact ? 26 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: isCompact ? 2 : 3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 16,
            vertical: isCompact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: isCompact ? 13 : 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
