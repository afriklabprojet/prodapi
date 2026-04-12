import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/api_client.dart';

/// Résultat de la vérification de version.
class VersionCheckResult {
  final bool forceUpdate;
  final bool updateAvailable;
  final String minVersion;
  final String latestVersion;
  final String currentVersion;
  final String storeUrl;
  final String? changelog;

  VersionCheckResult({
    required this.forceUpdate,
    required this.updateAvailable,
    required this.minVersion,
    required this.latestVersion,
    required this.currentVersion,
    required this.storeUrl,
    this.changelog,
  });

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) {
    return VersionCheckResult(
      forceUpdate: json['force_update'] ?? false,
      updateAvailable: json['update_available'] ?? false,
      minVersion: json['min_version'] ?? '1.0.0',
      latestVersion: json['latest_version'] ?? '1.0.0',
      currentVersion: json['current_version'] ?? '1.0.0',
      storeUrl: json['store_url'] ?? '',
      changelog: json['changelog'],
    );
  }
}

/// Provider pour la vérification de version.
final appUpdateProvider = FutureProvider<VersionCheckResult?>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final platform = Platform.isAndroid ? 'android' : 'ios';

    final response = await dio.get('/app/version-check', queryParameters: {
      'app': 'delivery',
      'version': packageInfo.version,
      'platform': platform,
    });

    if (response.data['success'] == true) {
      return VersionCheckResult.fromJson(response.data['data']);
    }
  } on DioException {
    // Silencieux - ne pas bloquer si le serveur est injoignable  
  }
  return null;
});

/// Provider pour les feature flags.
final featureFlagsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/app/features', queryParameters: {
      'app': 'delivery',
    });

    if (response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    }
  } on DioException {
    // Retourner les valeurs par défaut si offline
  }
  return {};
});

/// Helper pour vérifier si un feature flag est actif.
bool isFeatureEnabled(Map<String, dynamic> flags, String feature, {bool defaultValue = true}) {
  return flags[feature] as bool? ?? defaultValue;
}

/// Widget qui affiche un dialogue de mise à jour forcée.
/// Bloque l'utilisation de l'app tant que la mise à jour n'est pas faite.
class ForceUpdateDialog extends StatelessWidget {
  final VersionCheckResult result;

  const ForceUpdateDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Mise à jour requise'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.changelog ?? 'Une mise à jour critique est disponible.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Text(
              'Version actuelle: ${result.currentVersion}\nVersion requise: ${result.minVersion}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openStore(),
            icon: const Icon(Icons.download),
            label: const Text('Mettre à jour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStore() async {
    if (result.storeUrl.isNotEmpty) {
      final uri = Uri.parse(result.storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

/// Widget optionnel pour afficher un bandeau de mise à jour disponible (non-bloquant).
class UpdateAvailableBanner extends StatelessWidget {
  final VersionCheckResult result;
  final VoidCallback? onDismiss;

  const UpdateAvailableBanner({super.key, required this.result, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(
        'Nouvelle version ${result.latestVersion} disponible',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      leading: const Icon(Icons.info_outline, color: Colors.blue),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Plus tard'),
        ),
        TextButton(
          onPressed: () async {
            if (result.storeUrl.isNotEmpty) {
              final uri = Uri.parse(result.storeUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: const Text('Mettre à jour'),
        ),
      ],
    );
  }
}
