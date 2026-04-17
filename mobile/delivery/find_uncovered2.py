files_of_interest = [
    'presentation/screens/wallet_screen.dart',
    'presentation/widgets/battery/advanced_battery_widgets.dart',
    'presentation/widgets/delivery/delivery_status_actions.dart',
    'data/repositories/auth_repository.dart',
    'presentation/widgets/notifications/notification_widgets.dart',
    'presentation/screens/login_screen_redesign.dart',
]

current_file = None
uncov_lines = {}
with open('./coverage/lcov.info') as f:
    for line in f:
        line = line.strip()
        if line.startswith('SF:'):
            p = line[3:]
            short = p.split('lib/')[-1]
            if short in files_of_interest:
                current_file = short
                uncov_lines[current_file] = []
            else:
                current_file = None
        elif line.startswith('DA:') and current_file:
            parts = line[3:].split(',')
            lineno, count = int(parts[0]), int(parts[1])
            if count == 0:
                uncov_lines[current_file].append(lineno)

for f in files_of_interest:
    if f in uncov_lines:
        lines = uncov_lines[f]
        print(f'\n{len(lines)} uncov - {f}')
        print('Lines:', lines[:40], '...' if len(lines) > 40 else '')
