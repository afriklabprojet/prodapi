lines = open('coverage/lcov.info').readlines()
cur = None
files = {}
for l in lines:
    if l.startswith('SF:'):
        cur = l.strip()[3:]
    elif l.startswith('DA:') and cur:
        parts = l.strip()[3:].split(',')
        if cur not in files:
            files[cur] = [0, 0]
        files[cur][1] += 1
        if int(parts[1]) > 0:
            files[cur][0] += 1

zero_cov = [(f, t) for f, (h, t) in files.items() if h == 0 and t > 15]
zero_cov.sort(key=lambda x: -x[1])
print('=== FULLY UNTESTED FILES ===')
for f, t in zero_cov:
    print(f'  {t:4d} lines  {f.replace("lib/", "")}')

print()
print('=== <10% COVERAGE ===')
low_cov = [(f, h, t) for f, (h, t) in files.items() if h > 0 and h / t < 0.10 and t > 20]
low_cov.sort(key=lambda x: -(x[2] - x[1]))
for f, h, t in low_cov[:10]:
    pct = h * 100 / t
    print(f'  {h:4d}/{t:4d} ({pct:.0f}%)  {f.replace("lib/", "")}')
