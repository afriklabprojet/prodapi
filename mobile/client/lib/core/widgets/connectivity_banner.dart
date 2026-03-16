import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';

/// Wrap autour de l'app pour afficher un bandeau hors-ligne persistant.
///
/// Usage dans MaterialApp.router :
/// ```dart
/// builder: (context, child) => ConnectivityBanner(child: child!),
/// ```
class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectivityProvider);

    return Column(
      children: [
        // Contenu principal (prend tout l'espace disponible)
        Expanded(child: child),

        // Bannière offline en bas (sous le contenu)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isConnected ? 0 : 36,
          color: Colors.red.shade700,
          width: double.infinity,
          child: isConnected
              ? const SizedBox.shrink()
              : const SafeArea(
                  top: false,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Pas de connexion Internet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
