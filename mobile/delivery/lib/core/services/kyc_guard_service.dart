import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../presentation/providers/delivery_providers.dart';
import '../../presentation/providers/profile_provider.dart';
import '../router/route_names.dart';

// ============================================================================
// KYC Status Enum
// ============================================================================

/// Statuts KYC possibles retournés par l'API.
enum KycStatus {
  verified,
  incomplete,
  pendingReview,
  rejected,
  unknown;

  factory KycStatus.fromString(String value) {
    final normalized = value.trim().toLowerCase();

    switch (normalized) {
      case 'verified':
      case 'approved':
      case 'valid':
      case 'validated':
      case 'active':
      case 'complete':
      case 'completed':
      case 'done':
        return KycStatus.verified;
      case 'incomplete':
      case 'not_submitted':
        return KycStatus.incomplete;
      case 'pending_review':
      case 'pending':
      case 'under_review':
      case 'in_review':
      case 'submitted':
        return KycStatus.pendingReview;
      case 'rejected':
      case 'refused':
      case 'denied':
        return KycStatus.rejected;
      default:
        return KycStatus.unknown;
    }
  }

  bool get isVerified => this == KycStatus.verified;

  bool get canReceiveOrders => this == KycStatus.verified;

  String get label {
    switch (this) {
      case KycStatus.verified:
        return 'Vérifié';
      case KycStatus.incomplete:
        return 'Documents manquants';
      case KycStatus.pendingReview:
        return 'En cours de vérification';
      case KycStatus.rejected:
        return 'Documents refusés';
      case KycStatus.unknown:
        return 'Non vérifié';
    }
  }
}

// ============================================================================
// KYC Providers
// ============================================================================

KycStatus _statusFromRaw(String? rawStatus) {
  if (rawStatus == null || rawStatus.trim().isEmpty) {
    return KycStatus.unknown;
  }
  return KycStatus.fromString(rawStatus);
}

/// Statut KYC dérivé en priorité du profil coursier, avec fallback sur
/// le profil auth mis en cache pour éviter les faux blocages réseau.
final kycStatusProvider = Provider<KycStatus>((ref) {
  final courierProfileAsync = ref.watch(courierProfileProvider);
  final authProfileAsync = ref.watch(profileProvider);

  final courierStatus = courierProfileAsync.maybeWhen(
    data: (profile) => _statusFromRaw(profile.kycStatus),
    orElse: () => KycStatus.unknown,
  );

  if (courierStatus != KycStatus.unknown) {
    final rawStatus = courierProfileAsync.asData?.value.kycStatus ?? 'unknown';
    debugPrint(
      '🔍 [KYC] source=courierProfile brut="$rawStatus" → $courierStatus',
    );
    return courierStatus;
  }

  final authStatus = authProfileAsync.maybeWhen(
    data: (user) => _statusFromRaw(user.courier?.kycStatus),
    orElse: () => KycStatus.unknown,
  );

  if (authStatus != KycStatus.unknown) {
    final rawStatus =
        authProfileAsync.asData?.value.courier?.kycStatus ?? 'unknown';
    debugPrint('🔍 [KYC] source=authProfile brut="$rawStatus" → $authStatus');
    return authStatus;
  }

  debugPrint('🔍 [KYC] statut indisponible → KycStatus.unknown');
  return KycStatus.unknown;
});

/// Raccourci : le coursier peut-il recevoir des commandes ?
final canReceiveOrdersProvider = Provider<bool>((ref) {
  return ref.watch(kycStatusProvider).canReceiveOrders;
});

// ============================================================================
// KYC Guard — helper pour bloquer les actions sensibles
// ============================================================================

class KycGuard {
  KycGuard._();

  /// Vérifie le KYC avant d'exécuter [action].
  /// Si le KYC n'est pas vérifié, affiche un bottom sheet d'avertissement
  /// et retourne false. Sinon exécute l'action et retourne true.
  static bool check(
    BuildContext context,
    WidgetRef ref, {
    VoidCallback? action,
  }) {
    final status = ref.read(kycStatusProvider);
    if (status.canReceiveOrders) {
      action?.call();
      return true;
    }

    if (status == KycStatus.unknown) {
      _showUnknownStatusMessage(context);
      return false;
    }

    _showKycBlockedSheet(context, status);
    return false;
  }

  /// Force un refresh des profils puis vérifie le KYC.
  static Future<bool> ensureVerified(
    BuildContext context,
    WidgetRef ref,
  ) async {
    ref.invalidate(courierProfileProvider);
    ref.invalidate(profileProvider);

    try {
      await Future.wait([
        ref.read(courierProfileProvider.future),
        ref.read(profileProvider.future),
      ]);
    } catch (_) {
      // Un fallback cache/auth peut quand même permettre la vérification.
    }

    if (!context.mounted) return false;
    return check(context, ref);
  }

  static void _showUnknownStatusMessage(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Impossible de vérifier votre statut pour le moment. Vérifiez votre connexion puis réessayez.',
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Bottom sheet affiché quand une action est bloquée par le KYC.
  static void _showKycBlockedSheet(BuildContext context, KycStatus status) {
    const green = Color(0xFF0D6644);
    final isRejected = status == KycStatus.rejected;
    final isPending = status == KycStatus.pendingReview;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isPending ? Colors.orange : Colors.red).withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending
                    ? Icons.hourglass_top_rounded
                    : Icons.verified_user_outlined,
                size: 32,
                color: isPending ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'Vérification en cours' : 'Vérification requise',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F1F18),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Vos documents sont en cours de vérification. '
                        'Vous pourrez recevoir des commandes une fois la validation terminée.'
                  : isRejected
                  ? 'Vos documents ont été refusés. '
                        'Veuillez les soumettre à nouveau pour pouvoir recevoir des commandes.'
                  : 'Vous devez compléter la vérification de votre identité '
                        'avant de pouvoir recevoir des commandes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF7A9E87),
              ),
            ),
            const SizedBox(height: 20),
            // Actions
            if (!isPending)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.kycResubmission);
                  },
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text(
                    'Soumettre mes documents',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            if (isPending) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: BorderSide(color: green.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Compris',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
