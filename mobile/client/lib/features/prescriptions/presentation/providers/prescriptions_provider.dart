import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../data/datasources/prescriptions_remote_datasource.dart';
import 'prescriptions_notifier.dart';
import 'prescriptions_state.dart';

final prescriptionsProvider =
    StateNotifierProvider<PrescriptionsNotifier, PrescriptionsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PrescriptionsNotifier(
    remoteDataSource: PrescriptionsRemoteDataSourceImpl(apiClient),
  );
});
