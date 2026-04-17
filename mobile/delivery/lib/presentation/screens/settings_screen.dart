import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/utils/error_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/voice_service.dart';
import '../../core/router/route_names.dart';
import '../widgets/notifications/notification_widgets.dart';
import '../../data/repositories/auth_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadSettings();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    }
  }

  String _navigationApp = 'google_maps'; // google_maps, waze, apple_maps
  String _language = 'fr'; // fr, en

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLocale = ref.read(localeProvider);
    setState(() {
      _navigationApp = prefs.getString('navigation_app') ?? 'google_maps';
      _language = currentLocale.languageCode;
    });
  }

  Future<void> _updateNavigationApp(String value) async {
    setState(() => _navigationApp = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('navigation_app', value);
  }

  Future<void> _updateLanguage(String value) async {
    setState(() => _language = value);

    // Met à jour la locale via le provider
    ref.read(localeProvider.notifier).setLanguageCode(value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
  }

  Future<void> _openWebPage(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir la page web')),
        );
      }
    }
  }

  Future<void> _contactSupport() async {
    final Uri launchUri = Uri(scheme: 'tel', path: AppConfig.supportPhone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lancer l\'appel')),
        );
      }
    }
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              l10n?.language ?? 'Langue',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n?.french ?? 'Français'),
              trailing: _language == 'fr'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                _updateLanguage('fr');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n?.english ?? 'English'),
              trailing: _language == 'en'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                _updateLanguage('en');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Affichage & Navigation (fusionné Apparence + Préférences)
          _buildSectionHeader('Affichage & Navigation'),
          _buildCard([
            _buildThemeSelector(themeMode),
            const Divider(height: 1),
            _buildNavigationSelector(),
          ]),

          // 2. Notifications (fusionné Notifications + Vocales)
          const SizedBox(height: 24),
          _buildSectionHeader('Notifications'),
          const NotificationPreferencesCard(),
          const SizedBox(height: 8),
          _buildVoiceSettingsCard(),

          // 3. Compte & Sécurité (fusionné Compte + Sécurité)
          const SizedBox(height: 24),
          _buildSectionHeader('Compte & Sécurité'),
          _buildCard([
            _buildActionTile(
              icon: Icons.lock_outline,
              title: 'Changer le mot de passe',
              onTap: () {
                context.push(AppRoutes.changePassword);
              },
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.language,
              title: 'Langue de l\'application',
              trailing: Text(
                _language == 'fr' ? 'Français' : 'English',
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () => _showLanguageDialog(),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.history,
              title: 'Historique & Export',
              onTap: () => context.push(AppRoutes.historyExport),
            ),
          ]),
          const SizedBox(height: 8),
          _buildBiometricCard(),
          const SizedBox(height: 8),
          _buildCard([
            _buildActionTile(
              icon: Icons.accessibility_new,
              title: 'Accessibilité',
              onTap: () => _showAccessibilitySettings(),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.widgets,
              title: 'Widget écran d\'accueil',
              onTap: () => _showHomeWidgetSettings(),
            ),
          ]),

          // 4. Aide & Support
          const SizedBox(height: 24),
          _buildSectionHeader('Aide & Support'),
          _buildCard([
            _buildActionTile(
              icon: Icons.support_agent,
              title: 'Mes demandes de support',
              onTap: () => context.push(AppRoutes.support),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.headset_mic_outlined,
              title: 'Contacter le support',
              onTap: _contactSupport,
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.help_outline,
              title: 'Centre d\'aide (FAQ)',
              onTap: () => context.push(AppRoutes.helpCenter),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.school_outlined,
              title: 'Tutoriels interactifs',
              onTap: () => _showTutorialsSheet(),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.report_problem_outlined,
              title: 'Signaler un problème',
              onTap: () => context.push(AppRoutes.createTicket),
            ),
          ]),

          // 5. Informations légales
          const SizedBox(height: 24),
          _buildSectionHeader('Informations'),
          _buildCard([
            _buildActionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Politique de confidentialité',
              onTap: () => _openWebPage(AppConfig.privacyUrl),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.description_outlined,
              title: 'Conditions d\'utilisation',
              onTap: () => _openWebPage(AppConfig.termsUrl),
            ),
          ]),

          // 6. Zone dangereuse
          const SizedBox(height: 24),
          _buildSectionHeader('Zone dangereuse'),
          _buildCard([
            _buildActionTile(
              icon: Icons.delete_forever,
              title: 'Supprimer mon compte',
              titleColor: Colors.red,
              onTap: _showDeleteAccountDialog,
            ),
          ]),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Version $_appVersion',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildBiometricCard() {
    final biometricService = ref.watch(biometricServiceProvider);
    final biometricSettings = ref.watch(biometricSettingsProvider);

    return FutureBuilder<bool>(
      future: biometricService.canCheckBiometrics(),
      builder: (context, snapshot) {
        final canUseBiometric = snapshot.data ?? false;

        if (!canUseBiometric) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return _buildCard([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.grey).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                  size: 20,
                ),
              ),
              title: const Text(
                'Connexion biométrique',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                'Non disponible sur cet appareil',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade500 : Colors.grey,
                ),
              ),
              trailing: Icon(
                Icons.info_outline,
                color: isDark ? Colors.grey.shade500 : Colors.grey,
                size: 20,
              ),
            ),
          ]);
        }

        return FutureBuilder<List<AppBiometricType>>(
          future: biometricService.getAvailableBiometrics(),
          builder: (context, biometricTypesSnapshot) {
            final biometricTypes = biometricTypesSnapshot.data ?? [];
            String biometricLabel = 'Face ID / Touch ID';
            IconData biometricIcon = Icons.fingerprint;

            if (biometricTypes.contains(AppBiometricType.faceId)) {
              biometricLabel = 'Face ID';
              biometricIcon = Icons.face;
            } else if (biometricTypes.contains(AppBiometricType.fingerprint)) {
              biometricLabel = 'Touch ID';
              biometricIcon = Icons.fingerprint;
            }

            return _buildCard([
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(biometricIcon, color: Colors.green, size: 20),
                ),
                title: Text(
                  'Connexion par $biometricLabel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  biometricSettings
                      ? 'Activé - Se connecter avec $biometricLabel'
                      : 'Désactivé',
                  style: TextStyle(
                    fontSize: 12,
                    color: biometricSettings ? Colors.green : Colors.grey,
                  ),
                ),
                trailing: Switch.adaptive(
                  value: biometricSettings,
                  onChanged: (value) async {
                    if (value) {
                      // Demander l'authentification avant d'activer
                      final authenticated = await biometricService.authenticate(
                        reason:
                            'Confirmez votre identité pour activer $biometricLabel',
                      );
                      if (authenticated) {
                        await ref
                            .read(biometricSettingsProvider.notifier)
                            .enableBiometricLogin();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$biometricLabel activé avec succès',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } else {
                      await ref
                          .read(biometricSettingsProvider.notifier)
                          .disableBiometricLogin();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connexion biométrique désactivée'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                  activeTrackColor: Colors.green,
                ),
              ),
            ]);
          },
        );
      },
    );
  }

  void _showTutorialsSheet() {
    context.push(AppRoutes.tutorial);
  }

  void _showHomeWidgetSettings() {
    context.push(AppRoutes.homeWidgetSettings);
  }

  void _showAccessibilitySettings() {
    context.push(AppRoutes.accessibilitySettings);
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (titleColor ?? (isDark ? Colors.white : Colors.grey))
              .withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color:
              titleColor ??
              (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: titleColor,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: isDark ? Colors.grey.shade500 : Colors.grey,
          ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Expanded(child: Text('Supprimer mon compte')),
          ],
        ),
        content: const Text(
          'Cette action est irréversible. Toutes vos données personnelles, '
          'historique de livraisons et solde seront définitivement supprimés.\n\n'
          'Conformément à la loi n° 2013-450 relative à la protection des données '
          'à caractère personnel, votre demande sera traitée sous 72h.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(authRepositoryProvider);
        await repo.deleteAccount();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Demande de suppression envoyée. Votre compte sera supprimé sous 72h.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userFriendlyError(e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildNavigationSelector() {
    String label = 'Google Maps';
    if (_navigationApp == 'waze') label = 'Waze';
    if (_navigationApp == 'apple_maps') label = 'Apple Maps';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.map_outlined, color: Colors.orange, size: 20),
      ),
      title: const Text(
        'Application de Navigation',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.blue),
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Choisir l\'application GPS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.red),
                  title: const Text('Google Maps'),
                  trailing: _navigationApp == 'google_maps'
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    _updateNavigationApp('google_maps');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.directions_car, color: Colors.blue),
                  title: const Text('Waze'),
                  trailing: _navigationApp == 'waze'
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    _updateNavigationApp('waze');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: Colors.grey),
                  title: const Text('Apple Maps'),
                  trailing: _navigationApp == 'apple_maps'
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    _updateNavigationApp('apple_maps');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeSelector(ThemeMode currentMode) {
    // Utiliser le nouveau provider avec mode intelligent
    final appThemeMode = ref.watch(appThemeModeProvider);
    final appThemeNotifier = ref.read(appThemeModeProvider.notifier);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: appThemeMode == AppThemeMode.auto
              ? Colors.deepPurple.withValues(alpha: 0.1)
              : Colors.purple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          appThemeNotifier.modeIcon,
          color: appThemeMode == AppThemeMode.auto
              ? Colors.deepPurple
              : Colors.purple,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          const Text(
            'Thème',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          if (appThemeMode == AppThemeMode.auto) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'INTELLIGENT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        appThemeNotifier.modeDescription,
        style: const TextStyle(fontSize: 11, color: Colors.blue),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _showThemeSelectorDialog(appThemeMode),
    );
  }

  void _showThemeSelectorDialog(AppThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisir le thème',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Réduisez la fatigue visuelle pendant vos livraisons',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // ⭐ Mode Intelligent - NOUVEAU
              _ThemeOptionTile(
                icon: Icons.schedule,
                iconColor: Colors.deepPurple,
                title: 'Intelligent',
                subtitle: 'Mode sombre automatique la nuit (19h-6h)',
                isSelected: currentMode == AppThemeMode.auto,
                isRecommended: true,
                onTap: () {
                  ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.auto);
                  Navigator.pop(ctx);
                  _showAutoThemeActivatedSnackbar();
                },
              ),

              const Divider(height: 1, indent: 16, endIndent: 16),

              // Mode Système
              _ThemeOptionTile(
                icon: Icons.brightness_auto,
                iconColor: Colors.grey,
                title: 'Système',
                subtitle: 'Suit les paramètres de votre appareil',
                isSelected: currentMode == AppThemeMode.system,
                onTap: () {
                  ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),

              // Mode Clair
              _ThemeOptionTile(
                icon: Icons.light_mode,
                iconColor: Colors.orange,
                title: 'Clair',
                subtitle: 'Toujours en mode clair',
                isSelected: currentMode == AppThemeMode.light,
                onTap: () {
                  ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),

              // Mode Sombre
              _ThemeOptionTile(
                icon: Icons.dark_mode,
                iconColor: Colors.indigo,
                title: 'Sombre',
                subtitle: 'Toujours en mode sombre',
                isSelected: currentMode == AppThemeMode.dark,
                onTap: () {
                  ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),

              const SizedBox(height: 8),

              // Info sur le mode intelligent
              if (currentMode == AppThemeMode.auto)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Le mode intelligent bascule automatiquement entre clair et sombre pour protéger vos yeux pendant les livraisons de nuit.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutoThemeActivatedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mode intelligent activé! Le thème changera automatiquement selon l\'heure.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─── Voice Settings Card ───────────────────────────────────
  Widget _buildVoiceSettingsCard() {
    final voiceState = ref.watch(voiceServiceProvider);
    final settings = voiceState.settings;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Activer/Désactiver TTS
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over,
                color: Colors.deepPurple,
                size: 20,
              ),
            ),
            title: const Text(
              'Annonces vocales',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              settings.ttsEnabled ? 'Actif' : 'Désactivé',
              style: TextStyle(
                fontSize: 12,
                color: settings.ttsEnabled ? Colors.green : Colors.grey,
              ),
            ),
            value: settings.ttsEnabled,
            onChanged: (val) {
              ref
                  .read(voiceServiceProvider.notifier)
                  .updateSettings(settings.copyWith(ttsEnabled: val));
            },
          ),

          if (settings.ttsEnabled) ...[
            const Divider(height: 1),

            // Nouvelles livraisons
            SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              title: const Text(
                'Nouvelles livraisons',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text(
                'Annoncer les nouvelles commandes',
                style: TextStyle(fontSize: 12),
              ),
              value: settings.announceNewDeliveries,
              onChanged: (val) {
                ref
                    .read(voiceServiceProvider.notifier)
                    .updateSettings(
                      settings.copyWith(announceNewDeliveries: val),
                    );
              },
            ),

            const Divider(height: 1),

            // Navigation
            SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              title: const Text(
                'Guidage navigation',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text(
                'Annoncer les directions',
                style: TextStyle(fontSize: 12),
              ),
              value: settings.announceNavigation,
              onChanged: (val) {
                ref
                    .read(voiceServiceProvider.notifier)
                    .updateSettings(settings.copyWith(announceNavigation: val));
              },
            ),

            const Divider(height: 1),

            // Gains
            SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              title: const Text(
                'Annonce des gains',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text(
                'Lire les gains après livraison',
                style: TextStyle(fontSize: 12),
              ),
              value: settings.announceEarnings,
              onChanged: (val) {
                ref
                    .read(voiceServiceProvider.notifier)
                    .updateSettings(settings.copyWith(announceEarnings: val));
              },
            ),

            const Divider(height: 1),

            // Vitesse de parole
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.speed, color: Colors.teal, size: 20),
              ),
              title: const Text(
                'Vitesse de parole',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Slider(
                value: settings.speechRate,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: settings.speechRate < 0.4
                    ? 'Lent'
                    : settings.speechRate < 0.7
                    ? 'Normal'
                    : 'Rapide',
                onChanged: (val) {
                  ref
                      .read(voiceServiceProvider.notifier)
                      .updateSettings(settings.copyWith(speechRate: val));
                },
              ),
            ),

            const Divider(height: 1),

            // Test vocal
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  voiceState.isSpeaking ? Icons.stop_circle : Icons.play_circle,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              title: Text(
                voiceState.isSpeaking ? 'Arrêter' : 'Tester la voix',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: const Text(
                'Écouter un exemple d\'annonce',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                final vs = ref.read(voiceServiceProvider.notifier);
                if (voiceState.isSpeaking) {
                  vs.stop();
                } else {
                  vs.speak(
                    'Nouvelle livraison disponible. Pharmacie du Centre. Commission: 500 francs. Distance: 2 kilomètres.',
                    type: VoiceAnnouncementType.custom,
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget pour une option de thème dans le sélecteur
class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    this.isRecommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (isRecommended) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'RECOMMANDÉ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: isSelected
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            )
          : null,
      onTap: onTap,
    );
  }
}
