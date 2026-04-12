import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/providers.dart';

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
  final apiClient = ref.read(apiClientProvider);
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final platform = Platform.isAndroid ? 'android' : 'ios';

    final response = await apiClient.get(
      '/app/version-check?app=client&version=${packageInfo.version}&platform=$platform',
    );

    if (response.data['success'] == true) {
      return VersionCheckResult.fromJson(response.data['data']);
    }
  } catch (_) {
    // Silencieux - ne pas bloquer si le serveur est injoignable
  }
  return null;
});

/// Provider pour les feature flags.
final featureFlagsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  try {
    final response = await apiClient.get('/app/features?app=client');

    if (response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    }
  } catch (_) {
    // Retourner les valeurs par défaut si offline
  }
  return {};
});

/// Helper pour vérifier si un feature flag est actif.
bool isFeatureEnabled(
  Map<String, dynamic> flags,
  String feature, {
  bool defaultValue = true,
}) {
  return flags[feature] as bool? ?? defaultValue;
}

/// Widget bloquant de mise à jour forcée.
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
            onPressed: () async {
              if (result.storeUrl.isNotEmpty) {
                final uri = Uri.parse(result.storeUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
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
}
