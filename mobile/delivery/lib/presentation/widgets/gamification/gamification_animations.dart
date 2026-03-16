import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/gamification.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ANIMATION DE DÉBLOCAGE DE BADGE
// ══════════════════════════════════════════════════════════════════════════════

/// Overlay animé pour le déblocage d'un badge
class BadgeUnlockAnimation extends StatefulWidget {
  final GamificationBadge badge;
  final VoidCallback onComplete;

  const BadgeUnlockAnimation({
    super.key,
    required this.badge,
    required this.onComplete,
  });

  @override
  State<BadgeUnlockAnimation> createState() => _BadgeUnlockAnimationState();
}

class _BadgeUnlockAnimationState extends State<BadgeUnlockAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _shineController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _badgeScaleAnimation;
  late Animation<double> _badgeRotateAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _badgeSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    // Controller principal
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Controller pour les particules
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Controller pour le shine
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Animations
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 40,
      ),
    ]).animate(_mainController);
    
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_mainController);
    
    _badgeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
    ]).animate(_mainController);
    
    _badgeRotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: -0.1, end: 0.05),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.05, end: 0.0),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 50),
    ]).animate(_mainController);
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _badgeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));
    
    // Start animations
    _mainController.forward();
    _particleController.repeat();
    
    // Auto-close
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onComplete,
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Container(
            color: Colors.black.withValues(alpha: _opacityAnimation.value * 0.7),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge avec effets
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow externe
                        _buildGlow(),
                        
                        // Particules
                        _buildParticles(),
                        
                        // Badge principal
                        _buildBadge(),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Texte "Badge Débloqué"
                    _buildText(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlow() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: context.r.dp(180) + (context.r.dp(40) * _glowAnimation.value),
          height: context.r.dp(180) + (context.r.dp(40) * _glowAnimation.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.badge.color.withValues(alpha: 0.6 * _glowAnimation.value),
                widget.badge.color.withValues(alpha: 0.2 * _glowAnimation.value),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return SizedBox(
          width: context.r.dp(200),
          height: context.r.dp(200),
          child: CustomPaint(
            painter: _ParticlesPainter(
              progress: _particleController.value,
              color: widget.badge.color,
              particleCount: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge() {
    return SlideTransition(
      position: _badgeSlideAnimation,
      child: Transform.scale(
        scale: _badgeScaleAnimation.value,
        child: Transform.rotate(
          angle: _badgeRotateAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cercle de fond
              Container(
                width: context.r.dp(120),
                height: context.r.dp(120),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.badge.color.withValues(alpha: 0.15),
                  border: Border.all(color: widget.badge.color, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: widget.badge.color.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              
              // Shine effect
              AnimatedBuilder(
                animation: _shineController,
                builder: (context, child) {
                  return ClipOval(
                    child: Container(
                      width: context.r.dp(120),
                      height: context.r.dp(120),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1.0 + 3 * _shineController.value, -1.0),
                          end: Alignment(-0.5 + 3 * _shineController.value, 1.0),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Icon
              Icon(
                widget.badge.icon,
                size: context.r.dp(56),
                color: widget.badge.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return AnimatedBuilder(
      animation: CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
      builder: (context, child) {
        final progress = CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
        ).value;
        
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: Column(
              children: [
                Text(
                  '🎉 Badge Débloqué !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.r.sp(28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.badge.name,
                  style: TextStyle(
                    color: widget.badge.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.badge.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '+${widget.badge.requiredValue * 10} XP',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ANIMATION DE LEVEL UP
// ══════════════════════════════════════════════════════════════════════════════

/// Overlay animé pour le passage de niveau
class LevelUpAnimation extends StatefulWidget {
  final CourierLevel newLevel;
  final VoidCallback onComplete;

  const LevelUpAnimation({
    super.key,
    required this.newLevel,
    required this.onComplete,
  });

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _numberController;
  late AnimationController _starsController;
  
  late Animation<double> _backgroundOpacity;
  late Animation<double> _cardScale;
  late Animation<double> _numberScale;
  late Animation<double> _titleSlide;

  @override
  void initState() {
    super.initState();
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
    
    _starsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _backgroundOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.8), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.8), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.0), weight: 15),
    ]).animate(_mainController);
    
    _cardScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0),
        weight: 15,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 35),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
    ]).animate(_mainController);
    
    _numberScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 20),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.5).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.5, end: 1.0),
        weight: 10,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
    ]).animate(_mainController);
    
    _titleSlide = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.25, 0.45, curve: Curves.easeOut),
    );
    
    _mainController.forward();
    
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _numberController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onComplete,
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Container(
            color: Colors.black.withValues(alpha: _backgroundOpacity.value),
            child: Stack(
              children: [
                // Étoiles de fond
                _buildStars(),
                
                // Contenu principal
                Center(
                  child: Transform.scale(
                    scale: _cardScale.value,
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStars() {
    return AnimatedBuilder(
      animation: _starsController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _StarsPainter(
            progress: _starsController.value,
            color: widget.newLevel.color,
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.newLevel.color.withValues(alpha: 0.9),
            widget.newLevel.color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.newLevel.color.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🎊 LEVEL UP! 🎊',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.r.sp(24),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          
          // Numéro de niveau
          AnimatedBuilder(
            animation: _numberScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _numberScale.value,
                child: AnimatedBuilder(
                  animation: _numberController,
                  builder: (context, child) {
                    return Container(
                      width: context.r.dp(120),
                      height: context.r.dp(120),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(
                              alpha: 0.5 + (_numberController.value * 0.3),
                            ),
                            blurRadius: 20 + (_numberController.value * 10),
                            spreadRadius: _numberController.value * 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.newLevel.level}',
                          style: TextStyle(
                            fontSize: context.r.sp(60),
                            fontWeight: FontWeight.bold,
                            color: widget.newLevel.color,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Titre et récompenses
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_titleSlide),
            child: FadeTransition(
              opacity: _titleSlide,
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.newLevel.icon, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        widget.newLevel.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.r.sp(28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nouveaux avantages débloqués !',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      _buildBonusChip('Commission +${widget.newLevel.level}%'),
                      _buildBonusChip('Priorité +${widget.newLevel.level}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// XP FLYING ANIMATION
// ══════════════════════════════════════════════════════════════════════════════

/// Animation d'XP volant vers le compteur
class XPFlyingAnimation extends StatefulWidget {
  final int xpAmount;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback onComplete;

  const XPFlyingAnimation({
    super.key,
    required this.xpAmount,
    required this.startPosition,
    required this.endPosition,
    required this.onComplete,
  });

  @override
  State<XPFlyingAnimation> createState() => _XPFlyingAnimationState();
}

class _XPFlyingAnimationState extends State<XPFlyingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.3), weight: 70),
    ]).animate(_controller);
    
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);
    
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  '+${widget.xpAmount} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAINTERS CUSTOMISÉS
// ══════════════════════════════════════════════════════════════════════════════

/// Painter pour les particules du badge unlock
class _ParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount;

  _ParticlesPainter({
    required this.progress,
    required this.color,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42);
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final baseRadius = size.width / 2 * 0.6;
      final radiusVariation = random.nextDouble() * 30;
      final radius = baseRadius + radiusVariation + (progress * 80);
      
      final particleProgress = (progress + (i / particleCount)) % 1.0;
      final opacity = (1 - particleProgress).clamp(0.0, 1.0);
      
      final x = center.dx + math.cos(angle + progress * 2) * radius;
      final y = center.dy + math.sin(angle + progress * 2) * radius;
      
      final paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, y),
        3 + random.nextDouble() * 4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Painter pour les étoiles du level up
class _StarsPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StarsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.5 + random.nextDouble() * 0.5;
      final y = (baseY - (progress * size.height * speed)) % size.height;
      
      final starProgress = (progress * 3 + i / 50) % 1.0;
      final opacity = math.sin(starProgress * math.pi);
      
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;
      
      // Dessiner une étoile
      final starSize = 2 + random.nextDouble() * 3;
      _drawStar(canvas, Offset(x, y), starSize, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * math.pi / 5) - math.pi / 2;
      final point = Offset(
        center.dx + math.cos(angle) * size,
        center.dy + math.sin(angle) * size,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CONFETTI ANIMATION
// ══════════════════════════════════════════════════════════════════════════════

/// Widget d'animation de confettis
class ConfettiAnimation extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiAnimation({
    super.key,
    this.duration = const Duration(seconds: 3),
    this.onComplete,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Confetti> _confetti = [];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    // Générer les confettis
    final random = math.Random();
    for (int i = 0; i < 100; i++) {
      _confetti.add(_Confetti(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.3,
        speed: 0.3 + random.nextDouble() * 0.7,
        size: 6 + random.nextDouble() * 8,
        color: [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.pink,
        ][random.nextInt(7)],
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: random.nextDouble() * 5,
      ));
    }
    
    _controller.forward();
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            confetti: _confetti,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Confetti {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;

  _Confetti({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double progress;

  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final adjustedProgress = ((progress - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;
      
      final y = -0.1 + adjustedProgress * 1.2 * c.speed;
      if (y > 1.1) continue;
      
      final opacity = y > 0.9 ? (1.1 - y) / 0.2 : 1.0;
      
      final paint = Paint()
        ..color = c.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(
        c.x * size.width,
        y * size.height,
      );
      canvas.rotate(c.rotation + progress * c.rotationSpeed);
      
      // Dessiner un rectangle comme confetti
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.6),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SERVICE D'ANIMATIONS
// ══════════════════════════════════════════════════════════════════════════════

/// Service pour afficher les animations de gamification
class GamificationAnimationService {
  static final GamificationAnimationService _instance = GamificationAnimationService._();
  factory GamificationAnimationService() => _instance;
  GamificationAnimationService._();

  OverlayEntry? _currentOverlay;

  /// Afficher l'animation de déblocage de badge
  void showBadgeUnlock(BuildContext context, GamificationBadge badge) {
    _removeCurrentOverlay();
    
    _currentOverlay = OverlayEntry(
      builder: (context) => BadgeUnlockAnimation(
        badge: badge,
        onComplete: () => _removeCurrentOverlay(),
      ),
    );
    
    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Afficher l'animation de level up
  void showLevelUp(BuildContext context, CourierLevel newLevel) {
    _removeCurrentOverlay();
    
    _currentOverlay = OverlayEntry(
      builder: (context) => LevelUpAnimation(
        newLevel: newLevel,
        onComplete: () => _removeCurrentOverlay(),
      ),
    );
    
    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Afficher animation XP volant
  void showXPFlying(
    BuildContext context,
    int xpAmount,
    Offset startPosition,
    Offset endPosition,
  ) {
    final overlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            XPFlyingAnimation(
              xpAmount: xpAmount,
              startPosition: startPosition,
              endPosition: endPosition,
              onComplete: () {}, // Auto-removed by animation
            ),
          ],
        ),
      ),
    );
    
    Overlay.of(context).insert(overlay);
    
    Future.delayed(const Duration(milliseconds: 1100), () {
      overlay.remove();
    });
  }

  /// Afficher confettis
  void showConfetti(BuildContext context) {
    final overlay = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: ConfettiAnimation(
          onComplete: () {},
        ),
      ),
    );
    
    Overlay.of(context).insert(overlay);
    
    Future.delayed(const Duration(seconds: 3), () {
      overlay.remove();
    });
  }

  void _removeCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
