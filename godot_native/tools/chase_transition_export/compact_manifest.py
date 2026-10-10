import json
from pathlib import Path
root = Path(__file__).resolve().parents[2] / 'assets/derived/chase_transition_3d'
s = json.loads((root/'source_transition.json').read_text())
frames = [f for entries in s['stages'].values() for f in entries]
indices = [i for i in range(len(s['nodes'])) if any(not f['visible'][i] for f in frames)]
keys = ['cameraPosition','cameraQuaternion','cameraFov','background','exposure','camera']
r = {'fps':s['fps'],'referenceNodes':s['referenceNodes'],'nodes':[s['nodes'][i] for i in indices],'stages':{}}
for stage,entries in s['stages'].items():
 r['stages'][stage] = []
 for f in entries:
  m = {k:f[k] for k in keys}
  m['visible'] = [f['visible'][i] for i in indices]
  restored = [True]*len(s['nodes'])
  for i,v in zip(indices,m['visible']): restored[i] = v
  assert restored == f['visible']
  r['stages'][stage].append(m)
(root/'source_runtime.json').write_text(json.dumps(r,separators=(',',':')))
print(f'Lossless frame visibility compaction: {len(s["nodes"])} -> {len(indices)} flags')
