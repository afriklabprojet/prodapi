import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive.dart';
import '../../data/repositories/support_repository.dart';

/// FAQ items par défaut (fallback si API indisponible)
final List<_FAQItem> _defaultFaqItems = [
  _FAQItem(
    question: 'Comment accepter une livraison ?',
    answer: 'Quand une nouvelle livraison est disponible, vous recevez une notification. Allez dans l\'onglet "Livraisons" et appuyez sur "Accepter" pour prendre en charge la commande.',
    icon: Icons.delivery_dining,
  ),
  _FAQItem(
    question: 'Comment recharger mon portefeuille ?',
    answer: 'Allez dans votre profil > Portefeuille > Recharger. Vous pouvez payer par Mobile Money (Orange Money, MTN, Moov) ou par carte bancaire via JEKO.',
    icon: Icons.account_balance_wallet,
  ),
  _FAQItem(
    question: 'Pourquoi je ne peux plus livrer ?',
    answer: 'Si votre solde est insuffisant pour couvrir les commissions, vous ne pouvez plus accepter de livraisons. Rechargez votre portefeuille pour continuer.',
    icon: Icons.block,
  ),
  _FAQItem(
    question: 'Comment fonctionne la commission ?',
    answer: 'Une commission est prélevée sur chaque livraison terminée. Le montant est défini par la plateforme et déduit automatiquement de votre portefeuille.',
    icon: Icons.percent,
  ),
  _FAQItem(
    question: 'Comment confirmer une livraison ?',
    answer: 'À la livraison, demandez le code de confirmation au client. Entrez ce code à 4 chiffres dans l\'application pour valider la livraison et recevoir votre paiement.',
    icon: Icons.check_circle,
  ),
  _FAQItem(
    question: 'Comment mettre à jour ma position GPS ?',
    answer: 'Activez la localisation sur votre téléphone. L\'application met à jour votre position automatiquement toutes les 30 secondes quand vous êtes en ligne.',
    icon: Icons.location_on,
  ),
  _FAQItem(
    question: 'Comment voir l\'itinéraire vers le client ?',
    answer: 'Quand vous avez une livraison en cours, appuyez sur le bouton "Navigation" pour ouvrir Google Maps avec l\'itinéraire vers le client.',
    icon: Icons.map,
  ),
  _FAQItem(
    question: 'Comment changer mon mot de passe ?',
    answer: 'Allez dans Profil > Paramètres > Changer le mot de passe. Entrez votre mot de passe actuel puis le nouveau mot de passe deux fois.',
    icon: Icons.lock,
  ),
  _FAQItem(
    question: 'Que faire si le client est absent ?',
    answer: 'Essayez d\'appeler le client. Si après plusieurs tentatives il reste injoignable, contactez le support via les paramètres pour signaler le problème.',
    icon: Icons.person_off,
  ),
  _FAQItem(
    question: 'Comment contacter le support ?',
    answer: 'Allez dans Paramètres > Aide & Support > Contacter le support. Vous pouvez appeler directement ou envoyer un email.',
    icon: Icons.support_agent,
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

/// Provider pour charger les FAQ depuis l'API
final faqProvider = FutureProvider<List<_FAQItem>>((ref) async {
  final repository = ref.read(supportRepositoryProvider);
  final apiItems = await repository.getFaq();
  
  if (apiItems.isEmpty) {
    return _defaultFaqItems;
  }
  
  return apiItems.map((item) => _FAQItem(
    question: item.question,
    answer: item.answer,
    icon: _iconFromString(item.icon),
  )).toList();
});

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  String _searchQuery = '';

  List<_FAQItem> _filterItems(List<_FAQItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items.where((item) =>
      item.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      item.answer.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final faqAsync = ref.watch(faqProvider);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec gradient
          SliverAppBar(
            expandedHeight: context.r.hp(160),
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade800,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Centre d\'aide',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.r.sp(24),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Questions fréquentes',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Barre de recherche
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Rechercher une question...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: context.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Liste des FAQ
          ...faqAsync.when(
            loading: () => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
            error: (_, _) => [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final filtered = _filterItems(_defaultFaqItems);
                    return _FAQTile(item: filtered[index]);
                  },
                  childCount: _filterItems(_defaultFaqItems).length,
                ),
              ),
            ],
            data: (faqItems) {
              final filtered = _filterItems(faqItems);
              if (filtered.isEmpty) {
                return [
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: context.dividerColor),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun résultat trouvé',
                            style: TextStyle(
                              fontSize: 16,
                              color: context.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              }
              return [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _FAQTile(item: filtered[index]),
                    childCount: filtered.length,
                  ),
                ),
              ];
            },
          ),

          // Section contact en bas
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  Icon(Icons.headset_mic, size: 48, color: Colors.blue.shade600),
                  const SizedBox(height: 12),
                  const Text(
                    'Besoin d\'aide supplémentaire ?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notre équipe support est disponible 7j/7 de 8h à 22h',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.secondaryText),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(AppConfig.phoneUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text('Appeler'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => WhatsAppService.contactSupport(
                            supportNumber: AppConfig.supportWhatsApp,
                          ),
                          icon: const Icon(Icons.chat),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('mailto:${AppConfig.supportEmail}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.email),
                          label: const Text('Email'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;
  final IconData icon;

  _FAQItem({
    required this.question,
    required this.answer,
    required this.icon,
  });
}

class _FAQTile extends StatefulWidget {
  final _FAQItem item;

  const _FAQTile({required this.item});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _isExpanded ? Colors.blue.shade50 : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded ? Colors.blue.shade200 : context.dividerColor,
        ),
        boxShadow: _isExpanded
          ? [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isExpanded 
                        ? Colors.blue.shade100 
                        : context.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.item.icon,
                      size: 20,
                      color: _isExpanded 
                        ? Colors.blue.shade700 
                        : context.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _isExpanded 
                          ? Colors.blue.shade800 
                          : context.primaryText,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _isExpanded 
                        ? Colors.blue.shade600 
                        : context.iconColor,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 48),
                  child: Text(
                    widget.item.answer,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.secondaryText,
                      height: 1.5,
                    ),
                  ),
                ),
                crossFadeState: _isExpanded 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
