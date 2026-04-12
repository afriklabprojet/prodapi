import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/services/whatsapp_service.dart';
import '../../data/repositories/support_repository.dart';

// ============================================================================
// DESIGN SYSTEM - Executive Navy Theme
// ============================================================================

class _HelpColors {
  static const navyDark = Color(0xFF0F1C3F);
  static const navyMedium = Color(0xFF1A2B52);
  static const accentGold = Color(0xFFE5C76B);
  static const accentTeal = Color(0xFF2DD4BF);
  static const accentBlue = Color(0xFF60A5FA);
  static const bgLight = Color(0xFFF8FAFC);
  static const whatsappGreen = Color(0xFF25D366);
}

// ============================================================================
// FAQ DATA
// ============================================================================

// ============================================================================
// FAQ DATA
// ============================================================================

enum _FAQCategory {
  delivery('Livraisons', Icons.delivery_dining),
  wallet('Portefeuille', Icons.account_balance_wallet),
  technical('Technique', Icons.settings),
  account('Compte', Icons.person);

  const _FAQCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _FAQItem {
  final String question;
  final String answer;
  final IconData icon;
  final _FAQCategory category;

  _FAQItem({
    required this.question,
    required this.answer,
    required this.icon,
    required this.category,
  });
}

final List<_FAQItem> _defaultFaqItems = [
  _FAQItem(
    question: 'Comment accepter une livraison ?',
    answer:
        'Quand une nouvelle livraison est disponible, vous recevez une notification. Allez dans l\'onglet "Livraisons" et appuyez sur "Accepter" pour prendre en charge la commande.',
    icon: Icons.delivery_dining,
    category: _FAQCategory.delivery,
  ),
  _FAQItem(
    question: 'Comment confirmer une livraison ?',
    answer:
        'À la livraison, demandez le code de confirmation au client. Entrez ce code à 4 chiffres dans l\'application pour valider la livraison et recevoir votre paiement.',
    icon: Icons.check_circle,
    category: _FAQCategory.delivery,
  ),
  _FAQItem(
    question: 'Que faire si le client est absent ?',
    answer:
        'Essayez d\'appeler le client. Si après plusieurs tentatives il reste injoignable, contactez le support via les paramètres pour signaler le problème.',
    icon: Icons.person_off,
    category: _FAQCategory.delivery,
  ),
  _FAQItem(
    question: 'Comment voir l\'itinéraire vers le client ?',
    answer:
        'Quand vous avez une livraison en cours, appuyez sur le bouton "Navigation" pour ouvrir Google Maps avec l\'itinéraire vers le client.',
    icon: Icons.map,
    category: _FAQCategory.delivery,
  ),
  _FAQItem(
    question: 'Comment recharger mon portefeuille ?',
    answer:
        'Allez dans votre profil > Portefeuille > Recharger. Vous pouvez payer par Mobile Money (Orange Money, MTN, Moov) ou par carte bancaire via JEKO.',
    icon: Icons.account_balance_wallet,
    category: _FAQCategory.wallet,
  ),
  _FAQItem(
    question: 'Pourquoi je ne peux plus livrer ?',
    answer:
        'Si votre solde est insuffisant pour couvrir les commissions, vous ne pouvez plus accepter de livraisons. Rechargez votre portefeuille pour continuer.',
    icon: Icons.block,
    category: _FAQCategory.wallet,
  ),
  _FAQItem(
    question: 'Comment fonctionne la commission ?',
    answer:
        'Une commission est prélevée sur chaque livraison terminée. Le montant est défini par la plateforme et déduit automatiquement de votre portefeuille.',
    icon: Icons.percent,
    category: _FAQCategory.wallet,
  ),
  _FAQItem(
    question: 'Comment mettre à jour ma position GPS ?',
    answer:
        'Activez la localisation sur votre téléphone. L\'application met à jour votre position automatiquement toutes les 30 secondes quand vous êtes en ligne.',
    icon: Icons.location_on,
    category: _FAQCategory.technical,
  ),
  _FAQItem(
    question: 'Comment changer mon mot de passe ?',
    answer:
        'Allez dans Profil > Paramètres > Changer le mot de passe. Entrez votre mot de passe actuel puis le nouveau mot de passe deux fois.',
    icon: Icons.lock,
    category: _FAQCategory.account,
  ),
  _FAQItem(
    question: 'Comment contacter le support ?',
    answer:
        'Allez dans Paramètres > Aide & Support > Contacter le support. Vous pouvez appeler directement ou envoyer un email.',
    icon: Icons.support_agent,
    category: _FAQCategory.account,
  ),
];

/// Mapping des noms d'icônes vers IconData
IconData _iconFromString(String iconName) {
  const iconMap = <String, IconData>{
    'delivery_dining': Icons.delivery_dining,
    'account_balance_wallet': Icons.account_balance_wallet,
    'block': Icons.block,
    'percent': Icons.percent,
    'check_circle': Icons.check_circle,
    'location_on': Icons.location_on,
    'map': Icons.map,
    'lock': Icons.lock,
    'person_off': Icons.person_off,
    'support_agent': Icons.support_agent,
    'help': Icons.help,
    'info': Icons.info,
    'settings': Icons.settings,
    'payment': Icons.payment,
    'notifications': Icons.notifications,
    'security': Icons.security,
    'star': Icons.star,
  };
  return iconMap[iconName] ?? Icons.help;
}

_FAQCategory _categoryFromString(String? cat) {
  switch (cat) {
    case 'wallet':
      return _FAQCategory.wallet;
    case 'technical':
      return _FAQCategory.technical;
    case 'account':
      return _FAQCategory.account;
    default:
      return _FAQCategory.delivery;
  }
}

/// Provider pour charger les FAQ depuis l'API
final faqProvider = FutureProvider.autoDispose<List<_FAQItem>>((ref) async {
  final repository = ref.read(supportRepositoryProvider);
  final apiItems = await repository.getFaq();

  if (apiItems.isEmpty) {
    return _defaultFaqItems;
  }

  return apiItems
      .map(
        (item) => _FAQItem(
          question: item.question,
          answer: item.answer,
          icon: _iconFromString(item.icon),
          category: _categoryFromString(item.category),
        ),
      )
      .toList();
});

// ============================================================================
// MAIN SCREEN
// ============================================================================

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  _FAQCategory? _selectedCategory;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<_FAQItem> _filterItems(List<_FAQItem> items) {
    var filtered = items;
    if (_selectedCategory != null) {
      filtered = filtered
          .where((item) => item.category == _selectedCategory)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.question.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                item.answer.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final faqAsync = ref.watch(faqProvider);

    return Scaffold(
      backgroundColor: _HelpColors.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context),
          _buildQuickActions(context),
          _buildSearchBar(context),
          _buildCategoryFilter(context),
          _buildFAQList(faqAsync),
          _buildContactSection(context),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _HelpColors.navyDark,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_HelpColors.navyDark, _HelpColors.navyMedium],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _HelpColors.accentGold.withValues(alpha: 0.9),
                              _HelpColors.accentGold.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _HelpColors.accentGold.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          color: _HelpColors.navyDark,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Centre d\'aide',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Comment pouvons-nous vous aider ?',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
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
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // QUICK ACTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: _HelpColors.navyDark.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _QuickActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                color: _HelpColors.whatsappGreen,
                onTap: () => WhatsAppService.contactSupport(
                  supportNumber: AppConfig.supportWhatsApp,
                ),
              ),
              const SizedBox(width: 12),
              _QuickActionButton(
                icon: Icons.phone_outlined,
                label: 'Appeler',
                color: _HelpColors.accentBlue,
                onTap: () async {
                  final uri = Uri.parse(AppConfig.phoneUrl);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              ),
              const SizedBox(width: 12),
              _QuickActionButton(
                icon: Icons.email_outlined,
                label: 'Email',
                color: _HelpColors.accentTeal,
                onTap: () async {
                  final uri = Uri.parse('mailto:${AppConfig.supportEmail}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _HelpColors.navyDark.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Rechercher une question...',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey.shade400,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _HelpColors.navyMedium.withValues(alpha: 0.5),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CATEGORY FILTER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryFilter(BuildContext context) {
    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _CategoryChip(
              label: 'Tout',
              icon: Icons.apps,
              isSelected: _selectedCategory == null,
              onTap: () => setState(() => _selectedCategory = null),
            ),
            ..._FAQCategory.values.map(
              (cat) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _CategoryChip(
                  label: cat.label,
                  icon: cat.icon,
                  isSelected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FAQ LIST
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFAQList(AsyncValue<List<_FAQItem>> faqAsync) {
    return faqAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: CircularProgressIndicator(color: _HelpColors.navyDark),
          ),
        ),
      ),
      error: (_, stack) => _buildFAQItems(_filterItems(_defaultFaqItems)),
      data: (items) {
        final filtered = _filterItems(items);
        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _HelpColors.navyDark.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: _HelpColors.navyMedium.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat trouvé',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _HelpColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Essayez avec d\'autres mots-clés',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildFAQItems(filtered);
      },
    );
  }

  SliverList _buildFAQItems(List<_FAQItem> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _FAQTile(item: items[index], index: index),
        childCount: items.length,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONTACT SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContactSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_HelpColors.navyDark, _HelpColors.navyMedium],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _HelpColors.navyDark.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _HelpColors.accentGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                size: 40,
                color: _HelpColors.accentGold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Besoin d\'aide ?',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Notre équipe support est disponible\n7j/7 de 8h à 22h',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ContactButton(
                    icon: Icons.phone,
                    label: 'Appeler',
                    isPrimary: false,
                    onTap: () async {
                      final uri = Uri.parse(AppConfig.phoneUrl);
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _ContactButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    isPrimary: true,
                    onTap: () => WhatsAppService.contactSupport(
                      supportNumber: AppConfig.supportWhatsApp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SUPPORTING WIDGETS
// ============================================================================

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected ? _HelpColors.navyDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: isSelected ? 4 : 0,
        shadowColor: _HelpColors.navyDark.withValues(alpha: 0.2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : _HelpColors.navyDark.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : _HelpColors.navyMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _HelpColors.navyDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? _HelpColors.whatsappGreen
          : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQTile extends StatefulWidget {
  final _FAQItem item;
  final int index;

  const _FAQTile({required this.item, required this.index});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (widget.index * 50).clamp(0, 200)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _isExpanded
              ? _HelpColors.navyDark.withValues(alpha: 0.03)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded
                ? _HelpColors.navyDark.withValues(alpha: 0.15)
                : _HelpColors.navyDark.withValues(alpha: 0.06),
            width: _isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _HelpColors.navyDark.withValues(
                alpha: _isExpanded ? 0.08 : 0.03,
              ),
              blurRadius: _isExpanded ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: _isExpanded
                              ? const LinearGradient(
                                  colors: [
                                    _HelpColors.navyDark,
                                    _HelpColors.navyMedium,
                                  ],
                                )
                              : null,
                          color: _isExpanded
                              ? null
                              : _HelpColors.navyDark.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.item.icon,
                          size: 20,
                          color: _isExpanded
                              ? Colors.white
                              : _HelpColors.navyDark,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.item.question,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _HelpColors.navyDark,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _HelpColors.navyDark.withValues(
                              alpha: _isExpanded ? 0.1 : 0.05,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: _HelpColors.navyDark.withValues(
                              alpha: _isExpanded ? 0.8 : 0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14, left: 54),
                      child: Text(
                        widget.item.answer,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
