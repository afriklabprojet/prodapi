import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/router/route_names.dart';
import '../../l10n/app_localizations.dart';

class _OnboardingColors {
  static const navyDark = Color(0xFF0F1C3F);
  static const accentGold = Color(0xFFE5C76B);
  static const accentTeal = Color(0xFF2DD4BF);
  static const accentBlue = Color(0xFF60A5FA);
  static const softBackground = Color(0xFFF8FAFC);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingData> _buildPages(AppLocalizations l10n) => [
    OnboardingData(
      title: l10n.onboardingTitle1,
      description: l10n.onboardingDesc1,
      icon: Icons.local_shipping_rounded,
      badge: 'Rapide & fiable',
      gradient: const [
        _OnboardingColors.navyDark,
        _OnboardingColors.accentBlue,
      ],
    ),
    OnboardingData(
      title: l10n.onboardingTitle2,
      description: l10n.onboardingDesc2,
      icon: Icons.account_balance_wallet_rounded,
      badge: 'Gains en temps réel',
      gradient: const [_OnboardingColors.accentGold, Color(0xFFD9A441)],
    ),
    OnboardingData(
      title: l10n.onboardingTitle3,
      description: l10n.onboardingDesc3,
      icon: Icons.swap_horiz_rounded,
      badge: 'Simple à utiliser',
      gradient: const [_OnboardingColors.accentTeal, Color(0xFF14B8A6)],
    ),
  ];

  static const _pageCount = 3;

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
    context.go(AppRoutes.login);
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _buildPages(l10n);
    final current = pages[_currentPage];

    return Scaffold(
      backgroundColor: _OnboardingColors.softBackground,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  current.gradient.first.withValues(alpha: 0.10),
                  _OnboardingColors.softBackground,
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'DR-PHARMA Courier',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _OnboardingColors.navyDark,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          l10n.skip,
                          style: GoogleFonts.inter(
                            color: _OnboardingColors.navyDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: pages.length,
                    itemBuilder: (context, index) => _buildPage(pages[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => _buildIndicator(index, pages),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          if (_currentPage > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _previousPage,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _OnboardingColors.navyDark,
                                  side: BorderSide(
                                    color: _OnboardingColors.navyDark
                                        .withValues(alpha: 0.18),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  l10n.previousStep,
                                  style: GoogleFonts.sora(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          if (_currentPage > 0) const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: current.gradient,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: current.gradient.first.withValues(
                                      alpha: 0.30,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _currentPage == pages.length - 1
                                      ? l10n.getStarted
                                      : l10n.nextStep,
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.gradient.first.withValues(alpha: 0.12),
                  data.gradient.last.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: data.gradient.first.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.badge,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: data.gradient.first,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: data.gradient),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: data.gradient.first.withValues(alpha: 0.28),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Icon(data.icon, size: 84, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _OnboardingColors.navyDark,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index, List<OnboardingData> pages) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? pages[_currentPage].gradient.first
            : Colors.grey.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final String badge;
  final List<Color> gradient;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.badge,
    required this.gradient,
  });
}
