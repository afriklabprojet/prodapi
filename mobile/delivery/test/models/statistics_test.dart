import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/statistics.dart';

void main() {
  group('Statistics', () {
    test('fromJson with full data', () {
      final json = {
        'period': 'week',
        'start_date': '2026-02-07',
        'end_date': '2026-02-13',
        'overview': {
          'total_deliveries': 25,
          'total_earnings': 75000.0,
          'total_distance_km': 120.5,
          'total_duration_minutes': 480,
          'average_rating': 4.7,
          'delivery_trend': 12.5,
          'earnings_trend': -3.2,
          'currency': 'FCFA',
        },
        'performance': {
          'total_assigned': 30,
          'total_accepted': 28,
          'total_delivered': 25,
          'total_cancelled': 2,
          'acceptance_rate': 93.3,
          'completion_rate': 89.3,
          'cancellation_rate': 6.7,
          'on_time_rate': 95.0,
          'satisfaction_rate': 92.0,
        },
        'daily_breakdown': [
          {'date': '2026-02-07', 'day_name': 'Lundi', 'deliveries': 5, 'earnings': 15000.0},
          {'date': '2026-02-08', 'day_name': 'Mardi', 'deliveries': 3, 'earnings': 9000.0},
        ],
        'peak_hours': [
          {'hour': '12', 'label': '12h-13h', 'count': 8, 'percentage': 32.0},
        ],
        'revenue_breakdown': {
          'delivery_commissions': {'amount': 50000.0, 'percentage': 66.7},
          'challenge_bonuses': {'amount': 15000.0, 'percentage': 20.0},
          'rush_bonuses': {'amount': 10000.0, 'percentage': 13.3},
          'total': 75000.0,
        },
        'goals': {
          'weekly_target': 30,
          'current_progress': 25,
          'progress_percentage': 83.3,
          'remaining': 5,
        },
      };
      final stats = Statistics.fromJson(json);
      expect(stats.period, 'week');
      expect(stats.startDate, '2026-02-07');
      expect(stats.endDate, '2026-02-13');
      expect(stats.overview.totalDeliveries, 25);
      expect(stats.overview.totalEarnings, 75000.0);
      expect(stats.overview.averageRating, 4.7);
      expect(stats.performance.acceptanceRate, 93.3);
      expect(stats.performance.completionRate, 89.3);
      expect(stats.dailyBreakdown.length, 2);
      expect(stats.dailyBreakdown.first.dayName, 'Lundi');
      expect(stats.peakHours.length, 1);
      expect(stats.peakHours.first.label, '12h-13h');
      expect(stats.revenueBreakdown, isNotNull);
      expect(stats.revenueBreakdown!.total, 75000.0);
      expect(stats.revenueBreakdown!.deliveryCommissionsAmount, 50000.0);
      expect(stats.goals, isNotNull);
      expect(stats.goals!.weeklyTarget, 30);
      expect(stats.goals!.remaining, 5);
    });

    test('fromJson with minimal data (defaults)', () {
      final json = {
        'period': 'month',
        'start_date': '2026-02-01',
        'end_date': '2026-02-28',
        'overview': <String, dynamic>{},
        'performance': <String, dynamic>{},
      };
      final stats = Statistics.fromJson(json);
      expect(stats.overview.totalDeliveries, 0);
      expect(stats.overview.totalEarnings, 0.0);
      expect(stats.overview.currency, 'FCFA');
      expect(stats.performance.totalAssigned, 0);
      expect(stats.dailyBreakdown, isEmpty);
      expect(stats.peakHours, isEmpty);
      expect(stats.revenueBreakdown, isNull);
      expect(stats.goals, isNull);
    });
  });

  group('RevenueBreakdown', () {
    test('fromJson parses nested structure', () {
      final json = {
        'delivery_commissions': {'amount': 50000.0, 'percentage': 66.7},
        'challenge_bonuses': {'amount': 15000.0, 'percentage': 20.0},
        'rush_bonuses': {'amount': 10000.0, 'percentage': 13.3},
        'total': 75000.0,
      };
      final rb = RevenueBreakdown.fromJson(json);
      expect(rb.deliveryCommissionsAmount, 50000.0);
      expect(rb.deliveryCommissionsPercent, 66.7);
      expect(rb.challengeBonusesAmount, 15000.0);
      expect(rb.rushBonusesAmount, 10000.0);
      expect(rb.total, 75000.0);
    });

    test('fromJson handles empty/null safely', () {
      final rb = RevenueBreakdown.fromJson(<String, dynamic>{});
      expect(rb.deliveryCommissionsAmount, 0.0);
      expect(rb.total, 0.0);
    });

    test('toJson round-trip', () {
      final original = RevenueBreakdown.fromJson({
        'delivery_commissions': {'amount': 1000.0, 'percentage': 50.0},
        'challenge_bonuses': {'amount': 500.0, 'percentage': 25.0},
        'rush_bonuses': {'amount': 500.0, 'percentage': 25.0},
        'total': 2000.0,
      });
      final json = original.toJson();
      final restored = RevenueBreakdown.fromJson(json);
      expect(restored.deliveryCommissionsAmount, original.deliveryCommissionsAmount);
      expect(restored.total, original.total);
    });
  });

  group('DailyStats', () {
    test('fromJson works', () {
      final daily = DailyStats.fromJson({
        'date': '2026-02-13',
        'day_name': 'Vendredi',
        'deliveries': 7,
        'earnings': 21000.0,
      });
      expect(daily.date, '2026-02-13');
      expect(daily.dayName, 'Vendredi');
      expect(daily.deliveries, 7);
      expect(daily.earnings, 21000.0);
    });

    test('fromJson uses defaults', () {
      final daily = DailyStats.fromJson({
        'date': '2026-02-13',
        'day_name': 'Vendredi',
      });
      expect(daily.deliveries, 0);
      expect(daily.earnings, 0.0);
    });
  });

  group('StatsGoals', () {
    test('fromJson works', () {
      final goals = StatsGoals.fromJson({
        'weekly_target': 30,
        'current_progress': 20,
        'progress_percentage': 66.7,
        'remaining': 10,
      });
      expect(goals.weeklyTarget, 30);
      expect(goals.currentProgress, 20);
      expect(goals.progressPercentage, 66.7);
      expect(goals.remaining, 10);
    });

    test('toJson serializes correctly', () {
      const goals = StatsGoals(
        weeklyTarget: 30,
        currentProgress: 20,
        progressPercentage: 66.7,
        remaining: 10,
      );
      final json = goals.toJson();
      expect(json['weekly_target'], 30);
      expect(json['current_progress'], 20);
      expect(json['progress_percentage'], 66.7);
      expect(json['remaining'], 10);
    });

    test('toJson fromJson roundtrip', () {
      const original = StatsGoals(
        weeklyTarget: 50,
        currentProgress: 35,
        progressPercentage: 70.0,
        remaining: 15,
      );
      final json = original.toJson();
      final restored = StatsGoals.fromJson(json);
      expect(restored.weeklyTarget, original.weeklyTarget);
      expect(restored.currentProgress, original.currentProgress);
      expect(restored.progressPercentage, original.progressPercentage);
      expect(restored.remaining, original.remaining);
    });
  });

  group('Statistics toJson', () {
    test('toJson serializes full Statistics object', () {
      const stats = Statistics(
        period: 'week',
        startDate: '2026-02-07',
        endDate: '2026-02-13',
        overview: StatsOverview(
          totalDeliveries: 25,
          totalEarnings: 75000.0,
          totalDistanceKm: 120.5,
          totalDurationMinutes: 480,
          averageRating: 4.7,
          deliveryTrend: 12.5,
          earningsTrend: -3.2,
          currency: 'FCFA',
        ),
        performance: StatsPerformance(
          totalAssigned: 30,
          totalAccepted: 28,
          totalDelivered: 25,
          totalCancelled: 2,
          acceptanceRate: 93.3,
          completionRate: 89.3,
          cancellationRate: 6.7,
          onTimeRate: 95.0,
          satisfactionRate: 92.0,
        ),
        dailyBreakdown: [
          DailyStats(date: '2026-02-07', dayName: 'Lundi', deliveries: 5, earnings: 15000.0),
        ],
        peakHours: [
          PeakHour(hour: '12', label: '12h-13h', count: 8, percentage: 32.0),
        ],
      );

      final json = stats.toJson();
      expect(json['period'], 'week');
      expect(json['start_date'], '2026-02-07');
      expect(json['end_date'], '2026-02-13');
      expect(json['overview'], isA<StatsOverview>());
      expect(json['performance'], isA<StatsPerformance>());
      expect(json['daily_breakdown'], isA<List>());
      expect((json['daily_breakdown'] as List).length, 1);
      expect(json['peak_hours'], isA<List>());
      expect((json['peak_hours'] as List).length, 1);
      expect(json['revenue_breakdown'], isNull);
      expect(json['goals'], isNull);
    });

    test('toJson preserves all top-level fields', () {
      const original = Statistics(
        period: 'month',
        startDate: '2026-01-01',
        endDate: '2026-01-31',
        overview: StatsOverview(
          totalDeliveries: 100,
          totalEarnings: 300000.0,
          totalDistanceKm: 500.0,
          totalDurationMinutes: 2400,
          averageRating: 4.5,
          deliveryTrend: 5.0,
          earningsTrend: 10.0,
        ),
        performance: StatsPerformance(
          totalAssigned: 120,
          totalAccepted: 110,
          totalDelivered: 100,
          totalCancelled: 5,
          acceptanceRate: 91.7,
          completionRate: 90.9,
          cancellationRate: 4.2,
          onTimeRate: 88.0,
          satisfactionRate: 90.0,
        ),
      );
      final json = original.toJson();
      expect(json['period'], original.period);
      expect(json['start_date'], original.startDate);
      expect(json['end_date'], original.endDate);

      // Verify nested objects are accessible
      final overview = json['overview'] as StatsOverview;
      expect(overview.totalDeliveries, 100);
      expect(overview.totalEarnings, 300000.0);

      final perf = json['performance'] as StatsPerformance;
      expect(perf.totalAssigned, 120);
      expect(perf.acceptanceRate, 91.7);
    });
  });

  group('StatsOverview toJson', () {
    test('toJson serializes all fields', () {
      const overview = StatsOverview(
        totalDeliveries: 50,
        totalEarnings: 150000.0,
        totalDistanceKm: 250.3,
        totalDurationMinutes: 1200,
        averageRating: 4.6,
        deliveryTrend: 8.0,
        earningsTrend: -2.0,
        currency: 'XOF',
      );
      final json = overview.toJson();
      expect(json['total_deliveries'], 50);
      expect(json['total_earnings'], 150000.0);
      expect(json['total_distance_km'], 250.3);
      expect(json['total_duration_minutes'], 1200);
      expect(json['average_rating'], 4.6);
      expect(json['delivery_trend'], 8.0);
      expect(json['earnings_trend'], -2.0);
      expect(json['currency'], 'XOF');
    });

    test('toJson fromJson roundtrip', () {
      const original = StatsOverview(
        totalDeliveries: 10,
        totalEarnings: 30000.0,
        totalDistanceKm: 45.0,
        totalDurationMinutes: 180,
        averageRating: 3.9,
      );
      final json = original.toJson();
      final restored = StatsOverview.fromJson(json);
      expect(restored.totalDeliveries, original.totalDeliveries);
      expect(restored.totalEarnings, original.totalEarnings);
      expect(restored.totalDistanceKm, original.totalDistanceKm);
      expect(restored.totalDurationMinutes, original.totalDurationMinutes);
      expect(restored.averageRating, original.averageRating);
      expect(restored.deliveryTrend, original.deliveryTrend);
      expect(restored.earningsTrend, original.earningsTrend);
      expect(restored.currency, original.currency);
    });
  });

  group('StatsPerformance toJson', () {
    test('toJson serializes all fields', () {
      const perf = StatsPerformance(
        totalAssigned: 40,
        totalAccepted: 38,
        totalDelivered: 35,
        totalCancelled: 3,
        acceptanceRate: 95.0,
        completionRate: 92.1,
        cancellationRate: 7.5,
        onTimeRate: 88.0,
        satisfactionRate: 91.0,
      );
      final json = perf.toJson();
      expect(json['total_assigned'], 40);
      expect(json['total_accepted'], 38);
      expect(json['total_delivered'], 35);
      expect(json['total_cancelled'], 3);
      expect(json['acceptance_rate'], 95.0);
      expect(json['completion_rate'], 92.1);
      expect(json['cancellation_rate'], 7.5);
      expect(json['on_time_rate'], 88.0);
      expect(json['satisfaction_rate'], 91.0);
    });

    test('toJson fromJson roundtrip', () {
      const original = StatsPerformance(
        totalAssigned: 60,
        totalAccepted: 55,
        totalDelivered: 50,
        totalCancelled: 4,
        acceptanceRate: 91.7,
        completionRate: 90.9,
        cancellationRate: 6.7,
        onTimeRate: 85.0,
        satisfactionRate: 88.0,
      );
      final json = original.toJson();
      final restored = StatsPerformance.fromJson(json);
      expect(restored.totalAssigned, original.totalAssigned);
      expect(restored.totalAccepted, original.totalAccepted);
      expect(restored.totalDelivered, original.totalDelivered);
      expect(restored.totalCancelled, original.totalCancelled);
      expect(restored.acceptanceRate, original.acceptanceRate);
      expect(restored.completionRate, original.completionRate);
      expect(restored.cancellationRate, original.cancellationRate);
      expect(restored.onTimeRate, original.onTimeRate);
      expect(restored.satisfactionRate, original.satisfactionRate);
    });
  });

  group('DailyStats toJson', () {
    test('toJson serializes all fields', () {
      const daily = DailyStats(
        date: '2026-02-10',
        dayName: 'Mercredi',
        deliveries: 7,
        earnings: 21000.0,
      );
      final json = daily.toJson();
      expect(json['date'], '2026-02-10');
      expect(json['day_name'], 'Mercredi');
      expect(json['deliveries'], 7);
      expect(json['earnings'], 21000.0);
    });

    test('toJson fromJson roundtrip', () {
      const original = DailyStats(
        date: '2026-03-01',
        dayName: 'Samedi',
        deliveries: 12,
        earnings: 36000.0,
      );
      final json = original.toJson();
      final restored = DailyStats.fromJson(json);
      expect(restored.date, original.date);
      expect(restored.dayName, original.dayName);
      expect(restored.deliveries, original.deliveries);
      expect(restored.earnings, original.earnings);
    });
  });

  group('PeakHour toJson', () {
    test('toJson serializes all fields', () {
      const peak = PeakHour(
        hour: '18',
        label: '18h-19h',
        count: 15,
        percentage: 45.0,
      );
      final json = peak.toJson();
      expect(json['hour'], '18');
      expect(json['label'], '18h-19h');
      expect(json['count'], 15);
      expect(json['percentage'], 45.0);
    });

    test('toJson fromJson roundtrip', () {
      const original = PeakHour(
        hour: '08',
        label: '08h-09h',
        count: 3,
        percentage: 10.0,
      );
      final json = original.toJson();
      final restored = PeakHour.fromJson(json);
      expect(restored.hour, original.hour);
      expect(restored.label, original.label);
      expect(restored.count, original.count);
      expect(restored.percentage, original.percentage);
    });
  });

  group('PeakHour fromJson', () {
    test('fromJson with defaults', () {
      final peak = PeakHour.fromJson({
        'hour': '14',
        'label': '14h-15h',
      });
      expect(peak.count, 0);
      expect(peak.percentage, 0.0);
    });
  });

  group('RevenueBreakdown toJson', () {
    test('toJson produces nested structure', () {
      const rb = RevenueBreakdown(
        deliveryCommissionsAmount: 40000.0,
        deliveryCommissionsPercent: 60.0,
        challengeBonusesAmount: 20000.0,
        challengeBonusesPercent: 30.0,
        rushBonusesAmount: 5000.0,
        rushBonusesPercent: 10.0,
        total: 65000.0,
      );
      final json = rb.toJson();
      expect(json['delivery_commissions']['amount'], 40000.0);
      expect(json['delivery_commissions']['percentage'], 60.0);
      expect(json['challenge_bonuses']['amount'], 20000.0);
      expect(json['challenge_bonuses']['percentage'], 30.0);
      expect(json['rush_bonuses']['amount'], 5000.0);
      expect(json['rush_bonuses']['percentage'], 10.0);
      expect(json['total'], 65000.0);
    });
  });

  group('Statistics with optional fields', () {
    test('toJson includes revenueBreakdown and goals when present', () {
      const stats = Statistics(
        period: 'day',
        startDate: '2026-03-01',
        endDate: '2026-03-01',
        overview: StatsOverview(),
        performance: StatsPerformance(),
        revenueBreakdown: RevenueBreakdown(total: 5000.0),
        goals: StatsGoals(weeklyTarget: 20, remaining: 15),
      );
      final json = stats.toJson();
      expect(json['revenue_breakdown'], isNotNull);
      expect(json['goals'], isNotNull);
    });

    test('Statistics with dailyBreakdown and peakHours serializes lists', () {
      const stats = Statistics(
        period: 'week',
        startDate: '2026-03-01',
        endDate: '2026-03-07',
        overview: StatsOverview(),
        performance: StatsPerformance(),
        dailyBreakdown: [
          DailyStats(date: '2026-03-01', dayName: 'Lun', deliveries: 3, earnings: 9000),
          DailyStats(date: '2026-03-02', dayName: 'Mar', deliveries: 5, earnings: 15000),
        ],
        peakHours: [
          PeakHour(hour: '12', label: '12h-13h', count: 10, percentage: 40.0),
          PeakHour(hour: '18', label: '18h-19h', count: 8, percentage: 32.0),
        ],
      );
      final json = stats.toJson();
      final dailyList = json['daily_breakdown'] as List;
      final peakList = json['peak_hours'] as List;
      expect(dailyList.length, 2);
      expect(peakList.length, 2);
    });

    test('Statistics default values serialize correctly', () {
      const stats = Statistics(
        period: 'year',
        startDate: '2026-01-01',
        endDate: '2026-12-31',
        overview: StatsOverview(),
        performance: StatsPerformance(),
      );
      final json = stats.toJson();
      expect(json['daily_breakdown'], isEmpty);
      expect(json['peak_hours'], isEmpty);
      expect(json['revenue_breakdown'], isNull);
      expect(json['goals'], isNull);

      // Also verify overview defaults
      final overviewJson = (json['overview'] as StatsOverview).toJson();
      expect(overviewJson['total_deliveries'], 0);
      expect(overviewJson['total_earnings'], 0.0);
      expect(overviewJson['currency'], 'FCFA');

      // Verify performance defaults
      final perfJson = (json['performance'] as StatsPerformance).toJson();
      expect(perfJson['total_assigned'], 0);
      expect(perfJson['acceptance_rate'], 0.0);
    });
  });
}
