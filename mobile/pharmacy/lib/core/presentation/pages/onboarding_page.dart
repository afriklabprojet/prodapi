import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/ui_constants.dart';

/// Onboarding émotionnel axé sur la valeur.
/// 3 écrans qui répondent à "qu'est-ce que ça change pour moi ?"
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late final List<AnimationController> _iconControllers;
  late final List<Animation<double>> _iconAnimations;

  static const _steps = [
    _OnboardingStep(
      icon: Icons.notifications_active_rounded,
      secondaryIcon: Icons.shopping_bag_rounded,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      title: 'Recevez vos commandes\nen 1 tap',
      subtitle: 'Plus besoin de noter au téléphone',
      description: 'Les commandes arrivent directement dans l\'app. '
          'Vous êtes notifié instantanément, vous validez en un geste.',
      emoji: '📱',
    ),
    _OnboardingStep(
      icon: Icons.inventory_2_rounded,
      secondaryIcon: Icons.qr_code_scanner_rounded,
      gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
      title: 'Votre stock,\nsous contrôle',
      subtitle: 'Fini les ruptures surprises',
      description: 'Scanner de codes-barres, alertes de stock bas, '
          'mise à jour en 2 clics. Vous gardez le contrôle.',
      emoji: '📦',
    ),
    _OnboardingStep(
      icon: Icons.insights_rounded,
      secondaryIcon: Icons.trending_up_rounded,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
      title: 'Suivez votre chiffre\nen temps réel',
      subtitle: 'Vous savez exactement où vous en êtes',
      description: 'Dashboard animé, tendances de la semaine, '
          'rapports automatiques. Tout en un coup d\'œil.',
      emoji: '📊',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
      _steps.length,
      (i) => AnimationController(
        duration: AnimationConstants.feedbackDisplay,
        vsync: this,
      ),
    );
    _iconAnimations = _iconControllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.elasticOut);
    }).toList();
    
    // Démarrer l'animation de la première page
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _iconControllers[0].forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _goToLogin() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pharmacy_onboarding_completed', true);
    if (mounted) context.go('/login');
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    HapticFeedback.selectionClick();
    
    // Animer l'icône de la nouvelle page
    for (int i = 0; i < _iconControllers.length; i++) {
      if (i == index) {
        _iconControllers[i].forward(from: 0);
      } else {
        _iconControllers[i].reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentPage];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: logo + skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo DR-PHARMA
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: step.gradient),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'DR-PHARMA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _goToLogin,
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (ctx, index) {
                  return _OnboardingSlide(
                    step: _steps[index],
                    animation: _iconAnimations[index],
                    isDark: isDark,
                  );
                },
              ),
            ),

            // Dots indicateurs
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: _currentPage == i
                          ? LinearGradient(colors: step.gradient)
                          : null,
                      color: _currentPage == i
                          ? null
                          : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // CTA button avec gradient
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: step.gradient),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: step.gradient[0].withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (_currentPage == _steps.length - 1) {
                        _goToLogin();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _steps.length - 1
                              ? 'C\'est parti !'
                              : 'Continuer',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (_currentPage < _steps.length - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Slide avec illustration animée ──────────────────────────────────────────

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.step,
    required this.animation,
    required this.isDark,
  });
  
  final _OnboardingStep step;
  final Animation<double> animation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration animée
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.5 + (animation.value * 0.5),
                child: Opacity(
                  opacity: animation.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: _buildIllustration(),
          ),

          const SizedBox(height: 48),

          // Emoji
          Text(
            step.emoji,
            style: const TextStyle(fontSize: 40),
          ),
          
          const SizedBox(height: 20),

          // Titre principal
          Text(
            step.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),
          
          // Sous-titre accrocheur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: step.gradient.map((c) => c.withValues(alpha: 0.15)).toList(),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              step.subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: step.gradient[0],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Description détaillée
          Text(
            step.description,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: step.gradient.map((c) => c.withValues(alpha: 0.15)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle externe décoratif
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: step.gradient[0].withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          // Icône principale
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: step.gradient),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: step.gradient[0].withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              step.icon,
              size: 48,
              color: Colors.white,
            ),
          ),
          // Icône secondaire flottante
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                step.secondaryIcon,
                size: 24,
                color: step.gradient[1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _OnboardingStep {
  final IconData icon;
  final IconData secondaryIcon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final String description;
  final String emoji;

  const _OnboardingStep({
    required this.icon,
    required this.secondaryIcon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.emoji,
  });
}
