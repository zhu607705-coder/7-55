"""Render the revised microwave and adjacent pantry using existing GLB asset IDs.
No combined mesh, GLB, or Blender assembly is exported.
Run: blender -b --factory-startup -t 4 --python scripts/build_photo_pantry_composition.py
Before comparison (optional): append -- --before-glb=/path/to/previous/lod0_source.glb
Select one image (optional): append -- --only=photo_pantry_combined_revision
"""
import bpy,json,sys,hashlib,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];REVIEW=ROOT/'review/photo_living';LAYOUT=ROOT/'sources/photo_pantry_composition.json'
layout=json.loads(LAYOUT.read_text());report={}
def arg(prefix):return next((a.split('=',1)[1] for a in sys.argv if a.startswith(prefix+'=')),None)
def material(name,c,rough=.8):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=rough;return m
def load_asset(path,delta=(0,0,0),asset=None):
 before=set(bpy.context.scene.objects);bpy.ops.import_scene.gltf(filepath=str(path));new=set(bpy.context.scene.objects)-before
 # Imported hierarchy is transformed once at each root, preserving local child geometry.
 for o in new:
  if o.parent not in new:o.location+=Vector(delta)
  if asset:o['instance_asset_id']=asset
 return new
def world_bounds():
 bpy.context.view_layer.update();vs=[o.matrix_world@v.co for o in bpy.context.scene.objects if o.type=='MESH' for v in o.data.vertices]
 return [[min(v[i] for v in vs) for i in range(3)],[max(v[i] for v in vs) for i in range(3)]]
def render(name,kind,before=None):
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.unit_settings.system='METRIC'
 if kind=='unit':
  source=Path(before) if before else ROOT/'sources/models/photo_living/photo_pantry_grey_roundfront_appliance/lod0_source.glb';load_asset(source)
 else:
  for inst in layout['instances']:
   if kind=='counter' and inst['group']!='counter':continue
   load_asset(ROOT/inst['source'],inst['translationBlenderXYZ'],inst['asset'])
 bb=world_bounds()
 # Keep before/after camera, lighting, exposure and stage exactly identical.
 if kind=='unit':target=Vector((0,0,.19));loc=Vector((.75,-1.1,.64));lens=60;res=(1000,850);ortho=.75
 elif kind=='counter':target=Vector((0,0,1.18));loc=Vector((2.48,-3.13,2.30));lens=47;res=(1400,1000);ortho=None
 else:target=Vector((-.80,0,1.30));loc=Vector((3.3,-6.5,3.1));lens=50;res=(1900,1150);ortho=None
 bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.003));stage=bpy.context.object;stage.name='Render-only neutral floor';stage.data.materials.append(material('Render-only neutral stage',(.35,.36,.34)))
 bpy.ops.object.camera_add(location=loc);cam=bpy.context.object;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens
 if ortho:cam.data.type='ORTHO';cam.data.ortho_scale=ortho
 bpy.context.scene.camera=cam
 if kind=='unit':lights=[((-1.2,-1.2,2.0),140,1.6),((1.4,-.6,1.2),90,1.2),((0,1.2,1.4),100,1.3)]
 else:lights=[((-2.8,-2,4.8),900,4),((2,-2,3.2),550,3),((0,1.7,4),500,2)]
 for pos,power,size in lights:
  bpy.ops.object.light_add(type='AREA',location=pos);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
 sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Neutral daylight');sc.world.color=(.26,.26,.26);sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=64;sc.cycles.use_denoising=False;sc.render.resolution_x,sc.render.resolution_y=res;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.look='AgX - Medium High Contrast';sc.view_settings.exposure=-1.0;sc.render.image_settings.file_format='PNG';path=REVIEW/(name+'.png');sc.render.filepath=str(path);bpy.ops.render.render(write_still=True)
 report[name]={'file':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'resolution':list(res),'boundsBlenderXYZ':bb,'cameraLocation':list(loc),'cameraTarget':list(target),'cameraLens':lens,'orthoScale':ortho,'render':'Cycles CPU 64 samples','geometrySource':'existing independent GLB assets','visualInspection':'pending'}
 if kind=='unit':report[name]['assetSha256']=hashlib.sha256(source.read_bytes()).hexdigest()
 old=json.loads((REVIEW/'pantry_composition_render_report.json').read_text()) if (REVIEW/'pantry_composition_render_report.json').exists() else {'views':{}}
 old['views'].update(report);old['layout']='sources/photo_pantry_composition.json';old['newCombined3DAssets']=0;old['browserTested']=False;old['runtimeIntegrated']=False;(REVIEW/'pantry_composition_render_report.json').write_text(json.dumps(old,indent=2))
only=arg('--only');before=arg('--before-glb')
views=[]
if before:views.append(('photo_microwave_before_same_camera','unit',before))
views += [('photo_microwave_after_same_camera','unit',None),('photo_pantry_counter_near_final','counter',None),('photo_pantry_combined_revision','combined',None)]
for name,kind,path in views:
 if only and only!=name:continue
 render(name,kind,path)
print('Composition renders finished; no combined 3D assets exported')
