import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive.dart';
import 'login_screen_redesign.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Bienvenue Livreur',
      description:
          'Rejoignez l\'équipe DR-PHARMA et devenez un acteur clé de la santé. Livrez des médicaments et gagnez de l\'argent à votre rythme.',
      image: Icons.local_shipping_rounded,
      gradient: [const Color(0xFF2196F3), const Color(0xFF1565C0)],
    ),
    OnboardingData(
      title: 'Recevez des commandes',
      description:
          'Recevez des notifications en temps réel pour les nouvelles livraisons disponibles près de chez vous. Acceptez celles qui vous conviennent.',
      image: Icons.notifications_active_rounded,
      gradient: [const Color(0xFF00BCD4), const Color(0xFF00838F)],
    ),
    OnboardingData(
      title: 'Navigation optimisée',
      description:
          'Utilisez notre GPS intégré pour trouver le chemin le plus rapide. Gérez plusieurs livraisons en même temps avec l\'optimisation d\'itinéraire.',
      image: Icons.map_rounded,
      gradient: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
    ),
    OnboardingData(
      title: 'Gagnez plus',
      description:
          'Suivez vos gains en temps réel, consultez vos statistiques et retirez vos revenus facilement. Plus vous livrez, plus vous gagnez.',
      image: Icons.account_balance_wallet_rounded,
      gradient: [const Color(0xFFFF9800), const Color(0xFFE65100)],
    ),
    OnboardingData(
      title: 'Support 24/7',
      description:
          'Une question ou un problème ? Notre équipe est disponible 24h/24 pour vous aider. Chattez directement depuis l\'application.',
      image: Icons.support_agent_rounded,
      gradient: [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('courier_onboarding_completed', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreenRedesign()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      body: Stack(
        children: [
          // PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: TextButton(
              onPressed: _skip,
              child: Text(
                'Passer',
                style: TextStyle(
                  color: _pages[_currentPage].gradient[0],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Bottom Navigation
          Positioned(
            bottom: r.hp(50),
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildIndicator(index),
                  ),
                ),
                const SizedBox(height: 32),

                // Navigation Buttons
                Padding(
                  padding: r.padH(24),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: _pages[_currentPage].gradient[0],
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Précédent',
                              style: TextStyle(
                                color: _pages[_currentPage].gradient[0],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: _currentPage == 0 ? 1 : 1,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _pages[_currentPage].gradient,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _pages[_currentPage].gradient[0]
                                    .withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentPage == _pages.length - 1
                                  ? 'Commencer'
                                  : 'Suivant',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    final r = context.r;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.scaffoldBackground,
            data.gradient[0].withValues(alpha: 0.1),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: r.pad(24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Animated Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: r.dp(200),
                      height: r.dp(200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: data.gradient,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: data.gradient[0].withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Icon(
                        data.image,
                        size: r.dp(100),
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 1),

              // Title
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: r.sp(28),
                    fontWeight: FontWeight.bold,
                    color: data.gradient[0],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Description
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  data.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.secondaryText,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? _pages[_currentPage].gradient[0]
            : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData image;
  final List<Color> gradient;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.gradient,
  });
}
