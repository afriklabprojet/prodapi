import 'package:flutter/material.dart';

/// Premium card wrapper with animated scale and shadow on tap
class PremiumPharmacyCardWrapper extends StatefulWidget {
  final Widget child;
  final Color accentColor;

  const PremiumPharmacyCardWrapper({
    super.key,
    required this.child,
    required this.accentColor,
  });

  @override
  State<PremiumPharmacyCardWrapper> createState() =>
      _PremiumPharmacyCardWrapperState();
}

class _PremiumPharmacyCardWrapperState
    extends State<PremiumPharmacyCardWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? widget.accentColor.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: _isPressed ? 20 : 16,
                offset: Offset(0, _isPressed ? 8 : 6),
                spreadRadius: _isPressed ? 2 : 0,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
