import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/statistics.dart';
import '../../data/repositories/statistics_repository.dart';

final statisticsProvider = FutureProvider.family<Statistics, String>((ref, period) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.getStatistics(period: period);
});
