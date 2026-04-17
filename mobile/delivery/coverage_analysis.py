import collections

files = {}
with open('coverage/lcov.info') as f:
    sf = None
    for line in f:
        line = line.strip()
        if line.startswith('SF:'):
            sf = line[3:]
            files[sf] = {'total': 0, 'covered': 0, 'uncov_lines': []}
        elif line.startswith('DA:') and sf:
            parts = line[3:].split(',')
            lno, hits = int(parts[0]), int(parts[1])
            files[sf]['total'] += 1
            if hits > 0:
                files[sf]['covered'] += 1
            else:
                files[sf]['uncov_lines'].append(lno)

# Files with 20-50 uncov lines (medium difficulty)
ranked = sorted(files.items(), key=lambda x: len(x[1]['uncov_lines']), reverse=True)
print('Files with 20-60 uncovered lines (sweet spot):')
total_uncov = 0
for path, d in ranked:
    uncov = len(d['uncov_lines'])
    if 20 <= uncov <= 60:
        pct = d['covered']/d['total']*100 if d['total']>0 else 100
        short = path.replace('lib/', '')
        total_uncov += uncov
        print(f'  {uncov:3d} uncov ({pct:5.1f}%) {short}')
print(f'Total in this range: {total_uncov}')

print('\nFiles with 10-19 uncovered lines:')
total_small = 0
for path, d in ranked:
    uncov = len(d['uncov_lines'])
    if 10 <= uncov <= 19:
        pct = d['covered']/d['total']*100 if d['total']>0 else 100
        short = path.replace('lib/', '')
        total_small += uncov
        print(f'  {uncov:3d} uncov ({pct:5.1f}%) {short}')
print(f'Total in this range: {total_small}')

