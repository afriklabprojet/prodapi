import re

files = {}
current_file = None
with open('coverage/lcov.info') as f:
    for line in f:
        line = line.strip()
        if line.startswith('SF:'):
            current_file = line[3:]
        elif line.startswith('DA:'):
            parts = line[3:].split(',')
            if current_file not in files:
                files[current_file] = {'covered': 0, 'total': 0, 'uncovered': []}
            files[current_file]['total'] += 1
            if int(parts[1]) > 0:
                files[current_file]['covered'] += 1
            else:
                files[current_file]['uncovered'].append(int(parts[0]))

ranked = sorted(files.items(), key=lambda x: x[1]['total'] - x[1]['covered'], reverse=True)
print('Top 30 files by uncovered lines:')
for path, data in ranked[:30]:
    uncov = data['total'] - data['covered']
    pct = data['covered'] / data['total'] * 100 if data['total'] > 0 else 0
    short = path.replace('/Users/teya2023/Downloads/DR-PHARMA/mobile/delivery /lib/', '')
    # Show uncovered line ranges
    lines = data['uncovered']
    ranges = []
    if lines:
        start = lines[0]
        end = lines[0]
        for l in lines[1:]:
            if l == end + 1 or l == end + 2:
                end = l
            else:
                ranges.append(f"{start}-{end}" if start != end else str(start))
                start = end = l
        ranges.append(f"{start}-{end}" if start != end else str(start))
    range_str = ', '.join(ranges[:5])
    if len(ranges) > 5:
        range_str += f' (+{len(ranges)-5} more)'
    print(f'  {uncov:3d} uncov ({pct:5.1f}%) {short}  [{range_str}]')
