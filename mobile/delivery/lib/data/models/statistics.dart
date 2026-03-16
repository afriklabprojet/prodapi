import 'package:freezed_annotation/freezed_annotation.dart';

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
    @JsonKey(name: 'total_deliveries') @Default(0) int totalDeliveries,
    @JsonKey(name: 'total_earnings') @Default(0.0) double totalEarnings,
    @JsonKey(name: 'total_distance_km') @Default(0.0) double totalDistanceKm,
    @JsonKey(name: 'total_duration_minutes') @Default(0) int totalDurationMinutes,
    @JsonKey(name: 'average_rating') @Default(0.0) double averageRating,
    @JsonKey(name: 'delivery_trend') @Default(0.0) double deliveryTrend,
    @JsonKey(name: 'earnings_trend') @Default(0.0) double earningsTrend,
    @Default('FCFA') String currency,
  }) = _StatsOverview;

  factory StatsOverview.fromJson(Map<String, dynamic> json) =>
      _$StatsOverviewFromJson(json);
}

@freezed
abstract class StatsPerformance with _$StatsPerformance {
  const factory StatsPerformance({
    @JsonKey(name: 'total_assigned') @Default(0) int totalAssigned,
    @JsonKey(name: 'total_accepted') @Default(0) int totalAccepted,
    @JsonKey(name: 'total_delivered') @Default(0) int totalDelivered,
    @JsonKey(name: 'total_cancelled') @Default(0) int totalCancelled,
    @JsonKey(name: 'acceptance_rate') @Default(0.0) double acceptanceRate,
    @JsonKey(name: 'completion_rate') @Default(0.0) double completionRate,
    @JsonKey(name: 'cancellation_rate') @Default(0.0) double cancellationRate,
    @JsonKey(name: 'on_time_rate') @Default(0.0) double onTimeRate,
    @JsonKey(name: 'satisfaction_rate') @Default(0.0) double satisfactionRate,
  }) = _StatsPerformance;

  factory StatsPerformance.fromJson(Map<String, dynamic> json) =>
      _$StatsPerformanceFromJson(json);
}

@freezed
abstract class DailyStats with _$DailyStats {
  const factory DailyStats({
    required String date,
    @JsonKey(name: 'day_name') required String dayName,
    @Default(0) int deliveries,
    @Default(0.0) double earnings,
  }) = _DailyStats;

  factory DailyStats.fromJson(Map<String, dynamic> json) =>
      _$DailyStatsFromJson(json);
}

@freezed
abstract class PeakHour with _$PeakHour {
  const factory PeakHour({
    required String hour,
    required String label,
    @Default(0) int count,
    @Default(0.0) double percentage,
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
          (json['delivery_commissions']?['amount'] as num?)?.toDouble() ?? 0.0,
      deliveryCommissionsPercent:
          (json['delivery_commissions']?['percentage'] as num?)?.toDouble() ?? 0.0,
      challengeBonusesAmount:
          (json['challenge_bonuses']?['amount'] as num?)?.toDouble() ?? 0.0,
      challengeBonusesPercent:
          (json['challenge_bonuses']?['percentage'] as num?)?.toDouble() ?? 0.0,
      rushBonusesAmount:
          (json['rush_bonuses']?['amount'] as num?)?.toDouble() ?? 0.0,
      rushBonusesPercent:
          (json['rush_bonuses']?['percentage'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
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
    @JsonKey(name: 'weekly_target') @Default(0) int weeklyTarget,
    @JsonKey(name: 'current_progress') @Default(0) int currentProgress,
    @JsonKey(name: 'progress_percentage') @Default(0.0) double progressPercentage,
    @Default(0) int remaining,
  }) = _StatsGoals;

  factory StatsGoals.fromJson(Map<String, dynamic> json) =>
      _$StatsGoalsFromJson(json);
}
