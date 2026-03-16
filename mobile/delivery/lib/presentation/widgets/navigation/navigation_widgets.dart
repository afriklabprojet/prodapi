import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/navigation_service.dart';
import '../../../data/models/route_info.dart';

/// Widget compact pour lancer la navigation avec sélecteur d'apps
class NavigationLaunchButton extends ConsumerWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationName;
  final bool compact;

  const NavigationLaunchButton({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navService = ref.read(navigationServiceProvider);

    if (compact) {
      return FloatingActionButton.small(
        heroTag: 'nav_launch_${destinationLat}_$destinationLng',
        onPressed: () => _launchNavigation(context, navService),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        child: const Icon(Icons.navigation, color: Colors.blue),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _launchNavigation(context, navService),
      icon: const Icon(Icons.navigation_rounded),
      label: const Text('Navigation'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  void _launchNavigation(BuildContext context, NavigationService navService) {
    navService.showAppSelector(
      context,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      destinationName: destinationName,
    );
  }
}

/// Widget de prévisualisation des instructions de navigation
class NavigationPreviewCard extends StatelessWidget {
  final RouteInfo routeInfo;
  final VoidCallback onLaunchNavigation;
  final VoidCallback? onShowFullInstructions;

  const NavigationPreviewCard({
    super.key,
    required this.routeInfo,
    required this.onLaunchNavigation,
    this.onShowFullInstructions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final instructions = routeInfo.instructions;
    
    if (instructions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec durée totale
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeInfo.totalDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        routeInfo.totalDistance,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onLaunchNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Démarrer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Instructions preview (2-3 premières)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ...instructions.take(3).map((instruction) => _InstructionTile(
                  instruction: instruction,
                  isFirst: instruction == instructions.first,
                )),
                
                if (instructions.length > 3)
                  GestureDetector(
                    onTap: onShowFullInstructions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${instructions.length - 3} étapes en plus',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade600),
                        ],
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

class _InstructionTile extends StatelessWidget {
  final RouteStep instruction;
  final bool isFirst;

  const _InstructionTile({
    required this.instruction,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isFirst 
                  ? Colors.blue.withValues(alpha: 0.15)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getManeuverIcon(instruction.maneuver),
              color: isFirst ? Colors.blue : Colors.grey.shade600,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction.text,
                  style: TextStyle(
                    fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  instruction.distance,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
      case 'turn-slight-left':
      case 'turn-sharp-left':
        return Icons.turn_left;
      case 'turn-right':
      case 'turn-slight-right':
      case 'turn-sharp-right':
        return Icons.turn_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_right;
      case 'roundabout':
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'merge':
        return Icons.merge;
      case 'ramp':
      case 'ramp-left':
      case 'ramp-right':
        return Icons.ramp_right;
      default:
        return Icons.straight;
    }
  }
}

/// Widget de barre de navigation compacte pour le haut de l'écran
class NavigationBar extends StatelessWidget {
  final String destination;
  final String eta;
  final String distance;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const NavigationBar({
    super.key,
    required this.destination,
    required this.eta,
    required this.distance,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        destination,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            eta,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.straighten, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet pour afficher toutes les instructions
class FullInstructionsSheet extends StatelessWidget {
  final RouteInfo routeInfo;
  final VoidCallback onLaunchNavigation;

  const FullInstructionsSheet({
    super.key,
    required this.routeInfo,
    required this.onLaunchNavigation,
  });

  static Future<void> show(
    BuildContext context, {
    required RouteInfo routeInfo,
    required VoidCallback onLaunchNavigation,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => FullInstructionsSheet(
          routeInfo: routeInfo,
          onLaunchNavigation: onLaunchNavigation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Itinéraire',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${routeInfo.totalDuration} • ${routeInfo.totalDistance}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onLaunchNavigation,
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text('Démarrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Instructions list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: routeInfo.instructions.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 52),
              itemBuilder: (context, index) {
                final instruction = routeInfo.instructions[index];
                final isLast = index == routeInfo.instructions.length - 1;
                
                return _FullInstructionTile(
                  instruction: instruction,
                  stepNumber: index + 1,
                  isLast: isLast,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FullInstructionTile extends StatelessWidget {
  final RouteStep instruction;
  final int stepNumber;
  final bool isLast;

  const _FullInstructionTile({
    required this.instruction,
    required this.stepNumber,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isLast ? Colors.green : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isLast
                      ? const Icon(Icons.flag, color: Colors.white, size: 18)
                      : Text(
                          '$stepNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Instruction content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getManeuverIcon(instruction.maneuver),
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        instruction.distance,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  instruction.text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
      case 'turn-slight-left':
      case 'turn-sharp-left':
        return Icons.turn_left;
      case 'turn-right':
      case 'turn-slight-right':
      case 'turn-sharp-right':
        return Icons.turn_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_right;
      case 'roundabout':
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'merge':
        return Icons.merge;
      case 'ramp':
      case 'ramp-left':
      case 'ramp-right':
        return Icons.ramp_right;
      default:
        return Icons.straight;
    }
  }
}
