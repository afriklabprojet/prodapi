import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/safe_json.dart';

part 'statistics.freezed.dart';
part 'statistics.g.dart';

@freezed
abstract class Statistics with _$Statistics {
  const factory Statistics({
    required String period,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    required StatsOverview overview,
    required StatsPerformance performance,
    @JsonKey(name: 'daily_breakdown') @Default([]) List<DailyStats> dailyBreakdown,
    @JsonKey(name: 'peak_hours') @Default([]) List<PeakHour> peakHours,
    @JsonKey(name: 'revenue_breakdown') RevenueBreakdown? revenueBreakdown,
    StatsGoals? goals,
  }) = _Statistics;

  factory Statistics.fromJson(Map<String, dynamic> json) =>
      _$StatisticsFromJson(json);
}

@freezed
abstract class StatsOverview with _$StatsOverview {
  const factory StatsOverview({
    @JsonKey(name: 'total_deliveries', fromJson: safeInt) @Default(0) int totalDeliveries,
    @JsonKey(name: 'total_earnings', fromJson: safeDouble) @Default(0.0) double totalEarnings,
    @JsonKey(name: 'total_distance_km', fromJson: safeDouble) @Default(0.0) double totalDistanceKm,
    @JsonKey(name: 'total_duration_minutes', fromJson: safeInt) @Default(0) int totalDurationMinutes,
    @JsonKey(name: 'average_rating', fromJson: safeDouble) @Default(0.0) double averageRating,
    @JsonKey(name: 'delivery_trend', fromJson: safeDouble) @Default(0.0) double deliveryTrend,
    @JsonKey(name: 'earnings_trend', fromJson: safeDouble) @Default(0.0) double earningsTrend,
    @Default('FCFA') String currency,
  }) = _StatsOverview;

  factory StatsOverview.fromJson(Map<String, dynamic> json) =>
      _$StatsOverviewFromJson(json);
}

@freezed
abstract class StatsPerformance with _$StatsPerformance {
  const factory StatsPerformance({
    @JsonKey(name: 'total_assigned', fromJson: safeInt) @Default(0) int totalAssigned,
    @JsonKey(name: 'total_accepted', fromJson: safeInt) @Default(0) int totalAccepted,
    @JsonKey(name: 'total_delivered', fromJson: safeInt) @Default(0) int totalDelivered,
    @JsonKey(name: 'total_cancelled', fromJson: safeInt) @Default(0) int totalCancelled,
    @JsonKey(name: 'acceptance_rate', fromJson: safeDouble) @Default(0.0) double acceptanceRate,
    @JsonKey(name: 'completion_rate', fromJson: safeDouble) @Default(0.0) double completionRate,
    @JsonKey(name: 'cancellation_rate', fromJson: safeDouble) @Default(0.0) double cancellationRate,
    @JsonKey(name: 'on_time_rate', fromJson: safeDouble) @Default(0.0) double onTimeRate,
    @JsonKey(name: 'satisfaction_rate', fromJson: safeDouble) @Default(0.0) double satisfactionRate,
  }) = _StatsPerformance;

  factory StatsPerformance.fromJson(Map<String, dynamic> json) =>
      _$StatsPerformanceFromJson(json);
}

@freezed
abstract class DailyStats with _$DailyStats {
  const factory DailyStats({
    required String date,
    @JsonKey(name: 'day_name') required String dayName,
    @JsonKey(fromJson: safeInt) @Default(0) int deliveries,
    @JsonKey(fromJson: safeDouble) @Default(0.0) double earnings,
  }) = _DailyStats;

  factory DailyStats.fromJson(Map<String, dynamic> json) =>
      _$DailyStatsFromJson(json);
}

@freezed
abstract class PeakHour with _$PeakHour {
  const factory PeakHour({
    required String hour,
    required String label,
    @JsonKey(fromJson: safeInt) @Default(0) int count,
    @JsonKey(fromJson: safeDouble) @Default(0.0) double percentage,
  }) = _PeakHour;

  factory PeakHour.fromJson(Map<String, dynamic> json) =>
      _$PeakHourFromJson(json);
}

@freezed
abstract class RevenueBreakdown with _$RevenueBreakdown {
  const RevenueBreakdown._();

  const factory RevenueBreakdown({
    @Default(0.0) double deliveryCommissionsAmount,
    @Default(0.0) double deliveryCommissionsPercent,
    @Default(0.0) double challengeBonusesAmount,
    @Default(0.0) double challengeBonusesPercent,
    @Default(0.0) double rushBonusesAmount,
    @Default(0.0) double rushBonusesPercent,
    @Default(0.0) double total,
  }) = _RevenueBreakdown;

  factory RevenueBreakdown.fromJson(Map<String, dynamic> json) {
    return RevenueBreakdown(
      deliveryCommissionsAmount:
          safeDouble(json['delivery_commissions']?['amount']),
      deliveryCommissionsPercent:
          safeDouble(json['delivery_commissions']?['percentage']),
      challengeBonusesAmount:
          safeDouble(json['challenge_bonuses']?['amount']),
      challengeBonusesPercent:
          safeDouble(json['challenge_bonuses']?['percentage']),
      rushBonusesAmount:
          safeDouble(json['rush_bonuses']?['amount']),
      rushBonusesPercent:
          safeDouble(json['rush_bonuses']?['percentage']),
      total: safeDouble(json['total']),
    );
  }

  Map<String, dynamic> toJson() => {
        'delivery_commissions': {
          'amount': deliveryCommissionsAmount,
          'percentage': deliveryCommissionsPercent,
        },
        'challenge_bonuses': {
          'amount': challengeBonusesAmount,
          'percentage': challengeBonusesPercent,
        },
        'rush_bonuses': {
          'amount': rushBonusesAmount,
          'percentage': rushBonusesPercent,
        },
        'total': total,
      };
}

@freezed
abstract class StatsGoals with _$StatsGoals {
  const factory StatsGoals({
    @JsonKey(name: 'weekly_target', fromJson: safeInt) @Default(0) int weeklyTarget,
    @JsonKey(name: 'current_progress', fromJson: safeInt) @Default(0) int currentProgress,
    @JsonKey(name: 'progress_percentage', fromJson: safeDouble) @Default(0.0) double progressPercentage,
    @JsonKey(fromJson: safeInt) @Default(0) int remaining,
  }) = _StatsGoals;

  factory StatsGoals.fromJson(Map<String, dynamic> json) =>
      _$StatsGoalsFromJson(json);
}
