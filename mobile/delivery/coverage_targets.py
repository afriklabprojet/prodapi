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
                files[current_file] = {'covered': 0, 'total': 0}
            files[current_file]['total'] += 1
            if int(parts[1]) > 0:
                files[current_file]['covered'] += 1

# Filter for files with 20+ uncovered lines AND <60% coverage
print("Files <60% coverage with 20+ uncovered lines (high yield targets):")
targets = []
for path, data in files.items():
    uncov = data['total'] - data['covered']
    pct = data['covered'] / data['total'] * 100 if data['total'] > 0 else 0
    if uncov >= 20 and pct < 60:
        short = path.replace('/Users/teya2023/Downloads/DR-PHARMA/mobile/delivery /lib/', '')
        targets.append((uncov, pct, short))

targets.sort(key=lambda x: x[0], reverse=True)
for uncov, pct, short in targets:
    print(f"  {uncov:3d} uncov ({pct:5.1f}%) {short}")

print(f"\nTotal uncov in targets: {sum(t[0] for t in targets)}")

# Also show files with >60% coverage and 40+ uncov - potential specific branch targets
print("\nFiles >60% coverage with 40+ uncovered lines (branch coverage targets):")
branch_targets = []
for path, data in files.items():
    uncov = data['total'] - data['covered']
    pct = data['covered'] / data['total'] * 100 if data['total'] > 0 else 0
    if uncov >= 40 and pct >= 60:
        short = path.replace('/Users/teya2023/Downloads/DR-PHARMA/mobile/delivery /lib/', '')
        branch_targets.append((uncov, pct, short))

branch_targets.sort(key=lambda x: x[0], reverse=True)
for uncov, pct, short in branch_targets:
    print(f"  {uncov:3d} uncov ({pct:5.1f}%) {short}")
