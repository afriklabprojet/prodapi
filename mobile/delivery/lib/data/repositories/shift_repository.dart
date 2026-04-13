import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';
import '../models/courier_shift.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepository(ref.read(dioProvider));
});

class ShiftRepository {
  final Dio _dio;

  ShiftRepository(this._dio);

  /// Récupère mes shifts (passés et à venir)
  Future<List<CourierShift>> getMyShifts() async {
    try {
      final response = await _dio.get(ApiConstants.shifts);
      final data = response.data['data'];
      if (data is! List) return [];
      return data.map((e) => CourierShift.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ShiftRepo] getMyShifts: $e');
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Récupère le shift actif (null si aucun)
  Future<CourierShift?> getActiveShift() async {
    try {
      final response = await _dio.get(ApiConstants.activeShift);
      final data = response.data['data'];
      if (data == null) return null;
      return CourierShift.fromJson(data);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ShiftRepo] getActiveShift: $e');
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Créneaux disponibles par zone, groupés par date
  Future<List<DaySlots>> getAvailableSlots({String? zoneId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.shiftSlots,
        queryParameters: zoneId != null ? {'zone_id': zoneId} : null,
      );
      final data = response.data['data'];
      if (data is! List) return [];
      return data.map((e) => DaySlots.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ShiftRepo] getAvailableSlots: $e');
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Réserver un créneau
  Future<CourierShift> bookSlot(int slotId) async {
    try {
      final response = await _dio.post(
        ApiConstants.bookShift,
        data: {'slot_id': slotId},
      );
      return CourierShift.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        throw Exception(
          'Conflit horaire : vous avez déjà un shift à ce créneau.',
        );
      }
      if (e is DioException && e.response?.statusCode == 422) {
        final msg = e.response?.data['message'] ?? 'Réservation impossible.';
        throw Exception(msg);
      }
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Annuler un shift
  Future<void> cancelShift(int shiftId, {String? reason}) async {
    try {
      await _dio.post(
        ApiConstants.cancelShift(shiftId),
        data: reason != null ? {'reason': reason} : null,
      );
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 422) {
        throw Exception(
          e.response?.data['message'] ??
              'Annulation impossible (trop proche du début).',
        );
      }
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Démarrer un shift
  Future<void> startShift(int shiftId) async {
    try {
      await _dio.post(ApiConstants.startShift(shiftId));
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data['message'] ?? 'Impossible de démarrer.';
        throw Exception(msg);
      }
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Terminer un shift
  Future<void> endShift(int shiftId) async {
    try {
      await _dio.post(ApiConstants.endShift(shiftId));
    } catch (e) {
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }
}
