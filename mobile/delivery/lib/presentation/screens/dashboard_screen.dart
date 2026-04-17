import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/delivery_alert_service.dart';
import '../../core/services/tutorial_service.dart';
import '../../core/utils/app_exceptions.dart';
import '../../core/utils/responsive.dart';
import '../../core/router/route_names.dart';
import '../widgets/common/kyc_banner.dart';
import '../widgets/common/nav_badges.dart';
import '../../data/repositories/delivery_repository.dart';
import '../providers/delivery_providers.dart';
import '../widgets/tutorial/tutorial_widgets.dart';
import '../providers/dashboard_tab_provider.dart';
import 'home_screen.dart';
import 'deliveries_screen_redesign.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen_redesign.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

enum _LoadingState { loading, ready, error, timeout }

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  _LoadingState _loadingState = _LoadingState.loading;
  String? _errorMessage;
  Timer? _timeoutTimer;
  int _retryCount = 0;

  // Timeout augmenté pour couvrir les timeouts réseau (20s) + marge
  static const Duration _loadingTimeout = Duration(seconds: 25);
  static const int _maxAutoRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    // Différer les inits après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Forcer le rafraîchissement du profil au démarrage pour avoir le KYC à jour
      ref.invalidate(courierProfileProvider);
      _startLoadingWithTimeout();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  /// Démarre le chargement avec timeout
  void _startLoadingWithTimeout() {
    _timeoutTimer?.cancel();

    // Timeout de 25 secondes (aligné avec timeouts réseau)
    _timeoutTimer = Timer(_loadingTimeout, () {
      if (mounted && _loadingState == _LoadingState.loading) {
        // Réessayer une fois avant d'afficher l'erreur
        if (_retryCount < _maxAutoRetries) {
          _retryCount++;
          ref.invalidate(courierProfileProvider);
          _startLoadingWithTimeout();
          return;
        }
        setState(() {
          _loadingState = _LoadingState.timeout;
          _errorMessage =
              'Connexion au serveur difficile.\nAppuyez sur Réessayer ou vérifiez votre réseau.';
        });
      }
    });

    // Init notifications en parallèle (non-bloquant)
    _initNotificationsAndRouting().catchError((e) {
      if (kDebugMode) debugPrint('❌ [Dashboard] Notification init error: $e');
    });
  }

  /// Réessayer le chargement
  Future<void> _retry() async {
    if (!mounted) return;

    setState(() {
      _loadingState = _LoadingState.loading;
      _errorMessage = null;
      _retryCount = 0; // Reset pour permettre les auto-retries
    });

    // Invalider le cache du profil pour forcer un rechargement
    ref.invalidate(courierProfileProvider);

    _startLoadingWithTimeout();
  }

  /// Vérifie si c'est le premier lancement et affiche le tutoriel
  Future<void> _checkFirstLaunch() async {
    final service = ref.read(tutorialServiceProvider);
    final isFirst = await service.isFirstLaunch();

    if (isFirst && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ref.startTutorialIfNeeded(TutorialType.welcome);
      }
    }
  }

  /// Initialise les notifications FCM et le routage au tap
  Future<void> _initNotificationsAndRouting() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initNotifications();

    notificationService.onNotificationTapped = (String idStr) {
      _navigateToDeliveryFromNotification(idStr);
    };

    // Auto-assignation : naviguer vers l'onglet Livraisons (tab 1) sans fermer la notif.
    // La notification reste visible pour que l'utilisateur puisse réassigner si besoin.
    notificationService.onDeliveryAssignedNotificationTapped = (String idStr) {
      if (!mounted) return;
      // Aller sur le tab Livraisons pour gérer la course assignée
      ref.read(dashboardTabProvider.notifier).setTab(1);
    };

    notificationService.onChatNotificationTapped = (Map<String, dynamic> chatData) {
      _navigateToChatFromNotification(chatData);
    };

    // Écouter les nouvelles courses pour déclencher l'alerte sonore
    notificationService.newOrderStream.listen((notification) {
      if (notification != null && mounted) {
        // Auto-assignation : pas d'alarme sonore urgente, juste rafraîchir "En cours"
        if (notification.type == 'delivery_assigned') {
          ref.invalidate(deliveriesProvider('active'));
          ref.invalidate(deliveriesProvider('pending'));
          return;
        }

        // Broadcast offer : déclencher l'alerte sonore pour attirer l'attention
        final alertService = ref.read(deliveryAlertServiceProvider);
        alertService.startAlert();
        ref.read(deliveryAlertActiveProvider.notifier).activate();
        ref.invalidate(deliveriesProvider('pending'));
      }
    });
  }

  /// Navigue vers le chat depuis une notification de message
  void _navigateToChatFromNotification(Map<String, dynamic> chatData) {
    final deliveryId = int.tryParse(chatData['delivery_id']?.toString() ?? '');
    if (deliveryId == null || !mounted) return;

    // Utiliser order_id (ID commande) pour Firestore, fallback sur delivery_id
    final orderId = int.tryParse(chatData['order_id']?.toString() ?? '') ?? deliveryId;
    final senderType = chatData['sender_type']?.toString() ?? 'client';
    final senderName = chatData['sender_name']?.toString() ?? 'Interlocuteur';

    context.push(
      AppRoutes.deliveryChat,
      extra: {
        'orderId': orderId,
        'deliveryId': deliveryId,
        'target': senderType,
        'targetName': senderName,
        'targetAvatar': null,
        'targetPhone': null,
      },
    );
  }

  /// Navigue vers les détails d'une livraison depuis une notification tapée
  Future<void> _navigateToDeliveryFromNotification(String idStr) async {
    final id = int.tryParse(idStr);
    if (id == null) return;

    if (!mounted) return;

    try {
      final delivery = await ref
          .read(deliveryRepositoryProvider)
          .getDeliveryById(id);
      if (!mounted) return;
      context.push(AppRoutes.deliveryDetails, extra: delivery);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Navigation from notification failed: $e');
    }
  }

  void _onTabTapped(int index) {
    ref.read(dashboardTabProvider.notifier).setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final isDark = context.isDark;

    // Écouter les changements du profil
    ref.listen<AsyncValue<dynamic>>(courierProfileProvider, (prev, next) {
      next.when(
        loading: () {
          // Ne rien faire, on attend
        },
        error: (error, stack) {
          if (!mounted) return;

          if (kDebugMode) debugPrint('❌ [Dashboard] Profile error: $error');

          // Session expirée ou non authentifié
          if (error is SessionExpiredException) {
            _timeoutTimer?.cancel();
            context.go(AppRoutes.login);
            return;
          }

          // Compte en attente / suspendu / rejeté
          if (error is PendingApprovalException) {
            _timeoutTimer?.cancel();
            context.go(
              AppRoutes.pendingApproval,
              extra: {'status': error.status, 'message': error.userMessage},
            );
            return;
          }

          // KYC incomplet — laisser naviguer, bloquer les commandes
          if (error is IncompleteKycException) {
            _timeoutTimer?.cancel();
            if (mounted && _loadingState != _LoadingState.ready) {
              setState(() => _loadingState = _LoadingState.ready);
            }
            return;
          }

          // Profil non trouvé (pas un coursier)
          if (error is ForbiddenException &&
              error.code == 'COURIER_PROFILE_NOT_FOUND') {
            _timeoutTimer?.cancel();
            setState(() {
              _loadingState = _LoadingState.error;
              _errorMessage =
                  'Profil livreur non trouvé.\nContactez le support.';
            });
            return;
          }

          // Erreur réseau - retry automatique
          final isNetworkError = error is NetworkException;

          if (isNetworkError &&
              _loadingState == _LoadingState.loading &&
              _retryCount < _maxAutoRetries) {
            _retryCount++;
            if (kDebugMode) {
              debugPrint(
                '🔄 [Dashboard] Retry automatique $_retryCount/$_maxAutoRetries',
              );
            }

            Future.delayed(_retryDelay, () {
              if (mounted && _loadingState == _LoadingState.loading) {
                ref.invalidate(courierProfileProvider);
              }
            });
            return;
          }

          // Max retries atteint ou erreur non-réseau - afficher le vrai message
          _timeoutTimer?.cancel();
          setState(() {
            _loadingState = _LoadingState.error;
            String displayMessage = error is AppException
                ? error.userMessage
                : error.toString().replaceAll('Exception: ', '').trim();
            if (displayMessage.isEmpty || displayMessage.length > 200) {
              displayMessage = 'Erreur de chargement.\nVeuillez réessayer.';
            }
            _errorMessage = displayMessage;
          });
        },
        data: (profile) {
          _timeoutTimer?.cancel();
          if (mounted && _loadingState != _LoadingState.ready) {
            _retryCount = 0; // Reset retry count on success
            setState(() {
              _loadingState = _LoadingState.ready;
            });
            // Lancer le check du tutoriel après chargement
            _checkFirstLaunch().catchError((e) {
              if (kDebugMode) {
                debugPrint('❌ [Dashboard] First launch check error: $e');
              }
            });
          }
        },
      );
    });

    // Si en cours de chargement ou erreur, afficher l'écran approprié
    if (_loadingState != _LoadingState.ready) {
      return _buildLoadingOrErrorScreen(isDark);
    }

    // Dashboard complet avec nav bar
    final currentIndex = ref.watch(dashboardTabProvider);
    // Écrans const — la liste est recréée mais les widgets sont identiques (const)
    const screens = [
      HomeScreen(),
      DeliveriesScreenRedesign(),
      StatisticsScreenRedesign(),
      WalletScreen(),
      ProfileScreen(),
    ];

    return TutorialOverlay(
      child: Scaffold(
        body: Column(
          children: [
            const KycBanner(),
            Expanded(
              child: IndexedStack(index: currentIndex, children: screens),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: _onTabTapped,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: isDark
                      ? const Color(0xFF252540)
                      : DesignTokens.backgroundLight,
                  selectedItemColor: DesignTokens.primary,
                  unselectedItemColor: isDark
                      ? DesignTokens.textMutedDarkMode
                      : DesignTokens.textMuted,
                  selectedFontSize: 12,
                  unselectedFontSize: 11,
                  elevation: 0,
                  showUnselectedLabels: true,
                  items: [
                    BottomNavigationBarItem(
                      icon: _buildNavIcon(Icons.map_outlined, 0),
                      activeIcon: _buildActiveNavIcon(Icons.map, 0),
                      label: 'Carte',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavIcon(Icons.list_alt_outlined, 1),
                      activeIcon: _buildActiveNavIcon(Icons.list_alt, 1),
                      label: 'Livraisons',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavIcon(Icons.bar_chart_outlined, 2),
                      activeIcon: _buildActiveNavIcon(Icons.bar_chart, 2),
                      label: 'Stats',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavIcon(
                        Icons.account_balance_wallet_outlined,
                        3,
                      ),
                      activeIcon: _buildActiveNavIcon(
                        Icons.account_balance_wallet,
                        3,
                      ),
                      label: 'Wallet',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavIcon(Icons.person_outline, 4),
                      activeIcon: _buildActiveNavIcon(Icons.person, 4),
                      label: 'Profil',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Écran de chargement ou d'erreur (sans nav bar)
  Widget _buildLoadingOrErrorScreen(bool isDark) {
    final bgColor = isDark ? const Color(0xFF0D1117) : Colors.white;
    final r = Responsive.of(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: EdgeInsets.all(r.dp(16)),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: r.dp(80),
                  height: r.dp(80),
                  cacheWidth: 160,
                  cacheHeight: 160,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: r.dp(24)),

              // Titre
              Text(
                'DR-PHARMA',
                style: TextStyle(
                  fontSize: r.sp(32),
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade900,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: r.dp(8)),
              Text(
                'LIVREUR',
                style: TextStyle(
                  fontSize: r.sp(16),
                  letterSpacing: 5.0,
                  color: Colors.blue.shade400,
                ),
              ),
              SizedBox(height: r.dp(48)),

              // État selon loading/error/timeout
              if (_loadingState == _LoadingState.loading) ...[
                // Skeleton shimmer loading
                _buildSkeletonLoader(isDark, r),
                Text(
                  'Chargement...',
                  style: TextStyle(
                    fontSize: r.sp(14),
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ] else ...[
                // Icône d'erreur ou timeout
                Icon(
                  _loadingState == _LoadingState.timeout
                      ? Icons.timer_off_outlined
                      : Icons.error_outline,
                  size: r.dp(48),
                  color: _loadingState == _LoadingState.timeout
                      ? Colors.orange
                      : Colors.red,
                ),
                SizedBox(height: r.dp(16)),

                // Message d'erreur
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.dp(32)),
                  child: Text(
                    _errorMessage ?? 'Une erreur est survenue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.sp(14),
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: r.dp(24)),

                // Bouton Réessayer
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: r.dp(24),
                      vertical: r.dp(12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Skeleton shimmer loader pour remplacer le spinner
  Widget _buildSkeletonLoader(bool isDark, Responsive r) {
    final shimmerBase = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200;
    final shimmerHighlight = isDark
        ? const Color(0xFF3A3A3A)
        : Colors.grey.shade100;

    Widget shimmerBox({
      double? width,
      required double height,
      double radius = 8,
    }) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        builder: (context, value, child) {
          return AnimatedOpacity(
            opacity: value,
            duration: const Duration(milliseconds: 600),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  colors: [shimmerBase, shimmerHighlight, shimmerBase],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: r.padH(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fake status bar
          shimmerBox(width: r.dp(160), height: r.dp(16)),
          SizedBox(height: r.dp(12)),
          shimmerBox(height: r.dp(80), radius: 12),
          SizedBox(height: r.dp(16)),
          shimmerBox(width: r.dp(120), height: r.dp(14)),
          SizedBox(height: r.dp(10)),
          shimmerBox(height: r.dp(60), radius: 12),
          SizedBox(height: r.dp(10)),
          shimmerBox(height: r.dp(60), radius: 12),
          SizedBox(height: r.dp(16)),
          Center(
            child: Text(
              'Chargement...',
              style: TextStyle(
                fontSize: r.sp(13),
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Icône de navigation inactive
  Widget _buildNavIcon(IconData icon, int index) {
    final baseIcon = Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Icon(icon, size: 24),
    );
    
    // Ajouter badge selon l'index
    return switch (index) {
      1 => NavBadge(
        count: ref.watch(pendingDeliveriesCountProvider),
        type: NavBadgeType.info,
        child: baseIcon,
      ),
      4 => NavBadge(
        count: ref.watch(navNotificationsCountProvider),
        type: NavBadgeType.notification,
        child: baseIcon,
      ),
      _ => baseIcon,
    };
  }

  /// Icône de navigation active avec indicateur vert
  Widget _buildActiveNavIcon(IconData icon, int index) {
    final baseIcon = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DesignTokens.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: DesignTokens.primary),
        ),
      ],
    );
    
    // Ajouter badge selon l'index (même actif, on montre le badge)
    return switch (index) {
      1 => NavBadge(
        count: ref.watch(pendingDeliveriesCountProvider),
        type: NavBadgeType.info,
        offset: const Offset(0, -8),
        child: baseIcon,
      ),
      4 => NavBadge(
        count: ref.watch(navNotificationsCountProvider),
        type: NavBadgeType.notification,
        offset: const Offset(0, -8),
        child: baseIcon,
      ),
      _ => baseIcon,
    };
  }
}
