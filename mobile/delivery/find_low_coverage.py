files = {}
current = None
with open('coverage/lcov.info') as f:
    for line in f:
        line = line.strip()
        if line.startswith('SF:'):
            current = line[3:]
        elif line.startswith('DA:') and current:
            parts = line[3:].split(',')
            if current not in files:
                files[current] = {'total': 0, 'covered': 0}
            files[current]['total'] += 1
            if int(parts[1]) > 0:
                files[current]['covered'] += 1

# Find files with < 50% coverage and > 20 uncov lines
print("=== LOW COVERAGE FILES (< 50%, > 20 uncov) ===")
low = []
for f, d in files.items():
    uncov = d['total'] - d['covered']
    pct = d['covered']/d['total']*100 if d['total'] > 0 else 0
    if pct < 50 and uncov > 20:
        low.append((uncov, pct, f.split('/')[-1], f))
low.sort(reverse=True)
for uncov, pct, name, path in low:
    print(f'{uncov:4d} uncov  {pct:5.1f}%  {name}')

# Find files with < 30% coverage  
print("\n=== VERY LOW COVERAGE (< 30%) ===")
vlow = []
for f, d in files.items():
    uncov = d['total'] - d['covered']
    pct = d['covered']/d['total']*100 if d['total'] > 0 else 0
    if pct < 30 and uncov > 10:
        vlow.append((uncov, pct, f.split('/')[-1], f))
vlow.sort(reverse=True)
for uncov, pct, name, path in vlow:
    print(f'{uncov:4d} uncov  {pct:5.1f}%  {name}')

# Total uncov in all files
total_uncov = sum(d['total'] - d['covered'] for d in files.values())
total_lines = sum(d['total'] for d in files.values())
total_covered = sum(d['covered'] for d in files.values())
print(f'\nTotal: {total_covered}/{total_lines} = {total_covered/total_lines*100:.1f}%')
print(f'Total uncov: {total_uncov}')
print(f'Need 80%: {int(total_lines * 0.8) - total_covered} more lines')
