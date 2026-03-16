import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';

/// Page des paramètres d'apparence
class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apparence'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Mode Section
          _SectionTitle(title: 'Thème', icon: Icons.palette),
          const SizedBox(height: 12),
          _ThemeModeSelector(
            currentMode: themeState.themeMode,
            onModeChanged: (mode) {
              themeNotifier.setThemeMode(mode);
              HapticFeedback.lightImpact();
            },
          ),
          
          const SizedBox(height: 24),
          
          // Accent Color Section
          _SectionTitle(title: 'Couleur d\'accent', icon: Icons.color_lens),
          const SizedBox(height: 12),
          _AccentColorSelector(
            currentColor: themeState.customAccentColor,
            onColorChanged: (colorHex) {
              themeNotifier.setAccentColor(colorHex);
              HapticFeedback.lightImpact();
            },
          ),
          
          const SizedBox(height: 24),
          
          // Preview Section
          _SectionTitle(title: 'Aperçu', icon: Icons.preview),
          const SizedBox(height: 12),
          _ThemePreview(isDark: isDark),
          
          const SizedBox(height: 24),
          
          // Additional Options
          _SectionTitle(title: 'Options supplémentaires', icon: Icons.tune),
          const SizedBox(height: 12),
          _OptionCard(
            title: 'Couleurs dynamiques',
            subtitle: 'Utiliser les couleurs du fond d\'écran (Android 12+)',
            icon: Icons.auto_awesome,
            trailing: Switch(
              value: themeState.useDynamicColors,
              onChanged: (value) {
                themeNotifier.setDynamicColors(value);
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          _OptionCard(
            title: 'Suivre le système',
            subtitle: 'Le thème s\'adapte aux paramètres du système',
            icon: Icons.settings_suggest,
            trailing: Icon(
              themeState.themeMode == ThemeMode.system
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: themeState.themeMode == ThemeMode.system
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
          ),
          
          const SizedBox(height: 24),
          
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Les modifications de thème sont appliquées instantanément et sauvegardées automatiquement.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Titre de section
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Sélecteur de mode de thème
class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) onModeChanged;

  const _ThemeModeSelector({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ThemeModeOption(
          icon: Icons.light_mode,
          label: 'Clair',
          isSelected: currentMode == ThemeMode.light,
          onTap: () => onModeChanged(ThemeMode.light),
        ),
        const SizedBox(width: 12),
        _ThemeModeOption(
          icon: Icons.dark_mode,
          label: 'Sombre',
          isSelected: currentMode == ThemeMode.dark,
          onTap: () => onModeChanged(ThemeMode.dark),
        ),
        const SizedBox(width: 12),
        _ThemeModeOption(
          icon: Icons.settings_brightness,
          label: 'Auto',
          isSelected: currentMode == ThemeMode.system,
          onTap: () => onModeChanged(ThemeMode.system),
        ),
      ],
    );
  }
}

/// Option de mode de thème
class _ThemeModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: isDark ? 0.3 : 0.1)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white70 : Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white70 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sélecteur de couleur d'accent
class _AccentColorSelector extends StatelessWidget {
  final String? currentColor;
  final Function(String?) onColorChanged;

  const _AccentColorSelector({
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppThemes.accentColors.entries.map((entry) {
        final isSelected = currentColor == entry.key || 
            (currentColor == null && entry.key == 'green');
        
        return GestureDetector(
          onTap: () => onColorChanged(entry.key == 'green' ? null : entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: entry.value,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: entry.value.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

/// Aperçu du thème
class _ThemePreview extends StatelessWidget {
  final bool isDark;

  const _ThemePreview({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final successColor = Colors.green;
    final warningColor = Colors.orange;
    final errorColor = Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Mini app bar
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'DR-PHARMA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.notifications_outlined,
                color: isDark ? Colors.white54 : Colors.grey,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Mini cards
          Row(
            children: [
              _MiniCard(isDark: isDark, color: successColor, icon: Icons.check),
              const SizedBox(width: 8),
              _MiniCard(isDark: isDark, color: warningColor, icon: Icons.access_time),
              const SizedBox(width: 8),
              _MiniCard(isDark: isDark, color: errorColor, icon: Icons.close),
            ],
          ),
          const SizedBox(height: 12),
          
          // Mini button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Bouton principal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini carte pour l'aperçu
class _MiniCard extends StatelessWidget {
  final bool isDark;
  final Color color;
  final IconData icon;

  const _MiniCard({
    required this.isDark,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'option
class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
