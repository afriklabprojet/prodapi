import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/auto_theme_service.dart';

void main() {
  late AutoThemeService service;

  setUp(() {
    // Reset singleton state
    service = AutoThemeService.instance;
    service.dispose();
  });

  group('AutoThemeService', () {
    test('default nightStartHour is 19', () {
      expect(service.nightStartHour, 19);
    });

    test('default nightEndHour is 6', () {
      expect(service.nightEndHour, 6);
    });

    test('isEnabled defaults to false', () {
      expect(service.isEnabled, false);
    });

    test('isNightTime crossing midnight', () {
      // Night start = 19, end = 6
      // At 20h → should be night (true)
      // At 3h → should be night (true)
      // At 10h → should not be night (false)
      final now = DateTime.now();
      final hour = now.hour;

      final isNight = service.isNightTime();
      if (hour >= 19 || hour < 6) {
        expect(isNight, true);
      } else {
        expect(isNight, false);
      }
    });

    test('getTimeUntilNextChange returns positive duration', () {
      final duration = service.getTimeUntilNextChange();
      expect(duration.inSeconds, greaterThan(0));
    });

    test('getStatusDescription returns disabled message when not enabled', () {
      final desc = service.getStatusDescription();
      expect(desc, 'Mode automatique désactivé');
    });

    test('getIcon returns correct icon when disabled', () {
      expect(service.getIcon(), '🔆');
    });

    test('getSummary returns map with expected keys', () {
      final summary = service.getSummary();
      expect(summary, isA<Map<String, dynamic>>());
      expect(summary.containsKey('enabled'), isTrue);
      expect(summary.containsKey('is_night'), isTrue);
      expect(summary.containsKey('night_start'), isTrue);
      expect(summary.containsKey('night_end'), isTrue);
      expect(summary.containsKey('status'), isTrue);
      expect(summary.containsKey('icon'), isTrue);
    });
  });

  group('AutoThemeService - additional', () {
    test('isCurrentlyDark defaults to false', () {
      expect(service.isCurrentlyDark, isFalse);
    });

    test('formatHour pads single digit', () {
      expect(service.formatHour(6), '06:00');
      expect(service.formatHour(0), '00:00');
      expect(service.formatHour(9), '09:00');
    });

    test('formatHour double digit', () {
      expect(service.formatHour(19), '19:00');
      expect(service.formatHour(23), '23:00');
      expect(service.formatHour(12), '12:00');
    });

    test('nightScheduleDescription returns correct format', () {
      final desc = service.nightScheduleDescription;
      expect(desc, contains('Mode sombre de'));
      expect(desc, contains('19:00'));
      expect(desc, contains('06:00'));
    });

    test('getSummary contains correct values', () {
      final summary = service.getSummary();
      expect(summary['enabled'], false);
      expect(summary['night_start'], 19);
      expect(summary['night_end'], 6);
      expect(summary['icon'], '🔆');
    });

    test('getIcon returns sunburst when disabled', () {
      expect(service.getIcon(), '🔆');
    });

    test('getStatusDescription when disabled contains désactivé', () {
      final desc = service.getStatusDescription();
      expect(desc, contains('désactivé'));
    });

    test('default nightStartHour and nightEndHour', () {
      expect(service.nightStartHour, 19);
      expect(service.nightEndHour, 6);
    });
  });

  group('AutoThemeService - formatHour edge cases', () {
    test('formatHour with 0 returns 00:00', () {
      expect(service.formatHour(0), '00:00');
    });

    test('formatHour with 23 returns 23:00', () {
      expect(service.formatHour(23), '23:00');
    });

    test('formatHour with 10 returns 10:00', () {
      expect(service.formatHour(10), '10:00');
    });

    test('formatHour with negative returns padded', () {
      // This tests the padLeft behavior even with unusual inputs
      expect(service.formatHour(-1), '-1:00');
    });

    test('formatHour with 1 returns 01:00', () {
      expect(service.formatHour(1), '01:00');
    });

    test('formatHour with 5 returns 05:00', () {
      expect(service.formatHour(5), '05:00');
    });
  });

  group('AutoThemeService - getSummary variations', () {
    test('getSummary enabled field is bool', () {
      final summary = service.getSummary();
      expect(summary['enabled'], isA<bool>());
    });

    test('getSummary is_night field is bool', () {
      final summary = service.getSummary();
      expect(summary['is_night'], isA<bool>());
    });

    test('getSummary night_start is int', () {
      final summary = service.getSummary();
      expect(summary['night_start'], isA<int>());
    });

    test('getSummary night_end is int', () {
      final summary = service.getSummary();
      expect(summary['night_end'], isA<int>());
    });

    test('getSummary status is String', () {
      final summary = service.getSummary();
      expect(summary['status'], isA<String>());
    });

    test('getSummary icon is String', () {
      final summary = service.getSummary();
      expect(summary['icon'], isA<String>());
    });
  });

  group('AutoThemeService - nightScheduleDescription', () {
    test('nightScheduleDescription contains start hour', () {
      final desc = service.nightScheduleDescription;
      expect(desc, contains(service.formatHour(service.nightStartHour)));
    });

    test('nightScheduleDescription contains end hour', () {
      final desc = service.nightScheduleDescription;
      expect(desc, contains(service.formatHour(service.nightEndHour)));
    });

    test('nightScheduleDescription starts with Mode sombre', () {
      final desc = service.nightScheduleDescription;
      expect(desc.startsWith('Mode sombre'), isTrue);
    });
  });

  group('AutoThemeService - time calculations', () {
    test('getTimeUntilNextChange returns non-negative duration', () {
      final duration = service.getTimeUntilNextChange();
      expect(duration.isNegative, isFalse);
    });

    test('getTimeUntilNextChange returns less than 24 hours', () {
      final duration = service.getTimeUntilNextChange();
      expect(duration.inHours, lessThanOrEqualTo(24));
    });

    test('getTimeUntilNextChange has positive minutes or hours', () {
      final duration = service.getTimeUntilNextChange();
      expect(duration.inMinutes, greaterThan(0));
    });
  });

  group('AutoThemeService - getIcon states', () {
    test('getIcon when not enabled returns brightness icon', () {
      expect(service.getIcon(), '🔆');
    });

    test('getIcon emoji is single character or cluster', () {
      final icon = service.getIcon();
      expect(icon.isNotEmpty, isTrue);
    });
  });

  group('AutoThemeService - dispose and state', () {
    test('dispose can be called multiple times', () {
      service.dispose();
      service.dispose();
      // Should not throw
      expect(service.isEnabled, isFalse);
    });

    test('after dispose, isEnabled remains false', () {
      service.dispose();
      expect(service.isEnabled, isFalse);
    });

    test('after dispose, isCurrentlyDark is false', () {
      service.dispose();
      expect(service.isCurrentlyDark, isFalse);
    });
  });

  group('AutoThemeService - isNightTime edge cases', () {
    test('isNightTime returns bool', () {
      expect(service.isNightTime(), isA<bool>());
    });

    test('isNightTime is consistent across multiple calls', () {
      final first = service.isNightTime();
      final second = service.isNightTime();
      expect(first, second);
    });

    test('getStatusDescription contains mode keyword', () {
      final desc = service.getStatusDescription();
      expect(desc.toLowerCase(), contains('mode'));
    });
  });
}
