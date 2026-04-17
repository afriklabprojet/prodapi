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

targets = ['navigation_service', 'delivery_proof', 'app_update_service',
    'interactive_tutorial', 'whatsapp_service', 'error_boundary',
    'login_screen_redesign', 'register_screen_redesign']
for t in targets:
    for f, d in files.items():
        if t in f:
            pct = d['covered']/d['total']*100 if d['total']>0 else 0
            uncov = d['total'] - d['covered']
            name = f.split('/')[-1]
            print(f'{name}: {d["covered"]}/{d["total"]} ({pct:.1f}%) uncov={uncov}')

print("\n--- TOP 30 by uncov ---")
ranked = sorted(files.items(), key=lambda x: x[1]['total']-x[1]['covered'], reverse=True)
for f, d in ranked[:30]:
    pct = d['covered']/d['total']*100 if d['total']>0 else 0
    uncov = d['total'] - d['covered']
    name = f.split('/')[-1]
    print(f'{uncov:4d} uncov  {pct:5.1f}%  {name}')
