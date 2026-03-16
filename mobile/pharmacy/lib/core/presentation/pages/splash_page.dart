import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/presentation/providers/state/auth_state.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFadeAnimation;
  
  String _version = "";

  @override
  void initState() {
    super.initState();
    _initVersion();
    _setupAnimations();
    _checkAuthAndNavigate();
  }

  Future<void> _initVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
        });
      }
    } catch (e) {
      // Version fetch failed, keep default or empty
      if (kDebugMode) debugPrint("Version checking failed: $e");
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2)
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
        )
    );

    _animationController.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for minimum display time + animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check if onboarding is completed
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final onboardingCompleted = prefs.getBool('pharmacy_onboarding_completed') ?? false;
    
    if (!onboardingCompleted) {
      context.go('/onboarding');
      return;
    }

    // The redirection logic is mainly handled by the GoRouter redirect.
    // However, since this is the initial route, we can just trigger a refresh or push.
    // But since GoRouter's redirect checks auth state, we just need to make sure
    // we move away from splash if the router doesn't do it automatically.
    
    // In this specific setup, the SplashPage is likely the initial route.
    // We check the provider state.
    final authState = ref.read(authProvider);
    
    if (authState.status == AuthStatus.authenticated) {
        context.go('/dashboard');
    } else {
        context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade50,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                ),
                
                const SizedBox(height: 24),
                
                // Animated Text
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: [
                       Text(
                        'DR PHARMA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gestion pharmaceutique professionnelle',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Loader & Version
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textFadeAnimation,
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                   Text(
                    _version.isNotEmpty ? 'Version $_version' : 'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
