"""Reproduce CPU sample-count comparison without changing any authored asset.
blender -b --factory-startup -t 4 --python scripts/render_prop_comparison.py
Same geometry, glass, lights, camera, exposure, seed; 64 vs 512 samples.
No denoising or image retouch. PNGs are Blender CPU output, not web captures.
"""
import sys, json, hashlib
from pathlib import Path
import bpy
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_lab_tools as build
root=build.ROOT/'review/prop_refinement';root.mkdir(parents=True,exist_ok=True)
records=[]
for asset in ['printer_enclosure_study','laser_enclosure_study']:
 for count in [64,512]:
  folder=root/str(count);folder.mkdir(exist_ok=True)
  source=build.OUT/asset/(asset+'.blend')
  bpy.ops.wm.open_mainfile(filepath=str(source))
  build.render(asset,samples=count,output_dir=folder,seed=0)
  image=folder/(asset+'.png')
  records.append({'asset':asset,'samples':count,'adaptiveSampling':bpy.context.scene.cycles.use_adaptive_sampling,'adaptiveThreshold':bpy.context.scene.cycles.adaptive_threshold,'seed':0,'denoising':False,'engine':'Cycles CPU','blender':bpy.app.version_string,'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'image':str(image.relative_to(build.ROOT)),'sha256':hashlib.sha256(image.read_bytes()).hexdigest()})
(root/'render_comparison.json').write_text(json.dumps({'scope':'Sampling-only comparison; geometry and PBR unchanged; not a browser capture','records':records},indent=2)+'\n')
