import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/advanced_home_widget_service.dart';

/// Écran de configuration du widget écran d'accueil
/// ================================================

class HomeWidgetSettingsScreen extends ConsumerStatefulWidget {
  const HomeWidgetSettingsScreen({super.key});

  @override
  ConsumerState<HomeWidgetSettingsScreen> createState() =>
      _HomeWidgetSettingsScreenState();
}

class _HomeWidgetSettingsScreenState
    extends ConsumerState<HomeWidgetSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final widgetState = ref.watch(advancedHomeWidgetProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Écran d\'Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(advancedHomeWidgetProvider.notifier).forceRefresh();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Widget actualisé')));
            },
            tooltip: 'Actualiser le widget',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preview du widget
          _buildWidgetPreview(widgetState, isDark),
          const SizedBox(height: 24),

          // Style du widget
          _buildStyleSection(widgetState, theme),
          const SizedBox(height: 24),

          // Options d'affichage
          _buildDisplayOptions(widgetState, theme),
          const SizedBox(height: 24),

          // Objectif quotidien
          _buildDailyGoalSection(widgetState, theme),
          const SizedBox(height: 24),

          // Instructions d'ajout
          _buildAddWidgetInstructions(theme),
        ],
      ),
    );
  }

  Widget _buildWidgetPreview(HomeWidgetState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu du Widget',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2936) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildWidgetContent(state, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetContent(HomeWidgetState state, bool isDark) {
    final primaryColor = const Color(0xFF0A84FF);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // En-tête
          Row(
            children: [
              // Logo
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_pharmacy,
                  size: 18,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DR PHARMA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              // Badge statut
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: state.isOnline
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isOnline ? Icons.circle : Icons.circle_outlined,
                      size: 8,
                      color: state.isOnline ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.isOnline ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: state.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (state.style != WidgetStyle.compact) ...[
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.delivery_dining,
                    value: '${state.todayDeliveries}',
                    label: 'Livraisons',
                    color: primaryColor,
                    isDark: isDark,
                  ),
                ),
                if (state.showEarnings)
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.account_balance_wallet,
                      value: '${state.todayEarnings}',
                      label: 'FCFA',
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),

            // Livraison active
            if (state.hasActiveDelivery) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 14,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.deliveryStep.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const Spacer(),
                        if (state.estimatedTime != null)
                          Text(
                            state.estimatedTime!,
                            style: TextStyle(
                              fontSize: 10,
                              color: secondaryTextColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Barre de progression
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: state.deliveryStep.progress,
                        backgroundColor: isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(primaryColor),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.customerAddress ?? 'Adresse client',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],

            // Objectif (style détaillé)
            if (state.style == WidgetStyle.detailed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Objectif: ${state.todayDeliveries}/${state.dailyGoal}',
                    style: TextStyle(fontSize: 11, color: secondaryTextColor),
                  ),
                  const Spacer(),
                  Text(
                    '${(state.goalProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: state.goalProgress >= 1.0
                          ? Colors.green
                          : primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.goalProgress,
                  backgroundColor: isDark
                      ? Colors.white12
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    state.goalProgress >= 1.0 ? Colors.green : primaryColor,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStyleSection(HomeWidgetState state, ThemeData theme) {
    return RadioGroup<WidgetStyle>(
      groupValue: state.style,
      onChanged: (value) {
        if (value != null) {
          ref.read(advancedHomeWidgetProvider.notifier).setWidgetStyle(value);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Style du Widget',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...WidgetStyle.values.map(
            (style) => _buildStyleOption(
              style: style,
              isSelected: state.style == style,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleOption({
    required WidgetStyle style,
    required bool isSelected,
    required ThemeData theme,
  }) {
    String title;
    String description;
    IconData icon;

    switch (style) {
      case WidgetStyle.compact:
        title = 'Compact';
        description = 'Affiche uniquement le statut en ligne';
        icon = Icons.crop_square;
        break;
      case WidgetStyle.standard:
        title = 'Standard';
        description = 'Stats du jour + livraison active';
        icon = Icons.rectangle;
        break;
      case WidgetStyle.detailed:
        title = 'Détaillé';
        description = 'Toutes les infos + progression objectif';
        icon = Icons.crop_din;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<WidgetStyle>(
        value: style,
        title: Text(title),
        subtitle: Text(description, style: TextStyle(fontSize: 12)),
        secondary: Icon(icon, color: isSelected ? theme.primaryColor : null),
      ),
    );
  }

  Widget _buildDisplayOptions(HomeWidgetState state, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options d\'Affichage',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            title: const Text('Afficher les gains'),
            subtitle: const Text('Montrer le total gagné aujourd\'hui'),
            secondary: const Icon(Icons.account_balance_wallet),
            value: state.showEarnings,
            onChanged: (value) {
              ref
                  .read(advancedHomeWidgetProvider.notifier)
                  .setShowEarnings(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalSection(HomeWidgetState state, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectif Quotidien',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.flag, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nombre de livraisons',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${state.dailyGoal} livraisons par jour',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '${state.dailyGoal}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Slider(
                        value: state.dailyGoal.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '${state.dailyGoal}',
                        onChanged: (value) {
                          ref
                              .read(advancedHomeWidgetProvider.notifier)
                              .setDailyGoal(value.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddWidgetInstructions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajouter le Widget',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: theme.primaryColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionStep(
                  number: 1,
                  text: 'Appuyez longuement sur l\'écran d\'accueil',
                  theme: theme,
                ),
                _buildInstructionStep(
                  number: 2,
                  text: 'Sélectionnez "Widgets" dans le menu',
                  theme: theme,
                ),
                _buildInstructionStep(
                  number: 3,
                  text: 'Recherchez "DR Pharma Coursier"',
                  theme: theme,
                ),
                _buildInstructionStep(
                  number: 4,
                  text: 'Faites glisser le widget vers votre écran',
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: theme.hintColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Le widget se met à jour automatiquement avec vos livraisons.',
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Instructions spécifiques Tecno/Infinix/itel (HiOS / XOS)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: Icon(Icons.phone_android, color: theme.hintColor),
          title: Text(
            'Tecno, Infinix ou itel ?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.hintColor,
            ),
          ),
          children: [
            Card(
              color: Colors.orange.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Les launchers HiOS / XOS utilisent un menu différent :',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      number: 1,
                      text:
                          'Pincez l\'écran d\'accueil (2 doigts) ou appuyez longuement sur un espace vide',
                      theme: theme,
                    ),
                    _buildInstructionStep(
                      number: 2,
                      text: 'Appuyez sur « Widgets » en bas de l\'écran',
                      theme: theme,
                    ),
                    _buildInstructionStep(
                      number: 3,
                      text: 'Faites défiler et cherchez « DR Pharma »',
                      theme: theme,
                    ),
                    _buildInstructionStep(
                      number: 4,
                      text: 'Maintenez le widget puis déposez-le sur l\'écran',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.battery_saver,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Important : allez dans Paramètres → Batterie → Gestion des applications → DR Pharma Coursier → Autoriser l\'activité en arrière-plan. Sans cela, le widget peut ne pas se mettre à jour.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructionStep({
    required int number,
    required String text,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
