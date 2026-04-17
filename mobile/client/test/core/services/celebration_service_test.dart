import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/core/services/celebration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late CelebrationNotifier notifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    notifier = CelebrationNotifier(prefs);
  });

  // ── _loadState (via constructor) ──────────────────────
  group('constructor / _loadState', () {
    test('initial state has zero orderCount and no badges', () {
      expect(notifier.state.totalOrderCount, 0);
      expect(notifier.state.unlockedBadges, isEmpty);
      expect(notifier.state.isShowing, false);
    });

    test('reloads persisted orderCount and badges', () async {
      SharedPreferences.setMockInitialValues({
        'celebration_order_count': 7,
        'celebration_badges': ['first_order', 'vip'],
      });
      final prefs2 = await SharedPreferences.getInstance();
      final notifier2 = CelebrationNotifier(prefs2);

      expect(notifier2.state.totalOrderCount, 7);
      expect(notifier2.state.unlockedBadges, {'first_order', 'vip'});
    });
  });

  // ── hasBadge ──────────────────────────────────────────
  group('hasBadge', () {
    test('returns false when badge not present', () {
      expect(notifier.hasBadge('first_order'), false);
    });

    test('returns true after badge is unlocked', () async {
      await notifier.triggerFirstRenewalCelebration();
      expect(notifier.hasBadge('first_renewal'), true);
    });
  });

  // ── dismissCelebration ────────────────────────────────
  group('dismissCelebration', () {
    test('clears currentCelebration and isShowing', () async {
      await notifier.triggerOrderCelebration(); // first order → shows
      expect(notifier.state.isShowing, true);

      notifier.dismissCelebration();

      expect(notifier.state.isShowing, false);
      expect(notifier.state.currentCelebration, isNull);
    });

    test('is idempotent when nothing is showing', () {
      notifier.dismissCelebration();
      expect(notifier.state.isShowing, false);
    });
  });

  // ── triggerOrderCelebration ───────────────────────────
  group('triggerOrderCelebration', () {
    test(
      'first order shows firstOrder celebration with confetti and badge',
      () async {
        await notifier.triggerOrderCelebration();

        expect(notifier.state.isShowing, true);
        expect(notifier.state.totalOrderCount, 1);
        expect(
          notifier.state.currentCelebration!.type,
          CelebrationType.firstOrder,
        );
        expect(notifier.state.currentCelebration!.showConfetti, true);
        expect(notifier.hasBadge('first_order'), true);
      },
    );

    test(
      'first order already shown → standard celebration on repeat',
      () async {
        await prefs.setBool('celebration_first_order_shown', true);
        await notifier.triggerOrderCelebration();

        expect(
          notifier.state.currentCelebration!.type,
          CelebrationType.orderConfirmed,
        );
        expect(notifier.state.currentCelebration!.showConfetti, false);
      },
    );

    test('5th order shows fifthOrder celebration', () async {
      for (int i = 0; i < 4; i++) {
        await notifier.triggerOrderCelebration();
        notifier.dismissCelebration();
      }
      await notifier.triggerOrderCelebration();

      expect(notifier.state.totalOrderCount, 5);
      expect(
        notifier.state.currentCelebration!.type,
        CelebrationType.fifthOrder,
      );
      expect(notifier.hasBadge('fifth_order'), true);
    });

    test('10th order shows tenthOrder celebration', () async {
      for (int i = 0; i < 9; i++) {
        await notifier.triggerOrderCelebration();
        notifier.dismissCelebration();
      }
      await notifier.triggerOrderCelebration();

      expect(notifier.state.totalOrderCount, 10);
      expect(
        notifier.state.currentCelebration!.type,
        CelebrationType.tenthOrder,
      );
      expect(notifier.hasBadge('vip'), true);
    });

    test('standard order shows orderConfirmed celebration', () async {
      await notifier.triggerOrderCelebration(); // 1st (already shown)
      await prefs.setBool('celebration_first_order_shown', true);
      notifier.dismissCelebration();

      await notifier.triggerOrderCelebration(); // 2nd → standard
      expect(
        notifier.state.currentCelebration!.type,
        CelebrationType.orderConfirmed,
      );
    });

    test('increments and persists order count', () async {
      await notifier.triggerOrderCelebration();
      expect(prefs.getInt('celebration_order_count'), 1);
    });
  });

  // ── triggerFirstRenewalCelebration ────────────────────
  group('triggerFirstRenewalCelebration', () {
    test('triggers renewal celebration on first call', () async {
      await notifier.triggerFirstRenewalCelebration();

      expect(notifier.state.isShowing, true);
      expect(
        notifier.state.currentCelebration!.type,
        CelebrationType.treatmentRenewal,
      );
      expect(notifier.hasBadge('first_renewal'), true);
    });

    test('does nothing if already shown', () async {
      await notifier.triggerFirstRenewalCelebration();
      notifier.dismissCelebration();

      await notifier.triggerFirstRenewalCelebration(); // should be no-op
      expect(notifier.state.isShowing, false);
    });
  });

  // ── triggerFirstWalletTopUp ───────────────────────────
  group('triggerFirstWalletTopUp', () {
    test('triggers wallet celebration on first call', () async {
      await notifier.triggerFirstWalletTopUp();

      expect(notifier.state.isShowing, true);
      expect(
        notifier.state.currentCelebration!.type,
        CelebrationType.walletTopUp,
      );
      expect(notifier.hasBadge('first_wallet'), true);
    });

    test('does nothing if already shown', () async {
      await notifier.triggerFirstWalletTopUp();
      notifier.dismissCelebration();

      await notifier.triggerFirstWalletTopUp();
      expect(notifier.state.isShowing, false);
    });
  });

  // ── triggerFirstPrescriptionScan ──────────────────────
  group('triggerFirstPrescriptionScan', () {
    test('triggers scan celebration on first call', () async {
      await notifier.triggerFirstPrescriptionScan();

      expect(notifier.state.isShowing, true);
      expect(
        notifier.state.currentCelebration!.type,
        CelebrationType.prescriptionScanned,
      );
      expect(notifier.hasBadge('first_scan'), true);
    });

    test('does nothing if already shown', () async {
      await notifier.triggerFirstPrescriptionScan();
      notifier.dismissCelebration();

      await notifier.triggerFirstPrescriptionScan();
      expect(notifier.state.isShowing, false);
    });
  });
}
