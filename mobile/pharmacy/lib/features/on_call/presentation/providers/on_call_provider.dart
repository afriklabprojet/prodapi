import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/on_call_model.dart';
import '../../data/repositories/on_call_repository.dart';

// State to hold the list of on-calls
class OnCallState {
  final bool isLoading;
  final List<OnCallModel> onCalls;
  final String? error;

  OnCallState({
    this.isLoading = false,
    this.onCalls = const [],
    this.error,
  });

  OnCallState copyWith({
    bool? isLoading,
    List<OnCallModel>? onCalls,
    String? error,
  }) {
    return OnCallState(
      isLoading: isLoading ?? this.isLoading,
      onCalls: onCalls ?? this.onCalls,
      error: error,
    );
  }
}

class OnCallNotifier extends StateNotifier<OnCallState> {
  final OnCallRepository _repository;

  OnCallNotifier(this._repository) : super(OnCallState()) {
    getOnCalls();
  }

  Future<void> getOnCalls() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getOnCalls();
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (onCalls) => state = state.copyWith(isLoading: false, onCalls: onCalls),
    );
  }

  Future<bool> createOnCall(DateTime startAt, DateTime endAt, String type) async {
    state = state.copyWith(isLoading: true, error: null);

    // Format as 'yyyy-MM-dd HH:mm:ss' — compatible with Laravel Carbon parsing
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    final data = {
      'start_at': fmt.format(startAt),
      'end_at': fmt.format(endAt),
      'type': type,
    };

    final result = await _repository.createOnCall(data);
    
    bool success = false;
    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        success = false;
      },
      (newOnCall) {
        // Optimistically add to list or refresh
        state = state.copyWith(
          isLoading: false, 
          onCalls: [newOnCall, ...state.onCalls],
        );
        success = true;
      },
    );
    return success;
  }

  Future<bool> deleteOnCall(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.deleteOnCall(id);

    bool success = false;
    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        success = false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          onCalls: state.onCalls.where((c) => c.id != id).toList(),
        );
        success = true;
      },
    );
    return success;
  }
}

final onCallProvider = StateNotifierProvider<OnCallNotifier, OnCallState>((ref) {
  final repository = ref.watch(onCallRepositoryProvider);
  return OnCallNotifier(repository);
});
