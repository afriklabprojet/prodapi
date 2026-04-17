import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wallet_data.dart';
import '../../data/repositories/wallet_repository.dart';

/// Provider principal pour les données du wallet (lance une exception si erreur)
final walletProvider = FutureProvider.autoDispose<WalletData>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWalletData();
});

/// Provider pour les données du wallet avec gestion d'erreur silencieuse
/// Retourne null en cas d'erreur réseau, mais propage les autres erreurs
final walletDataProvider = FutureProvider.autoDispose<WalletData?>((ref) async {
  try {
    return await ref.read(walletRepositoryProvider).getWalletData();
  } on Exception catch (e) {
    // Erreurs réseau → null silencieux (l'UI affiche 0 plutôt qu'un crash)
    if (e.toString().contains('connexion') || e.toString().contains('timeout') || e.toString().contains('internet')) {
      return null;
    }
    // Erreurs métier (403, 401) → propager pour que l'UI puisse réagir
    rethrow;
  }
});
