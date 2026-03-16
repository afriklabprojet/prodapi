import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'core/constants/app_colors.dart';
import 'core/utils/responsive_utils.dart';
import 'config/providers.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/orders/presentation/providers/cart_provider.dart';
import 'features/home/presentation/widgets/widgets.dart';
import 'features/home/domain/models/promo_item.dart';
import 'l10n/app_localizations.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController _promoPageController = PageController();
  final PageController _pharmacyPageController = PageController();
  Timer? _promoTimer;
  Timer? _pharmacyTimer;
  int _currentPromoIndex = 0;
  int _currentPharmacyIndex = 0;

  final List<PromoItem> _promoItems = [
    PromoItem(
      badge: 'Nouveau',
      title: 'Livraison Gratuite',
      subtitle: 'Sur votre première commande',
      gradientColorValues: [AppColors.primary.toARGB32(), AppColors.primaryDark.toARGB32()],
    ),
    PromoItem(
      badge: '-20%',
      title: 'Vitamines & Compléments',
      subtitle: 'Profitez des promotions santé',
      gradientColorValues: [0xFF00BCD4, 0xFF0097A7],
    ),
    PromoItem(
      badge: 'Pharmacie de garde',
      title: 'Service 24h/24',
      subtitle: 'Trouvez une pharmacie ouverte près de vous',
      gradientColorValues: [0xFFFF5722, 0xFFE64A19],
      actionType: 'onDuty',
    ),
    PromoItem(
      badge: 'Ordonnance',
      title: 'Envoyez votre ordonnance',
      subtitle: 'Recevez vos médicaments à domicile',
      gradientColorValues: [0xFF9C27B0, 0xFF7B1FA2],
      actionType: 'prescription',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startPromoTimer();
    // Load featured pharmacies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pharmaciesProvider.notifier).fetchFeaturedPharmacies();
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _pharmacyTimer?.cancel();
    _promoPageController.dispose();
    _pharmacyPageController.dispose();
    super.dispose();
  }

  void _startPharmacyTimer(int pharmacyCount) {
    _pharmacyTimer?.cancel();
    if (pharmacyCount <= 1) return;
    
    _pharmacyTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pharmacyPageController.hasClients) {
        _currentPharmacyIndex = (_currentPharmacyIndex + 1) % pharmacyCount;
        _pharmacyPageController.animateToPage(
          _currentPharmacyIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startPromoTimer() {
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_promoPageController.hasClients) {
        _currentPromoIndex = (_currentPromoIndex + 1) % _promoItems.length;
        _promoPageController.animateToPage(
          _currentPromoIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cartState = ref.watch(cartProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = ResponsiveUtils(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation(context);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.grey[50],
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.value(mobile: double.infinity, tablet: 700.0, desktop: 900.0)),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                HomeAppBar(cartState: cartState, isDark: isDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(r.horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WelcomeSection(userName: user?.name, isDark: isDark),
                        SizedBox(height: r.value(mobile: 32.0, tablet: 40.0, desktop: 48.0)),
                        FeaturedPharmaciesSection(
                          pharmacies: ref.watch(pharmaciesProvider).featuredPharmacies,
                          isLoading: ref.watch(pharmaciesProvider).isFeaturedLoading,
                          isDark: isDark,
                          pageController: _pharmacyPageController,
                          currentIndex: _currentPharmacyIndex,
                          onRefresh: () => ref.read(pharmaciesProvider.notifier).fetchFeaturedPharmacies(),
                          onPageChanged: (index) {
                            setState(() => _currentPharmacyIndex = index);
                            final pharmacies = ref.read(pharmaciesProvider).featuredPharmacies;
                            if (pharmacies.isNotEmpty && _pharmacyTimer == null) {
                              _startPharmacyTimer(pharmacies.length);
                            }
                          },
                        ),
                        SizedBox(height: r.value(mobile: 32.0, tablet: 40.0, desktop: 48.0)),
                        SectionTitle(title: AppLocalizations.of(context).homeServices, isDark: isDark),
                        const SizedBox(height: 16),
                        QuickActionsGrid(isDark: isDark),
                        SizedBox(height: r.value(mobile: 32.0, tablet: 40.0, desktop: 48.0)),
                        SectionTitle(title: AppLocalizations.of(context).homeFeatured, isDark: isDark),
                        const SizedBox(height: 16),
                        PromoSlider(
                          items: _promoItems,
                          controller: _promoPageController,
                          currentIndex: _currentPromoIndex,
                          isDark: isDark,
                          onPageChanged: (index) => setState(() => _currentPromoIndex = index),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogQuitApp),
        content: Text(l10n.dialogQuitAppMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.btnQuit, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }
}
