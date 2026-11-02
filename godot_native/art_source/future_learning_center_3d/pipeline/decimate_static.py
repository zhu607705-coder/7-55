"""Bake true polygon LODs after DCC edits, including meshes split by UV seams.
Blender --background --factory-startup --python pipeline/decimate_static.py -- INPUT OUTPUT_DIR
"""
import bpy,sys,json,hashlib
from pathlib import Path
args=sys.argv[sys.argv.index('--')+1:];source=Path(args[0]).resolve();out=Path(args[1]);out.mkdir(parents=True,exist_ok=True)
receipt={'source':str(source.name),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'tool':'Blender '+bpy.app.version_string,'method':'Decimate collapse, UV data preserved; visual acceptance required','levels':[]}
for level,target in enumerate([20000,8000,2000]):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);bpy.ops.import_scene.gltf(filepath=str(source))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];count=sum(sum(max(0,len(p.vertices)-2) for p in o.data.polygons) for o in meshes);ratio=min(1,target/count)
 for ob in meshes:
  bpy.context.view_layer.objects.active=ob
  if ratio<1:
   mod=ob.modifiers.new('Measured polygon LOD','DECIMATE');mod.ratio=ratio;mod.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 bpy.ops.object.select_all(action='SELECT');dest=out/f'lod{level}_source.glb';bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',export_yup=True)
 triangles=sum(sum(max(0,len(p.vertices)-2) for p in o.data.polygons) for o in meshes)
 receipt['levels'].append({'level':level,'target':target,'triangles':triangles,'file':dest.name,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
(out/'decimation_receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
