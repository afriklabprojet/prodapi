import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive.dart';
import '../providers/profile_provider.dart';
import '../widgets/common/common_widgets.dart';
import '../../data/models/user.dart';
import '../../data/models/wallet_data.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import 'login_screen_redesign.dart';
import 'deliveries_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'advanced_dashboard_screen.dart';
import 'help_center_screen.dart';

// --- Providers ---

// Provider pour les données réelles du wallet (statistiques)
final profileWalletProvider = FutureProvider.autoDispose<WalletData?>((ref) async {
  try {
    final repo = ref.read(walletRepositoryProvider);
    return await repo.getWalletData();
  } catch (e) {
    return null;
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(profileProvider);
    // Écouter les changements de thème
    ref.watch(themeProvider);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      body: AsyncValueWidget<User>(
        value: userAsync,
        data: (user) => _ProfileView(user: user),
        onRetry: () => ref.refresh(profileProvider),
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  final User user;

  const _ProfileView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _HeaderSection(user: user),
          Padding(
            padding: context.r.pad(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Aperçu'),
                const SizedBox(height: 16),
                _StatsGrid(user: user),
                const SizedBox(height: 32),
                _SectionTitle(title: 'Personnel & Véhicule'),
                const SizedBox(height: 16),
                _InfoSection(user: user),
                const SizedBox(height: 32),
                _SectionTitle(title: 'Hebdomadaire'),
                const SizedBox(height: 16),
                _PerformanceCard(),
                const SizedBox(height: 32),
                _SectionTitle(title: 'Préférences'),
                const SizedBox(height: 16),
                _ActionsSection(),
                const SizedBox(height: 40),
                _LogoutButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 1. Header Premium ---

class _HeaderSection extends ConsumerStatefulWidget {
  final User user;

  const _HeaderSection({required this.user});

  @override
  ConsumerState<_HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends ConsumerState<_HeaderSection> {
  late bool isOnline;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isOnline = widget.user.courier?.status == 'available';
  }

  @override
  void didUpdateWidget(_HeaderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.courier?.status != widget.user.courier?.status) {
      isOnline = widget.user.courier?.status == 'available';
    }
  }

  Future<void> _toggleAvailability() async {
    setState(() => isLoading = true);
    try {
      // Envoie le statut souhaité explicitement (inverse de l'état actuel)
      final desiredStatus = isOnline ? 'offline' : 'available';
      final actualStatus = await ref.read(deliveryRepositoryProvider).toggleAvailability(desiredStatus: desiredStatus);
      if (!mounted) return;
      setState(() {
        isOnline = actualStatus;
      });
      // Refresh global profile to keep sync
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        // Extraire le message d'erreur propre
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courierInfo = widget.user.courier;
    final r = context.r;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r.dp(20), topPadding + r.dp(20), r.dp(20), r.dp(30)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar & Info
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          backgroundImage: widget.user.avatar != null 
                              ? CachedNetworkImageProvider(widget.user.avatar!) 
                              : null,
                          child: widget.user.avatar == null
                              ? Text(
                                  widget.user.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Status Dot Pulse
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.greenAccent : Colors.grey,
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isOnline)
                              BoxShadow(
                                color: Colors.greenAccent.withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (courierInfo?.vehicleType ?? 'Transporteur').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Status Switch
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(
                        isOnline ? Icons.power_settings_new : Icons.pause_circle_outline,
                        color: isOnline ? Colors.greenAccent : Colors.white54,
                      ),
                  onPressed: isLoading ? null : _toggleAvailability,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 2. Stats Dashboard (Grid 2x2) ---

class _StatsGrid extends ConsumerWidget {
  final User user;

  const _StatsGrid({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(profileWalletProvider);
    final courier = user.courier;

    // Récupérer les vraies stats du wallet ou valeurs par défaut
    final walletData = walletAsync.whenOrNull(data: (data) => data);
    final deliveriesCount = walletData?.deliveriesCount ?? courier?.completedDeliveries ?? 0;
    final totalCommissions = walletData?.totalCommissions ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.local_shipping_outlined,
          value: '$deliveriesCount',
          label: 'Total Livré',
          color: Colors.blue.shade700,
          bgColor: Colors.blue.shade50,
        ),
        _StatCard(
          icon: Icons.star_outline_rounded,
          value: '${courier?.rating ?? 5.0}',
          label: 'Note Moyenne',
          color: Colors.orange.shade700,
          bgColor: Colors.orange.shade50,
        ),
        _StatCard(
          icon: Icons.account_balance_wallet_outlined,
          value: NumberFormat("#,##0", "fr_FR").format(walletData?.balance ?? 0),
          label: 'Solde (FCFA)',
          color: Colors.green.shade700,
          bgColor: Colors.green.shade50,
        ),
        _StatCard(
          icon: Icons.trending_down,
          value: NumberFormat("#,##0", "fr_FR").format(totalCommissions),
          label: 'Commissions',
          color: Colors.purple.shade700,
          bgColor: Colors.purple.shade50,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? bgColor.withValues(alpha: 0.2) : bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper pour le type de véhicule ---
String _getVehicleLabel(String? vehicleType) {
  switch (vehicleType?.toLowerCase()) {
    case 'motorcycle':
      return 'Moto';
    case 'bicycle':
      return 'Vélo';
    case 'car':
      return 'Voiture';
    case 'scooter':
      return 'Scooter';
    case null:
      return 'Non défini';
    default:
      return vehicleType!;
  }
}

// --- 3. Informations Section ---

class _InfoSection extends ConsumerWidget {
  final User user;

  const _InfoSection({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.email_outlined,
            title: 'Email',
            value: user.email,
            isFirst: true,
          ),
          _Separator(),
          _InfoTile(
            icon: Icons.phone_android_outlined,
            title: 'Téléphone',
            value: user.phone ?? 'Non renseigné',
            action: Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
            onTap: () => _showEditPhoneDialog(context, ref, user.phone),
          ),
          _Separator(),
          _InfoTile(
            icon: Icons.directions_bike_outlined,
            title: 'Véhicule',
            value: user.courier != null 
                ? '${_getVehicleLabel(user.courier?.vehicleType)} (${user.courier?.vehicleNumber ?? "---"})'
                : '⚠️ Profil coursier non configuré',
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(BuildContext context, WidgetRef ref, String? currentPhone) {
    final isDark = context.isDark;
    final controller = TextEditingController(text: currentPhone ?? '');
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.phone_android, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Text(
              'Modifier le téléphone',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Entrez votre nouveau numéro de téléphone',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: '+225 07 XX XX XX XX',
                  prefixIcon: Icon(Icons.phone, color: Colors.blue.shade700),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un numéro';
                  }
                  // Validation basique du format téléphone
                  final phone = value.replaceAll(RegExp(r'[\s\-\.]'), '');
                  if (phone.length < 8) {
                    return 'Numéro trop court';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                await _updatePhone(context, ref, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePhone(BuildContext context, WidgetRef ref, String newPhone) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateProfile(phone: newPhone);
      
      // Fermer le loader
      if (context.mounted) Navigator.pop(context);
      
      // Rafraîchir le profil
      ref.invalidate(profileProvider);
      
      // Message de succès
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Numéro de téléphone mis à jour'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      // Fermer le loader
      if (context.mounted) Navigator.pop(context);
      
      // Message d'erreur
      if (context.mounted) {
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Widget? action;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.action,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.blue.shade800, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

// --- 4. Performance Card ---

class _PerformanceCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(profileWalletProvider);
    final walletData = walletAsync.whenOrNull(data: (data) => data);
    
    // Données réelles du wallet
    final totalEarnings = walletData?.totalEarnings ?? 0;
    final deliveriesCount = walletData?.deliveriesCount ?? 0;
    final totalTopups = walletData?.totalTopups ?? 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50), // Dark elegant background
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text(
                 'Gains de Livraison',
                 style: TextStyle(color: Colors.white70, fontSize: 14),
               ),
               if (deliveriesCount > 0)
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: Colors.white.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Icon(Icons.local_shipping, color: Colors.greenAccent, size: 14),
                       const SizedBox(width: 4),
                       Text('$deliveriesCount', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                     ],
                   ),
                 )
             ],
           ),
           const SizedBox(height: 8),
           Text(
             '${NumberFormat("#,##0", "fr_FR").format(totalEarnings)} FCFA',
             style: const TextStyle(
               color: Colors.white,
               fontSize: 32,
               fontWeight: FontWeight.bold,
             ),
           ),
           const SizedBox(height: 24),
           Row(
             children: [
               _PerformanceMetrics(label: 'Livraisons', value: '$deliveriesCount'),
               _VerticalDivider(),
               _PerformanceMetrics(label: 'Rechargé', value: NumberFormat.compact(locale: 'fr').format(totalTopups)),
               _VerticalDivider(),
               _PerformanceMetrics(label: 'Solde', value: NumberFormat.compact(locale: 'fr').format(walletData?.balance ?? 0)),
             ],
           )
        ],
      ),
    );
  }
}

class _PerformanceMetrics extends StatelessWidget {
  final String label;
  final String value;
  
  const _PerformanceMetrics({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
         children: [
           Text(
             value,
             style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 4),
           Text(
             label,
             style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
           ),
         ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1), 
    );
  }
}

// --- 5. Quick Actions ---

class _ActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionButton(
          icon: Icons.dashboard_rounded, 
          label: 'Dashboard',
          color: Colors.indigo,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdvancedDashboardScreen()),
            );
          },
        ),
        _ActionButton(
          icon: Icons.bar_chart_rounded, 
          label: 'Statistiques',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StatisticsScreen()),
            );
          },
        ),
        _ActionButton(
          icon: Icons.history, 
          label: 'Historique',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeliveriesScreen()),
            );
          },
        ),
        _ActionButton(
          icon: Icons.settings_outlined, 
          label: 'Paramètres',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        _ActionButton(
          icon: Icons.help_outline, 
          label: 'Aide & Support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon, 
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final buttonColor = color ?? Colors.blue;
    return ActionChip(
      avatar: Icon(icon, size: 18, color: buttonColor),
      label: Text(label),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      labelStyle: TextStyle(color: isDark ? buttonColor.withValues(alpha: 0.8) : buttonColor, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: onTap,
    );
  }
}

// --- Components ---

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, indent: 60);
  }
}

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
            _confirmLogout(context, ref);
        },
        icon: Icon(Icons.logout, color: Colors.red.shade400, size: 20),
        label: Text(
          'Se déconnecter de l\'application',
          style: TextStyle(color: Colors.red.shade400, fontSize: 14),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    // Capturer le Navigator du contexte parent AVANT d'ouvrir le dialog
    final navigator = Navigator.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              elevation: 0,
            ),
            onPressed: () async {
              // Fermer le dialog d'abord
              Navigator.pop(dialogContext);
              
              // Effectuer la déconnexion
              await ref.read(authRepositoryProvider).logout();
              
              // Utiliser le navigator capturé pour rediriger vers LoginScreen
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreenRedesign()),
                (route) => false,
              );
            },
            child: Text('Déconnecter', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }
}
