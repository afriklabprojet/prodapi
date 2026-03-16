import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wallet_data.dart';
import '../../data/repositories/wallet_repository.dart';

final walletProvider = FutureProvider.autoDispose<WalletData>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWalletData();
});
