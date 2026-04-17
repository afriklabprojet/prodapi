import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/core/providers/ui_state_providers.dart';

void main() {
  // ── ToggleNotifier ───────────────────────────────────
  group('ToggleNotifier', () {
    test('initial state is false by default', () {
      final n = ToggleNotifier();
      expect(n.state, false);
    });

    test('initial state can be set to true', () {
      final n = ToggleNotifier(true);
      expect(n.state, true);
    });

    test('toggle flips false to true', () {
      final n = ToggleNotifier();
      n.toggle();
      expect(n.state, true);
    });

    test('toggle flips true to false', () {
      final n = ToggleNotifier(true);
      n.toggle();
      expect(n.state, false);
    });

    test('set explicitly sets value', () {
      final n = ToggleNotifier();
      n.set(true);
      expect(n.state, true);
      n.set(false);
      expect(n.state, false);
    });
  });

  // ── LoadingNotifier ───────────────────────────────────
  group('LoadingNotifier', () {
    test('initial state is not loading, no error', () {
      final n = LoadingNotifier();
      expect(n.state.isLoading, false);
      expect(n.state.error, isNull);
    });

    test('startLoading sets isLoading true and clears error', () {
      final n = LoadingNotifier();
      n.setError('previous error');
      n.startLoading();
      expect(n.state.isLoading, true);
      expect(n.state.error, isNull);
    });

    test('stopLoading sets isLoading false', () {
      final n = LoadingNotifier();
      n.startLoading();
      n.stopLoading();
      expect(n.state.isLoading, false);
    });

    test('setError sets error message and stops loading', () {
      final n = LoadingNotifier();
      n.startLoading();
      n.setError('Something failed');
      expect(n.state.isLoading, false);
      expect(n.state.error, 'Something failed');
    });

    test('clearError removes error message', () {
      final n = LoadingNotifier();
      n.setError('Error');
      n.clearError();
      expect(n.state.error, isNull);
    });
  });

  // ── LoadingState ──────────────────────────────────────
  group('LoadingState.copyWith', () {
    test('copyWith with no args clears error (current behavior)', () {
      const s = LoadingState(isLoading: true, error: 'err');
      final s2 = s.copyWith();
      expect(s2.isLoading, true); // preserved
      expect(
        s2.error,
        isNull,
      ); // not preserved — copyWith(error: null) by default
    });

    test('copyWith overrides individual fields', () {
      const s = LoadingState(isLoading: false, error: null);
      final s2 = s.copyWith(isLoading: true, error: 'new error');
      expect(s2.isLoading, true);
      expect(s2.error, 'new error');
    });
  });

  // ── CountdownNotifier ────────────────────────────────
  group('CountdownNotifier', () {
    test('initial state is 0 by default', () {
      final n = CountdownNotifier();
      expect(n.state, 0);
    });

    test('setValue sets the count', () {
      final n = CountdownNotifier();
      n.setValue(30);
      expect(n.state, 30);
    });

    test('decrement decreases by 1', () {
      final n = CountdownNotifier(10);
      n.decrement();
      expect(n.state, 9);
    });

    test('decrement does not go below 0', () {
      final n = CountdownNotifier();
      n.decrement();
      expect(n.state, 0);
    });

    test('reset sets count to 0', () {
      final n = CountdownNotifier(15);
      n.reset();
      expect(n.state, 0);
    });
  });

  // ── FormFieldsNotifier ───────────────────────────────
  group('FormFieldsNotifier', () {
    test('initial state is empty map', () {
      final n = FormFieldsNotifier();
      expect(n.state, isEmpty);
    });

    test('setError stores error for field', () {
      final n = FormFieldsNotifier();
      n.setError('email', 'Email invalide');
      expect(n.getError('email'), 'Email invalide');
    });

    test('clearError clears specific field', () {
      final n = FormFieldsNotifier();
      n.setError('email', 'Error');
      n.clearError('email');
      expect(n.getError('email'), isNull);
    });

    test('clearAll removes all fields', () {
      final n = FormFieldsNotifier();
      n.setError('email', 'Error 1');
      n.setError('password', 'Error 2');
      n.clearAll();
      expect(n.state, isEmpty);
    });

    test('setField stores a generic value', () {
      final n = FormFieldsNotifier();
      n.setField('name', 'Alice');
      expect(n.getValue('name'), 'Alice');
    });

    test('getValue returns null for unknown field', () {
      final n = FormFieldsNotifier();
      expect(n.getValue('unknown'), isNull);
    });
  });

  // ── SelectedIndexNotifier ─────────────────────────────
  group('SelectedIndexNotifier', () {
    test('initial state is 0', () {
      final n = SelectedIndexNotifier();
      expect(n.state, 0);
    });

    test('select sets the index', () {
      final n = SelectedIndexNotifier();
      n.select(3);
      expect(n.state, 3);
    });
  });

  // ── PageIndexNotifier ────────────────────────────────
  group('PageIndexNotifier', () {
    test('initial state is 0', () {
      final n = PageIndexNotifier(maxPages: 5);
      expect(n.state, 0);
    });

    test('next increments index', () {
      final n = PageIndexNotifier(maxPages: 5);
      n.next();
      expect(n.state, 1);
    });

    test('next does not go past maxPages-1', () {
      final n = PageIndexNotifier(maxPages: 3);
      n.next();
      n.next();
      n.next(); // tries to go past 2
      expect(n.state, 2);
    });

    test('previous decrements index', () {
      final n = PageIndexNotifier(maxPages: 5);
      n.goTo(3);
      n.previous();
      expect(n.state, 2);
    });

    test('previous does not go below 0', () {
      final n = PageIndexNotifier(maxPages: 5);
      n.previous();
      expect(n.state, 0);
    });

    test('goTo sets the index within bounds', () {
      final n = PageIndexNotifier(maxPages: 5);
      n.goTo(4);
      expect(n.state, 4);
    });

    test('goTo ignores index out of bounds', () {
      final n = PageIndexNotifier(maxPages: 3);
      n.goTo(10);
      expect(n.state, 0); // unchanged
      n.goTo(-1);
      expect(n.state, 0); // unchanged
    });

    test('isFirstPage true at index 0', () {
      final n = PageIndexNotifier(maxPages: 5);
      expect(n.isFirstPage, true);
    });

    test('isLastPage true at maxPages-1', () {
      final n = PageIndexNotifier(maxPages: 3);
      n.goTo(2);
      expect(n.isLastPage, true);
    });

    test('isFirstPage false after next', () {
      final n = PageIndexNotifier(maxPages: 5);
      n.next();
      expect(n.isFirstPage, false);
    });
  });
}
