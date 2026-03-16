import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/presentation/widgets/widgets.dart';

class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _autoLockEnabled = true;
  int _sessionTimeoutMinutes = 15;
  bool _isLoading = true;

  // Session management
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoadingSessions = false;
  bool _isRevokingOthers = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final securityService = ref.read(securityServiceProvider);
    setState(() {
      _biometricEnabled = securityService.isBiometricEnabled();
      _pinEnabled = securityService.isPinEnabled();
      _sessionTimeoutMinutes = securityService.getSessionTimeout().inMinutes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sécurité'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Authentification
                  _buildSectionHeader('Authentification', Icons.fingerprint),
                  const SizedBox(height: 16),
                  
                  ModernCard(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.fingerprint,
                          iconColor: Theme.of(context).colorScheme.primary,
                          title: 'Authentification biométrique',
                          subtitle: 'Utiliser Face ID / Empreinte digitale',
                          value: _biometricEnabled,
                          onChanged: _toggleBiometric,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.pin,
                          iconColor: Colors.purple,
                          title: 'Code PIN',
                          subtitle: 'Définir un code PIN de sécurité',
                          value: _pinEnabled,
                          onChanged: _togglePin,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Section Session
                  _buildSectionHeader('Session', Icons.timer_outlined),
                  const SizedBox(height: 16),
                  
                  ModernCard(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.lock_clock,
                          iconColor: Colors.orange,
                          title: 'Verrouillage automatique',
                          subtitle: 'Verrouiller après inactivité',
                          value: _autoLockEnabled,
                          onChanged: (value) {
                            setState(() => _autoLockEnabled = value);
                          },
                        ),
                        if (_autoLockEnabled) ...[
                          const Divider(height: 1),
                          _buildTimeoutSelector(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section Appareils connectés
                  _buildSectionHeader('Appareils connectés', Icons.devices),
                  const SizedBox(height: 16),
                  _buildSessionsSection(),
                  const SizedBox(height: 32),
                  
                  // Section Données
                  _buildSectionHeader('Données', Icons.storage),
                  const SizedBox(height: 16),
                  
                  ModernCard(
                    child: Column(
                      children: [
                        _buildActionTile(
                          icon: Icons.delete_sweep,
                          iconColor: Colors.red,
                          title: 'Effacer le cache',
                          subtitle: 'Libérer de l\'espace',
                          onTap: _clearCache,
                        ),
                        const Divider(height: 1),
                        _buildActionTile(
                          icon: Icons.sync,
                          iconColor: Colors.blue,
                          title: 'Synchroniser maintenant',
                          subtitle: 'Forcer la synchronisation',
                          onTap: _forceSync,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Informations de sécurité
                  AlertCard(
                    message: 'Vos données sont chiffrées et stockées de manière sécurisée sur votre appareil.',
                    type: AlertType.info,
                    icon: Icons.shield_outlined,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutSelector() {
    final options = [
      {'value': 5, 'label': '5 minutes'},
      {'value': 15, 'label': '15 minutes'},
      {'value': 30, 'label': '30 minutes'},
      {'value': 60, 'label': '1 heure'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Délai avant verrouillage',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = _sessionTimeoutMinutes == option['value'];
              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  setState(() => _sessionTimeoutMinutes = option['value'] as int);
                  final securityService = ref.read(securityServiceProvider);
                  await securityService.setSessionTimeout(
                    Duration(minutes: _sessionTimeoutMinutes),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    option['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (enabled) {
      // Vérifier si l'appareil supporte la biométrie
      final securityService = ref.read(securityServiceProvider);
      final capability = await securityService.checkBiometricCapability();
      
      if (!capability.isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentification biométrique non disponible sur cet appareil'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Authentifier d'abord
      final result = await securityService.authenticateWithBiometric(
        reason: 'Confirmez votre identité pour activer la biométrie',
      );
      
      if (result.success) {
        await securityService.setBiometricEnabled(true);
        if (!mounted) return;
        setState(() => _biometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentification biométrique activée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      final securityService = ref.read(securityServiceProvider);
      await securityService.setBiometricEnabled(false);
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _togglePin(bool enabled) async {
    if (enabled) {
      _showSetPinDialog();
    } else {
      _showConfirmDisablePinDialog();
    }
  }

  void _showSetPinDialog() {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Définir un code PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Code PIN (4-6 chiffres)',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le code PIN',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (pinController.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le PIN doit faire au moins 4 chiffres')),
                );
                return;
              }
              if (pinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Les codes PIN ne correspondent pas')),
                );
                return;
              }
              
              final securityService = ref.read(securityServiceProvider);
              await securityService.setPinEnabled(true, pin: pinController.text);
              if (!mounted) return;
              setState(() => _pinEnabled = true);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code PIN défini avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ).whenComplete(() {
      pinController.dispose();
      confirmPinController.dispose();
    });
  }

  void _showConfirmDisablePinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver le code PIN ?'),
        content: const Text(
          'Votre compte sera moins sécurisé sans code PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              final securityService = ref.read(securityServiceProvider);
              await securityService.setPinEnabled(false);
              if (!mounted) return;
              setState(() => _pinEnabled = false);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  // ────── Session Management ──────

  Future<void> _loadSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/auth/sessions');
      final data = response.data['data'];
      final list = (data['sessions'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) setState(() => _sessions = list);
    } catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _revokeOtherSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnecter les autres appareils ?'),
        content: const Text(
          'Tous les autres appareils connectés à ce compte seront déconnectés immédiatement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isRevokingOthers = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/auth/sessions/revoke-others', data: {});
      final revoked = response.data['data']?['revoked_count'] ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$revoked autre(s) session(s) déconnectée(s)'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSessions();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la révocation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRevokingOthers = false);
    }
  }

  Widget _buildSessionsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Load sessions on first build
    if (_sessions.isEmpty && !_isLoadingSessions) {
      Future.microtask(() => _loadSessions());
    }

    return ModernCard(
      child: Column(
        children: [
          if (_isLoadingSessions)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // Session count info
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.smartphone, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_sessions.length}/2 appareils connectés',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Maximum 2 appareils simultanés',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    onPressed: _loadSessions,
                    tooltip: 'Actualiser',
                  ),
                ],
              ),
            ),

            // Session list
            ...List.generate(_sessions.length, (i) {
              final session = _sessions[i];
              final isCurrent = session['is_current'] == true;
              final name = session['name']?.toString() ?? 'Appareil inconnu';
              final lastUsed = session['last_used_at'] != null
                  ? DateTime.tryParse(session['last_used_at'].toString())
                  : null;
              final created = session['created_at'] != null
                  ? DateTime.tryParse(session['created_at'].toString())
                  : null;

              return Column(
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCurrent ? Icons.phone_android : Icons.phone_android_outlined,
                            color: isCurrent ? Colors.green : Colors.grey,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Cet appareil',
                                        style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                lastUsed != null
                                    ? 'Dernière activité: ${_formatSessionDate(lastUsed)}'
                                    : created != null
                                        ? 'Connecté le ${_formatSessionDate(created)}'
                                        : '',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),

            // Revoke others button
            if (_sessions.length > 1) ...[
              const Divider(height: 1),
              InkWell(
                onTap: _isRevokingOthers ? null : _revokeOtherSessions,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRevokingOthers)
                        const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                        )
                      else
                        const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Déconnecter les autres appareils',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 2) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return DateFormat('dd/MM/yyyy HH:mm', 'fr').format(date);
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer le cache ?'),
        content: const Text(
          'Cette action supprimera les données temporaires. Vous devrez peut-être vous reconnecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cacheService = ref.read(cacheServiceProvider);
      await cacheService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache effacé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _forceSync() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text('Synchronisation en cours...'),
          ],
        ),
        duration: Duration(seconds: 5),
      ),
    );
    
    // Utiliser le vrai service de synchronisation
    final syncService = ref.read(syncServiceProvider);
    final result = await syncService.syncNow();
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success 
            ? 'Synchronisation terminée (${result.syncedCount} éléments)'
            : result.message),
          backgroundColor: result.success ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
