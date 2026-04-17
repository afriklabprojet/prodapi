import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/courier_heatmap_opportunity.dart';
import '../../data/repositories/courier_heatmap_repository.dart';
import 'delivery_providers.dart';

class CourierHeatmapState {
  final List<CourierHeatmapOpportunity> opportunities;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  const CourierHeatmapState({
    this.opportunities = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  CourierHeatmapState copyWith({
    List<CourierHeatmapOpportunity>? opportunities,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) {
    return CourierHeatmapState(
      opportunities: opportunities ?? this.opportunities,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

final courierHeatmapProvider =
    NotifierProvider<CourierHeatmapNotifier, CourierHeatmapState>(
      CourierHeatmapNotifier.new,
    );

class CourierHeatmapNotifier extends Notifier<CourierHeatmapState> {
  Timer? _refreshTimer;

  @override
  CourierHeatmapState build() {
    ref.onDispose(() => _refreshTimer?.cancel());

    ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
      if (isOnline) {
        _startAutoRefresh();
        refresh();
      } else {
        _refreshTimer?.cancel();
        state = const CourierHeatmapState();
      }
    });

    if (ref.read(isOnlineProvider)) {
      _startAutoRefresh();
      Future.microtask(refresh);
    }

    return const CourierHeatmapState();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (ref.read(isOnlineProvider)) {
        refresh(silent: true);
      }
    });
  }

  Future<void> refresh({bool silent = false}) async {
    if (!ref.read(isOnlineProvider)) {
      state = const CourierHeatmapState();
      return;
    }

    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final repo = ref.read(courierHeatmapRepositoryProvider);
      final payload = await repo.getOpportunities();

      state = state.copyWith(
        opportunities: payload.opportunities,
        isLoading: false,
        error: null,
        lastUpdatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [HeatmapProvider] refresh: $e');
      }
      if (!silent) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }
}
