import 'package:flutter/material.dart';

class PreferencesSection extends StatelessWidget {
  final VoidCallback onDashboard;
  final VoidCallback onStatistics;
  final VoidCallback onHistory;
  final VoidCallback onBadges;
  final VoidCallback onSettings;
  final VoidCallback onHelp;

  const PreferencesSection({
    super.key,
    required this.onDashboard,
    required this.onStatistics,
    required this.onHistory,
    required this.onBadges,
    required this.onSettings,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Menu rapide',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          _divider(),
          _menuTile(
            icon: Icons.space_dashboard_outlined,
            label: 'Dashboard',
            subtitle: 'Vue d\'ensemble',
            color: const Color(0xFF6366F1),
            onTap: onDashboard,
          ),
          _divider(),
          _menuTile(
            icon: Icons.insights_rounded,
            label: 'Statistiques',
            subtitle: 'Performances & analyses',
            color: const Color(0xFF059669),
            onTap: onStatistics,
          ),
          _divider(),
          _menuTile(
            icon: Icons.receipt_long_outlined,
            label: 'Historique',
            subtitle: 'Vos livraisons passées',
            color: const Color(0xFF3B82F6),
            onTap: onHistory,
          ),
          _divider(),
          _menuTile(
            icon: Icons.emoji_events_rounded,
            label: 'Progression',
            subtitle: 'Badges & défis',
            color: const Color(0xFFF97316),
            onTap: onBadges,
          ),
          _divider(),
          _menuTile(
            icon: Icons.tune_rounded,
            label: 'Paramètres',
            subtitle: 'Préférences & sécurité',
            color: const Color(0xFF6B7280),
            onTap: onSettings,
          ),
          _divider(),
          _menuTile(
            icon: Icons.support_agent_rounded,
            label: 'Aide & Support',
            subtitle: 'FAQ & contact',
            color: const Color(0xFFF59E0B),
            onTap: onHelp,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D26),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 74),
      child: Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
    );
  }
}
