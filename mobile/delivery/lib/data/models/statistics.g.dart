// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Statistics _$StatisticsFromJson(Map<String, dynamic> json) => _Statistics(
  period: json['period'] as String,
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String,
  overview: StatsOverview.fromJson(json['overview'] as Map<String, dynamic>),
  performance: StatsPerformance.fromJson(
    json['performance'] as Map<String, dynamic>,
  ),
  dailyBreakdown:
      (json['daily_breakdown'] as List<dynamic>?)
          ?.map((e) => DailyStats.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  peakHours:
      (json['peak_hours'] as List<dynamic>?)
          ?.map((e) => PeakHour.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  revenueBreakdown: json['revenue_breakdown'] == null
      ? null
      : RevenueBreakdown.fromJson(
          json['revenue_breakdown'] as Map<String, dynamic>,
        ),
  goals: json['goals'] == null
      ? null
      : StatsGoals.fromJson(json['goals'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StatisticsToJson(_Statistics instance) =>
    <String, dynamic>{
      'period': instance.period,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'overview': instance.overview,
      'performance': instance.performance,
      'daily_breakdown': instance.dailyBreakdown,
      'peak_hours': instance.peakHours,
      'revenue_breakdown': instance.revenueBreakdown,
      'goals': instance.goals,
    };

_StatsOverview _$StatsOverviewFromJson(Map<String, dynamic> json) =>
    _StatsOverview(
      totalDeliveries: json['total_deliveries'] == null
          ? 0
          : safeInt(json['total_deliveries']),
      totalEarnings: json['total_earnings'] == null
          ? 0.0
          : safeDouble(json['total_earnings']),
      totalDistanceKm: json['total_distance_km'] == null
          ? 0.0
          : safeDouble(json['total_distance_km']),
      totalDurationMinutes: json['total_duration_minutes'] == null
          ? 0
          : safeInt(json['total_duration_minutes']),
      averageRating: json['average_rating'] == null
          ? 0.0
          : safeDouble(json['average_rating']),
      deliveryTrend: json['delivery_trend'] == null
          ? 0.0
          : safeDouble(json['delivery_trend']),
      earningsTrend: json['earnings_trend'] == null
          ? 0.0
          : safeDouble(json['earnings_trend']),
      currency: json['currency'] as String? ?? 'FCFA',
    );

Map<String, dynamic> _$StatsOverviewToJson(_StatsOverview instance) =>
    <String, dynamic>{
      'total_deliveries': instance.totalDeliveries,
      'total_earnings': instance.totalEarnings,
      'total_distance_km': instance.totalDistanceKm,
      'total_duration_minutes': instance.totalDurationMinutes,
      'average_rating': instance.averageRating,
      'delivery_trend': instance.deliveryTrend,
      'earnings_trend': instance.earningsTrend,
      'currency': instance.currency,
    };

_StatsPerformance _$StatsPerformanceFromJson(Map<String, dynamic> json) =>
    _StatsPerformance(
      totalAssigned: json['total_assigned'] == null
          ? 0
          : safeInt(json['total_assigned']),
      totalAccepted: json['total_accepted'] == null
          ? 0
          : safeInt(json['total_accepted']),
      totalDelivered: json['total_delivered'] == null
          ? 0
          : safeInt(json['total_delivered']),
      totalCancelled: json['total_cancelled'] == null
          ? 0
          : safeInt(json['total_cancelled']),
      acceptanceRate: json['acceptance_rate'] == null
          ? 0.0
          : safeDouble(json['acceptance_rate']),
      completionRate: json['completion_rate'] == null
          ? 0.0
          : safeDouble(json['completion_rate']),
      cancellationRate: json['cancellation_rate'] == null
          ? 0.0
          : safeDouble(json['cancellation_rate']),
      onTimeRate: json['on_time_rate'] == null
          ? 0.0
          : safeDouble(json['on_time_rate']),
      satisfactionRate: json['satisfaction_rate'] == null
          ? 0.0
          : safeDouble(json['satisfaction_rate']),
    );

Map<String, dynamic> _$StatsPerformanceToJson(_StatsPerformance instance) =>
    <String, dynamic>{
      'total_assigned': instance.totalAssigned,
      'total_accepted': instance.totalAccepted,
      'total_delivered': instance.totalDelivered,
      'total_cancelled': instance.totalCancelled,
      'acceptance_rate': instance.acceptanceRate,
      'completion_rate': instance.completionRate,
      'cancellation_rate': instance.cancellationRate,
      'on_time_rate': instance.onTimeRate,
      'satisfaction_rate': instance.satisfactionRate,
    };

_DailyStats _$DailyStatsFromJson(Map<String, dynamic> json) => _DailyStats(
  date: json['date'] as String,
  dayName: json['day_name'] as String,
  deliveries: json['deliveries'] == null ? 0 : safeInt(json['deliveries']),
  earnings: json['earnings'] == null ? 0.0 : safeDouble(json['earnings']),
);

Map<String, dynamic> _$DailyStatsToJson(_DailyStats instance) =>
    <String, dynamic>{
      'date': instance.date,
      'day_name': instance.dayName,
      'deliveries': instance.deliveries,
      'earnings': instance.earnings,
    };

_PeakHour _$PeakHourFromJson(Map<String, dynamic> json) => _PeakHour(
  hour: json['hour'] as String,
  label: json['label'] as String,
  count: json['count'] == null ? 0 : safeInt(json['count']),
  percentage: json['percentage'] == null ? 0.0 : safeDouble(json['percentage']),
);

Map<String, dynamic> _$PeakHourToJson(_PeakHour instance) => <String, dynamic>{
  'hour': instance.hour,
  'label': instance.label,
  'count': instance.count,
  'percentage': instance.percentage,
};

_StatsGoals _$StatsGoalsFromJson(Map<String, dynamic> json) => _StatsGoals(
  weeklyTarget: json['weekly_target'] == null
      ? 0
      : safeInt(json['weekly_target']),
  currentProgress: json['current_progress'] == null
      ? 0
      : safeInt(json['current_progress']),
  progressPercentage: json['progress_percentage'] == null
      ? 0.0
      : safeDouble(json['progress_percentage']),
  remaining: json['remaining'] == null ? 0 : safeInt(json['remaining']),
);

Map<String, dynamic> _$StatsGoalsToJson(_StatsGoals instance) =>
    <String, dynamic>{
      'weekly_target': instance.weeklyTarget,
      'current_progress': instance.currentProgress,
      'progress_percentage': instance.progressPercentage,
      'remaining': instance.remaining,
    };
