import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom sheet de bienvenue affiché à la première connexion.
/// 
/// Présente l'application de manière chaleureuse avant de lancer
/// le tutoriel interactif avec les coach marks.
class WelcomeOnboardingSheet extends StatefulWidget {
  final VoidCallback? onGetStarted;
  
  const WelcomeOnboardingSheet({
    this.onGetStarted,
    super.key,
  });

  @override
  State<WelcomeOnboardingSheet> createState() => _WelcomeOnboardingSheetState();
}

class _WelcomeOnboardingSheetState extends State<WelcomeOnboardingSheet> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  
  int _currentStep = 0;
  
  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      icon: Icons.local_pharmacy_rounded,
      title: 'Bienvenue sur DR-PHARMA',
      description: 'Votre assistant pour gérer les commandes, '
          'le stock et les paiements de votre pharmacie.',
    ),
    _OnboardingStep(
      icon: Icons.receipt_long_rounded,
      title: 'Commandes en temps réel',
      description: 'Recevez et traitez les commandes instantanément. '
          'Notifications push pour ne rien manquer.',
    ),
    _OnboardingStep(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Scanner d\'ordonnances',
      description: 'Scannez les ordonnances avec reconnaissance OCR '
          'pour un traitement rapide et précis.',
    ),
    _OnboardingStep(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Portefeuille intégré',
      description: 'Suivez vos revenus et demandez des retraits '
          'directement depuis l\'application.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _controller.reset();
      _controller.forward();
    } else {
      Navigator.of(context).pop();
      widget.onGetStarted?.call();
    }
  }
  
  void _skip() {
    Navigator.of(context).pop();
    widget.onGetStarted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final step = _steps[_currentStep];
    final isLastStep = _currentStep == _steps.length - 1;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              
              // Animated content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Icon with gradient background
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step.icon,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // Description
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Step indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  final isActive = index == _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? AppColors.primary 
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              
              // Buttons
              Row(
                children: [
                  if (!isLastStep)
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Passer',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastStep ? 'Commencer' : 'Suivant',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLastStep ? Icons.check : Icons.arrow_forward,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final String title;
  final String description;
  
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}
