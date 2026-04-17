import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/courier_shift.dart';
import '../../data/repositories/shift_repository.dart';

part 'shift_provider.freezed.dart';

// ─── State ───

@freezed
abstract class ShiftState with _$ShiftState {
  const factory ShiftState({
    @Default([]) List<CourierShift> myShifts,
    @Default([]) List<DaySlots> availableSlots,
    CourierShift? activeShift,
    @Default(false) bool isLoading,
    @Default(false) bool isSlotsLoading,
    @Default(false) bool isBooking,
    String? error,
    int? bookingSlotId,
  }) = _ShiftState;
}

// ─── Provider ───

final shiftProvider = NotifierProvider<ShiftNotifier, ShiftState>(
  ShiftNotifier.new,
);

class ShiftNotifier extends Notifier<ShiftState> {
  @override
  ShiftState build() {
    // Charger au démarrage
    Future.microtask(() => loadAll());
    return const ShiftState();
  }

  ShiftRepository get _repo => ref.read(shiftRepositoryProvider);

  /// Charge shifts + shift actif
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.getMyShifts(),
        _repo.getActiveShift(),
      ]);
      state = state.copyWith(
        myShifts: results[0] as List<CourierShift>,
        activeShift: results[1] as CourierShift?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Charge les créneaux disponibles
  Future<void> loadAvailableSlots({String? zoneId}) async {
    state = state.copyWith(isSlotsLoading: true, error: null);
    try {
      final slots = await _repo.getAvailableSlots(zoneId: zoneId);
      state = state.copyWith(availableSlots: slots, isSlotsLoading: false);
    } catch (e) {
      state = state.copyWith(isSlotsLoading: false, error: e.toString());
    }
  }

  /// Réserver un créneau
  Future<bool> bookSlot(int slotId) async {
    state = state.copyWith(isBooking: true, bookingSlotId: slotId, error: null);
    try {
      final shift = await _repo.bookSlot(slotId);
      state = state.copyWith(
        isBooking: false,
        bookingSlotId: null,
        myShifts: [...state.myShifts, shift],
      );
      // Rafraîchir les slots (le compteur a changé)
      loadAvailableSlots();
      return true;
    } catch (e) {
      state = state.copyWith(
        isBooking: false,
        bookingSlotId: null,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Annuler un shift
  Future<bool> cancelShift(int shiftId, {String? reason}) async {
    state = state.copyWith(error: null);
    try {
      await _repo.cancelShift(shiftId, reason: reason);
      state = state.copyWith(
        myShifts: state.myShifts.where((s) => s.id != shiftId).toList(),
        activeShift: state.activeShift?.id == shiftId
            ? null
            : state.activeShift,
      );
      loadAvailableSlots();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Démarrer un shift
  Future<bool> startShift(int shiftId) async {
    state = state.copyWith(error: null);
    try {
      await _repo.startShift(shiftId);
      await loadAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Terminer un shift
  Future<bool> endShift(int shiftId) async {
    state = state.copyWith(error: null);
    try {
      await _repo.endShift(shiftId);
      await loadAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ─── Providers dérivés ───

/// Shifts à venir uniquement (confirmés + en cours)
final upcomingShiftsProvider = Provider<List<CourierShift>>((ref) {
  final shifts = ref.watch(shiftProvider).myShifts;
  final now = DateTime.now();
  return shifts.where((s) {
    if (!ShiftStatus.isActive(s.status)) return false;
    try {
      final dt = DateTime.parse(s.date);
      return dt.isAfter(now.subtract(const Duration(days: 1)));
    } catch (_) {
      return true;
    }
  }).toList();
});

/// Nombre de shifts à venir (pour badge)
final upcomingShiftCountProvider = Provider<int>((ref) {
  return ref.watch(upcomingShiftsProvider).length;
});

/// Shift actif
final activeShiftProvider = Provider<CourierShift?>((ref) {
  return ref.watch(shiftProvider).activeShift;
});
