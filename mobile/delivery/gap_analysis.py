files = {}
current = None
with open('coverage/lcov.info') as f:
    for line in f:
        line = line.strip()
        if line.startswith('SF:'):
            current = line[3:]
        elif line.startswith('DA:'):
            parts = line[3:].split(',')
            if current not in files:
                files[current] = [0, 0]
            files[current][1] += 1
            if int(parts[1]) > 0:
                files[current][0] += 1
result = []
for f, vals in files.items():
    h, t = vals
    m = t - h
    p = 100.0 * h / t if t > 0 else 100
    short = f.split('/lib/')[-1] if '/lib/' in f else f.split('/')[-1]
    result.append((m, p, short))
result.sort(reverse=True)
for m, p, s in result[:30]:
    print('%s %d %.1f%%' % (s, m, p))
