import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/accessibility_service.dart';

/// Écran de paramètres d'accessibilité
/// ===================================

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accessibilityProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Accessibilité')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Introduction
          Card(
            color: theme.primaryColor.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.accessibility_new,
                    color: theme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Options d\'accessibilité',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personnalisez l\'application selon vos besoins',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section Vision
          _buildSectionHeader('Vision', Icons.visibility, theme),
          const SizedBox(height: 12),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.contrast,
              title: 'Contraste élevé',
              subtitle: 'Augmente le contraste des couleurs',
              value: state.highContrast,
              onChanged: (value) {
                ref.read(accessibilityProvider.notifier).setHighContrast(value);
              },
              theme: theme,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.format_size,
              title: 'Texte large',
              subtitle: 'Agrandit la taille du texte (x1.3)',
              value: state.largeText,
              onChanged: (value) {
                ref.read(accessibilityProvider.notifier).setLargeText(value);
              },
              theme: theme,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.format_bold,
              title: 'Texte en gras',
              subtitle: 'Rend le texte plus épais',
              value: state.boldText,
              onChanged: (value) {
                ref.read(accessibilityProvider.notifier).setBoldText(value);
              },
              theme: theme,
            ),
          ], theme),
          const SizedBox(height: 12),
          _buildCard([
            _buildSliderTile(
              icon: Icons.text_fields,
              title: 'Taille du texte',
              value: state.textScaleFactor,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              formatValue: (v) => '${(v * 100).toInt()}%',
              onChanged: (value) {
                ref
                    .read(accessibilityProvider.notifier)
                    .setTextScaleFactor(value);
              },
              theme: theme,
            ),
          ], theme),
          const SizedBox(height: 24),

          // Section Mouvement
          _buildSectionHeader('Mouvement', Icons.animation, theme),
          const SizedBox(height: 12),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.slow_motion_video,
              title: 'Réduire les animations',
              subtitle: 'Désactive les animations et transitions',
              value: state.reduceMotion,
              onChanged: (value) {
                ref.read(accessibilityProvider.notifier).setReduceMotion(value);
              },
              theme: theme,
            ),
          ], theme),
          const SizedBox(height: 24),

          // Section Lecteur d'écran
          _buildSectionHeader(
            'Lecteur d\'écran',
            Icons.record_voice_over,
            theme,
          ),
          const SizedBox(height: 12),
          _buildCard([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (state.screenReaderEnabled ? Colors.green : Colors.grey)
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.record_voice_over,
                  color: state.screenReaderEnabled ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
              title: const Text(
                'VoiceOver / TalkBack',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                state.screenReaderEnabled ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: state.screenReaderEnabled ? Colors.green : null,
                ),
              ),
              trailing: Icon(
                state.screenReaderEnabled
                    ? Icons.check_circle
                    : Icons.info_outline,
                color: state.screenReaderEnabled ? Colors.green : Colors.grey,
              ),
            ),
          ], theme),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.hintColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le lecteur d\'écran est contrôlé depuis les paramètres système de votre appareil.',
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Aperçu
          _buildSectionHeader('Aperçu', Icons.preview, theme),
          const SizedBox(height: 12),
          _buildPreviewCard(state, theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
  }) {
    return Semantics(
      toggled: value,
      label: '$title. $subtitle',
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (value ? theme.primaryColor : Colors.grey).withValues(
              alpha: 0.1,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: value ? theme.primaryColor : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) formatValue,
    required ValueChanged<double> onChanged,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatValue(value),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: formatValue(value),
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatValue(min),
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
              Text(
                formatValue(max),
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(AccessibilityState state, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: state.highContrast ? Colors.black : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: state.highContrast
            ? Border.all(color: Colors.white, width: 2)
            : null,
        boxShadow: state.highContrast
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exemple de texte',
            style: TextStyle(
              fontSize: 18 * state.textScaleFactor,
              fontWeight: state.boldText ? FontWeight.bold : FontWeight.w600,
              color: state.highContrast ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ceci est un exemple de texte avec les paramètres actuels. '
            'Vous pouvez voir comment le texte apparaîtra dans l\'application.',
            style: TextStyle(
              fontSize: 14 * state.textScaleFactor,
              fontWeight: state.boldText ? FontWeight.w600 : FontWeight.normal,
              height: 1.5,
              color: state.highContrast ? Colors.white70 : null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: null, // Bouton de prévisualisation désactivé
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.highContrast
                        ? Colors.white
                        : theme.primaryColor,
                    foregroundColor: state.highContrast
                        ? Colors.black
                        : Colors.white,
                    disabledBackgroundColor: state.highContrast
                        ? Colors.white
                        : theme.primaryColor,
                    disabledForegroundColor: state.highContrast
                        ? Colors.black
                        : Colors.white,
                  ),
                  child: Text(
                    'Bouton',
                    style: TextStyle(
                      fontSize: 14 * state.textScaleFactor,
                      fontWeight: state.boldText
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: null, // Bouton de prévisualisation désactivé
                  style: OutlinedButton.styleFrom(
                    foregroundColor: state.highContrast ? Colors.white : null,
                    disabledForegroundColor: state.highContrast
                        ? Colors.white70
                        : null,
                    side: state.highContrast
                        ? const BorderSide(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      fontSize: 14 * state.textScaleFactor,
                      fontWeight: state.boldText
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
