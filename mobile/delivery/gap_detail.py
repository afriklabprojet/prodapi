#!/usr/bin/env python3
"""Find specific uncovered line ranges in target files."""

targets = [
    'lib/features/settings/home_widget_settings_screen.dart',
    'lib/presentation/screens/multi_route_screen.dart',
    'lib/presentation/screens/gamification_screen.dart',
    'lib/presentation/widgets/battery/battery_indicator_widget.dart',
    'lib/presentation/widgets/delivery/delivery_document_section.dart',
    'lib/presentation/widgets/tutorial/interactive_tutorial_widgets.dart',
    'lib/presentation/widgets/gamification/gamification_widgets.dart',
    'lib/presentation/screens/challenges_screen.dart',
    'lib/presentation/screens/support_tickets_screen.dart',
    'lib/presentation/widgets/gamification/daily_challenges_widgets.dart',
    'lib/presentation/screens/delivery_details_screen.dart',
    'lib/presentation/widgets/tutorial/tutorial_widgets.dart',
    'lib/presentation/screens/help_center_screen.dart',
    'lib/presentation/screens/pending_approval_screen.dart',
    'lib/presentation/widgets/home/delivery_dialogs.dart',
    'lib/core/theme/theme_provider.dart',
    'lib/presentation/providers/history_providers.dart',
    'lib/presentation/widgets/common/signature_pad.dart',
]

file_stats = {}
current_file = None
with open('coverage/lcov.info') as f:
    for line in f:
        line = line.strip()
        if line.startswith('SF:'):
            current_file = line[3:]
        elif line.startswith('DA:'):
            parts = line[3:].split(',')
            line_num = int(parts[0])
            hits = int(parts[1])
            if current_file not in file_stats:
                file_stats[current_file] = {'covered': 0, 'total': 0, 'uncovered': []}
            file_stats[current_file]['total'] += 1
            if hits > 0:
                file_stats[current_file]['covered'] += 1
            else:
                file_stats[current_file]['uncovered'].append(line_num)

for t in targets:
    if t in file_stats:
        uncov = file_stats[t]['uncovered']
        total = file_stats[t]['total']
        cov = file_stats[t]['covered']
        ranges = []
        if uncov:
            start = uncov[0]
            end = uncov[0]
            for i in range(1, len(uncov)):
                if uncov[i] <= end + 2:
                    end = uncov[i]
                else:
                    ranges.append((start, end))
                    start = uncov[i]
                    end = uncov[i]
            ranges.append((start, end))
        pct = cov / total * 100 if total > 0 else 0
        print(f"\n{t.replace('lib/', '')} ({len(uncov)} uncov / {total} total = {pct:.0f}%)")
        for s, e in ranges:
            span = e - s + 1
            print(f"  Lines {s}-{e} ({span} lines)")
