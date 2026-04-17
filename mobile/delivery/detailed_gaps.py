import sys

target_files = [
    'error_boundary.dart',
    'delivery_status_actions.dart', 
    'profile_hero.dart',
    'kyc_resubmission_screen.dart',
    'history_export_screen.dart',
    'interactive_tutorial_screen.dart',
    'enhanced_chat_widgets.dart',
    'earnings_export_sheet.dart',
    'auth_repository.dart',
    'delivery_document_section.dart',
    'gamification_screen.dart',
    'statistics_screen.dart',
    'settings_screen.dart',
    'deliveries_screen.dart',
    'wallet_screen.dart',
]

current = None
file_data = {}  # filename -> list of (line_num, is_covered)

with open('coverage/lcov.info') as f:
    for line in f:
        line = line.strip()
        if line.startswith('SF:'):
            current = line[3:].split('/')[-1]
        elif line.startswith('DA:') and current:
            parts = line[3:].split(',')
            line_num = int(parts[0])
            hit_count = int(parts[1])
            if current in target_files:
                if current not in file_data:
                    file_data[current] = []
                file_data[current].append((line_num, hit_count > 0))

for fname in target_files:
    if fname not in file_data:
        continue
    data = file_data[fname]
    uncov_lines = [ln for ln, covered in data if not covered]
    total = len(data)
    covered = sum(1 for _, c in data if c)
    pct = covered/total*100 if total > 0 else 0
    
    # Find contiguous uncovered ranges
    ranges = []
    if uncov_lines:
        start = uncov_lines[0]
        end = uncov_lines[0]
        for ln in uncov_lines[1:]:
            if ln == end + 1 or ln == end + 2:  # allow 1-line gap
                end = ln
            else:
                ranges.append((start, end))
                start = ln
                end = ln
        ranges.append((start, end))
    
    big_ranges = [(s, e, e-s+1) for s, e in ranges if e-s+1 >= 3]
    print(f'\n{fname}: {covered}/{total} ({pct:.1f}%) uncov={len(uncov_lines)}')
    for s, e, size in big_ranges:
        print(f'  Lines {s}-{e} ({size} lines)')
