import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple state notifier for boolean toggle states like password visibility.
/// This replaces setState(() => _obscurePassword = !_obscurePassword)
/// 
/// SECURITY NOTE: Default is FALSE (safe opt-in behavior).
/// For password fields, explicitly initialize with TRUE to obscure by default.
class ToggleNotifier extends StateNotifier<bool> {
  ToggleNotifier([super.initial = false]);

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

/// Provider factory for creating unique toggle providers
/// 
/// Usage examples:
/// - Password obscure (should be true): Initialize explicitly after first read
/// - Accept terms (should be false): Default behavior is correct
/// - Address default (should be false): Default behavior is correct
/// 
/// For password fields, call `.notifier.set(true)` on init:
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   Future.microtask(() => ref.read(toggleProvider(_obscurePasswordId).notifier).set(true));
/// }
/// ```
final toggleProvider = StateNotifierProvider.family<ToggleNotifier, bool, String>(
  (ref, id) => ToggleNotifier(false),
);

/// A state notifier for loading/submitting states
/// Tracks loading state with optional error message
class LoadingNotifier extends StateNotifier<LoadingState> {
  LoadingNotifier() : super(const LoadingState());

  void startLoading() => state = state.copyWith(isLoading: true, error: null);
  void stopLoading() => state = state.copyWith(isLoading: false);
  void setError(String error) => state = state.copyWith(isLoading: false, error: error);
  void clearError() => state = state.copyWith(error: null);
}

class LoadingState {
  final bool isLoading;
  final String? error;

  const LoadingState({
    this.isLoading = false,
    this.error,
  });

  LoadingState copyWith({bool? isLoading, String? error}) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for form loading states
/// Usage: ref.watch(loadingProvider('login_form'))
final loadingProvider = StateNotifierProvider.family<LoadingNotifier, LoadingState, String>(
  (ref, formId) => LoadingNotifier(),
);

/// Simple counter provider for things like OTP resend countdown
class CountdownNotifier extends StateNotifier<int> {
  CountdownNotifier([super.initial = 0]);

  void setValue(int value) => state = value;
  void decrement() {
    if (state > 0) state = state - 1;
  }
  void reset() => state = 0;
}

final countdownProvider = StateNotifierProvider.family<CountdownNotifier, int, String>(
  (ref, id) => CountdownNotifier(),
);

/// State notifier for form fields validation
class FormFieldsNotifier extends StateNotifier<Map<String, String?>> {
  FormFieldsNotifier() : super({});

  void setError(String field, String? error) {
    state = {...state, field: error};
  }

  void clearError(String field) {
    state = {...state, field: null};
  }

  void clearAll() {
    state = {};
  }

  /// Set a generic field value (can be used for any string value, not just errors)
  void setField(String field, String? value) {
    state = {...state, field: value};
  }

  String? getError(String field) => state[field];
  String? getValue(String field) => state[field];
}

final formFieldsProvider = StateNotifierProvider.family<FormFieldsNotifier, Map<String, String?>, String>(
  (ref, formId) => FormFieldsNotifier(),
);

/// Selected index provider for tab bars, page views, etc.
class SelectedIndexNotifier extends StateNotifier<int> {
  SelectedIndexNotifier([super.initial = 0]);

  void select(int index) => state = index;
}

final selectedIndexProvider = StateNotifierProvider.family<SelectedIndexNotifier, int, String>(
  (ref, id) => SelectedIndexNotifier(),
);

/// Page controller state for onboarding/walkthroughs
class PageIndexNotifier extends StateNotifier<int> {
  final int maxPages;
  
  PageIndexNotifier({required this.maxPages}) : super(0);

  void next() {
    if (state < maxPages - 1) state = state + 1;
  }

  void previous() {
    if (state > 0) state = state - 1;
  }

  void goTo(int index) {
    if (index >= 0 && index < maxPages) state = index;
  }

  bool get isFirstPage => state == 0;
  bool get isLastPage => state == maxPages - 1;
}
