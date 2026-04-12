import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../data/datasources/cart_local_datasource.dart';
import 'cart_notifier.dart';
import 'cart_state.dart';

final cartLocalDataSourceProvider = Provider<CartLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CartLocalDataSourceImpl(sharedPreferences: prefs);
});

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final dataSource = ref.watch(cartLocalDataSourceProvider);
  return CartNotifier(dataSource);
});
