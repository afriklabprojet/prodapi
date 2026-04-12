import sys

lines = open('coverage/lcov.info').readlines()
cur = None
uncov_ranges = {}

for l in lines:
    if l.startswith('SF:'):
        cur = l.strip()[3:]
    elif l.startswith('DA:') and cur:
        parts = l.strip()[3:].split(',')
        ln = int(parts[0])
        hits = int(parts[1])
        if hits == 0:
            if cur not in uncov_ranges:
                uncov_ranges[cur] = []
            uncov_ranges[cur].append(ln)

targets = [
    'lib/core/services/advanced_home_widget_service.dart',
    'lib/core/services/delivery_proof_service.dart',
    'lib/core/services/home_widget_service.dart',
    'lib/core/services/notification_service.dart',
    'lib/core/services/enhanced_chat_service.dart',
    'lib/presentation/screens/edit_profile_screen.dart',
    'lib/presentation/screens/otp_verification_screen.dart',
    'lib/core/services/live_tracking_service.dart',
    'lib/presentation/widgets/notifications/notification_widgets.dart',
    'lib/presentation/widgets/profile/profile_hero.dart',
    'lib/presentation/widgets/history/history_filter_sheet.dart',
    'lib/presentation/widgets/home/active_delivery_panel.dart',
    'lib/presentation/widgets/wallet/earnings_export_sheet.dart',
]

for t in targets:
    if t in uncov_ranges:
        lns = uncov_ranges[t]
        ranges = []
        start = lns[0]
        prev = lns[0]
        for ln in lns[1:]:
            if ln == prev + 1:
                prev = ln
            else:
                if start != prev:
                    ranges.append(f'{start}-{prev}')
                else:
                    ranges.append(str(start))
                start = ln
                prev = ln
        if start != prev:
            ranges.append(f'{start}-{prev}')
        else:
            ranges.append(str(start))
        short = t.replace('lib/', '')
        print(f'{short} ({len(lns)} uncov):')
        print(f'  {" ".join(ranges[:20])}')
        print()
