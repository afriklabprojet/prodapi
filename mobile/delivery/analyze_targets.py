target_files = [
    'presentation/screens/gamification_screen.dart',
    'presentation/widgets/history/history_filter_sheet.dart',
    'presentation/widgets/tutorial/interactive_tutorial_widgets.dart',
    'presentation/widgets/delivery/delivery_proof.dart',
    'presentation/screens/document_scanner_screen.dart',
    'presentation/screens/create_ticket_screen.dart',
    'presentation/widgets/profile/personnel_card.dart',
    'presentation/widgets/common/app_empty_widget.dart',
    'presentation/screens/help_center_screen.dart',
    'core/services/delivery_export_service.dart',
]

current_file = None
covered = {}
uncovered = {}

with open('coverage/lcov.info') as f:
    for line in f:
        line = line.strip()
        if line.startswith('SF:'):
            path = line[3:]
            for tf in target_files:
                if path.endswith(tf):
                    current_file = tf
                    covered[tf] = []
                    uncovered[tf] = []
                    break
            else:
                current_file = None
        elif current_file and line.startswith('DA:'):
            parts = line[3:].split(',')
            ln, hits = int(parts[0]), int(parts[1])
            if hits > 0:
                covered[current_file].append(ln)
            else:
                uncovered[current_file].append(ln)

for tf in target_files:
    if tf in uncovered:
        print(f'{tf}: {len(uncovered[tf])} uncov: {uncovered[tf]}')
