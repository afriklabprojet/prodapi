import 'package:flutter/material.dart';

/// Control button at bottom of scanner.
class ScannerControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const ScannerControlButton({
    super.key,
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (badge != null)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Corner position enum for scanner overlay.
enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

/// Corner decoration widget for scanner overlay.
class ScannerCorner extends StatelessWidget {
  final double size;
  final double width;
  final Color color;
  final CornerPosition position;

  const ScannerCorner({
    super.key,
    required this.size,
    required this.width,
    required this.color,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          width: width,
          position: position,
        ),
      ),
    );
  }
}

/// Paints corner decorations.
class _CornerPainter extends CustomPainter {
  final Color color;
  final double width;
  final CornerPosition position;

  _CornerPainter({
    required this.color,
    required this.width,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (position) {
      case CornerPosition.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
        break;
      case CornerPosition.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case CornerPosition.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case CornerPosition.bottomRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return color != oldDelegate.color ||
        width != oldDelegate.width ||
        position != oldDelegate.position;
  }
}

/// Scanner overlay painter — dims area outside scan window.
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color borderColor;

  ScannerOverlayPainter({
    required this.scanWindow,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final scanWindowPath = Path()
      ..addRRect(
          RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)));

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanWindowPath,
    );

    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return scanWindow != oldDelegate.scanWindow ||
        borderColor != oldDelegate.borderColor;
  }
}
