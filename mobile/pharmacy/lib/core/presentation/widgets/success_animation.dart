import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget d'animation de succès pour les actions critiques.
/// Crée un effet de satisfaction visuelle + haptique.
/// 
/// Utilisé après : confirmation commande, paiement reçu, ordonnance validée.
class SuccessAnimation extends StatefulWidget {
  /// Callback appelé à la fin de l'animation
  final VoidCallback? onComplete;
  
  /// Taille de l'animation (défaut: 120)
  final double size;
  
  /// Couleur principale (défaut: vert médical)
  final Color? color;
  
  /// Message affiché sous l'animation
  final String? message;
  
  /// Durée totale de l'animation
  final Duration duration;

  const SuccessAnimation({
    this.onComplete,
    this.size = 120,
    this.color,
    this.message,
    this.duration = const Duration(milliseconds: 1500),
    super.key,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _circleController;
  late final AnimationController _checkController;
  late final AnimationController _scaleController;
  late final AnimationController _particleController;
  
  late final Animation<double> _circleAnimation;
  late final Animation<double> _checkAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Circle drawing animation
    _circleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 3),
    );
    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOut),
    );
    
    // Check mark drawing animation
    _checkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 3),
    );
    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeInOut),
    );
    
    // Scale bounce animation
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Particle explosion animation
    _particleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 2),
    );
    _particleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );
    
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Haptic feedback au début
    HapticFeedback.lightImpact();
    
    // Démarrer le cercle
    _circleController.forward();
    _scaleController.forward();
    
    await Future.delayed(Duration(milliseconds: widget.duration.inMilliseconds ~/ 3));
    
    // Haptic feedback au checkmark
    HapticFeedback.mediumImpact();
    
    // Démarrer le checkmark et les particules
    _checkController.forward();
    _particleController.forward();
    
    await Future.delayed(Duration(milliseconds: widget.duration.inMilliseconds * 2 ~/ 3));
    
    // Haptic feedback final
    HapticFeedback.heavyImpact();
    
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF2E7D32);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            _circleAnimation,
            _checkAnimation,
            _scaleAnimation,
            _particleAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Particules de célébration
                    ..._buildParticles(color),
                    
                    // Cercle de fond
                    CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _CirclePainter(
                        progress: _circleAnimation.value,
                        color: color,
                      ),
                    ),
                    
                    // Checkmark
                    CustomPaint(
                      size: Size(widget.size * 0.5, widget.size * 0.5),
                      painter: _CheckPainter(
                        progress: _checkAnimation.value,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          AnimatedOpacity(
            opacity: _checkAnimation.value,
            duration: const Duration(milliseconds: 300),
            child: Text(
              widget.message!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildParticles(Color color) {
    final particles = <Widget>[];
    const particleCount = 8;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = widget.size * 0.8 * _particleAnimation.value;
      final opacity = (1 - _particleAnimation.value).clamp(0.0, 1.0);
      
      particles.add(
        Transform.translate(
          offset: Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance,
          ),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }
    return particles;
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  
  _CirclePainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;
    
    // Fond du cercle (rempli progressivement)
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * progress, fillPaint);
    
    // Bordure du cercle
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, strokePaint);
  }
  
  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  _CheckPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final path = Path();
    
    // Points du checkmark
    final start = Offset(size.width * 0.2, size.height * 0.5);
    final middle = Offset(size.width * 0.4, size.height * 0.7);
    final end = Offset(size.width * 0.8, size.height * 0.3);
    
    // Première partie (start -> middle)
    if (progress <= 0.5) {
      final p = progress * 2;
      path.moveTo(start.dx, start.dy);
      path.lineTo(
        start.dx + (middle.dx - start.dx) * p,
        start.dy + (middle.dy - start.dy) * p,
      );
    } else {
      // Première partie complète + deuxième partie
      path.moveTo(start.dx, start.dy);
      path.lineTo(middle.dx, middle.dy);
      
      final p = (progress - 0.5) * 2;
      path.lineTo(
        middle.dx + (end.dx - middle.dx) * p,
        middle.dy + (end.dy - middle.dy) * p,
      );
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Helper pour afficher l'animation de succès dans un dialog
Future<void> showSuccessAnimation(
  BuildContext context, {
  String? message,
  VoidCallback? onComplete,
  Duration duration = const Duration(milliseconds: 1500),
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SuccessAnimation(
            message: message,
            duration: duration,
            onComplete: () {
              Navigator.of(context).pop();
              onComplete?.call();
            },
          ),
        ),
      ),
    ),
  );
}
