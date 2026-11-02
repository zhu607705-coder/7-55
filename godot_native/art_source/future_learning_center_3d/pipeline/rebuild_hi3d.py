"""Rebuild approved local derivatives only. Never calls provider or paid tools.
Run from any directory: python3 pipeline/rebuild_hi3d.py
Preserved normalized base GLBs are intentional inputs, tracked with their hashes
in edit_receipt.json. Raw provider originals also remain separately preserved.
"""
import json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];BLENDER='/Applications/Blender.app/Contents/MacOS/Blender'
def run(args):subprocess.run(args,cwd=ROOT,check=True)
run([BLENDER,'--background','--factory-startup','--python','pipeline/refine_table.py'])
run([BLENDER,'--background','--factory-startup','--python','pipeline/refine_sofa.py'])
base=Path('sources/models/hi3d')
jobs=[(base/'mobile_exhibition_table/local_edits'/f'table_{c}.glb',base/'mobile_exhibition_table/local_edits'/f'lods_{c}','web/assets/models/hi3d/table_'+c,'1') for c in ['150','135','125','120']]
jobs.append((base/'rest_sofa/local_edits/sofa_metric.glb',base/'rest_sofa/local_edits/lods','web/assets/models/hi3d/rest_sofa_metric','.86'))
for source,out,dest,h in jobs:
 run([BLENDER,'--background','--factory-startup','--python','pipeline/decimate_static.py','--',str(source),str(out)])
 if not (ROOT/out/'decimation_receipt.json').exists():raise RuntimeError('DCC processing did not produce its receipt')
 run(['node','pipeline/build_asset.mjs',str(out/'lod0_source.glb'),dest,h,'0','1024',str(out/'lod1_source.glb'),str(out/'lod2_source.glb')])
run(['node','pipeline/build_asset.mjs',str(base/'silver_covered_exhibit/original_0.glb'),'web/assets/models/hi3d/silver_covered_exhibit','.54','0','1024'])
p=ROOT/'web/assets/generated_furniture_catalog.json';c=json.loads(p.read_text());m=json.loads((ROOT/'web/assets/models/hi3d/silver_covered_exhibit/manifest.json').read_text());x,y,z=m['levels'][0]['size'];c['slots']['silver_exhibit']['uniformScale']=min(.88/x,.54/z,.54/y);p.write_text(json.dumps(c,ensure_ascii=False,indent=2)+'\n')
print('Local derivatives rebuilt. Run acceptance scripts before accepting changes.')
