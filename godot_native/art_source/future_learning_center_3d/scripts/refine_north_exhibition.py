"""Incremental rebuild of the photographed north furnishings from shared source functions."""
import ast,bpy,json,math,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'flc_walkthrough.blend'))
scene=bpy.context.scene;floor=bpy.data.objects['Floor 3'];meta=json.loads((ROOT/'web/assets/layout.json').read_text());room=next(r for r in meta['floors']['3']['rooms'] if r['id']=='seminar');x0,z0,x1,z1=room['bounds']
def in_room(x,z):return x0<x<x1 and z0<z<z1
before={'bounds':room['bounds'],'colliders':[c for c in meta['floors']['3']['colliders'] if c.get('rect') and in_room((c['rect'][0]+c['rect'][2])/2,(c['rect'][1]+c['rect'][3])/2)]}
baseline=ROOT/'review/north_density_before_layout.json'
if not baseline.exists():baseline.write_text(json.dumps(before,indent=2))
removed=0
for ob in list(floor.children):
 if ob.type!='MESH' or ob.get('kind') in ['wall','ceiling','floor','finish']:continue
 p=sum((ob.matrix_local@Vector(c) for c in ob.bound_box),Vector())/8
 if in_room(p.x,-p.y) or ob.name.startswith(('Public copier cabinet','Copier scanner')):
  bpy.data.objects.remove(ob,do_unlink=True);removed+=1
kept=[]
for c in meta['floors']['3']['colliders']:
 r=c.get('rect')
 if r and (in_room((r[0]+r[2])/2,(r[1]+r[3])/2) or c['id']=='Public copier'):continue
 kept.append(c)
meta['floors']['3']['colliders']=kept
# Compile only local function definitions; no top-level scene deletion or full build executes.
source=ast.parse((ROOT/'scripts/build_scene.py').read_text());definitions=ast.Module(body=[n for n in source.body if isinstance(n,ast.FunctionDef)],type_ignores=[])
env={'bpy':bpy,'math':math,'json':json,'hashlib':hashlib,'Path':Path,'Vector':Vector,'ROOT':ROOT,'WEB':ROOT/'web','scene':scene,'parent':floor,'root_floor':floor,'current_floor':3,'meta':meta}
for key,name in {'white':'Plaster','gray':'Terrazzo gray','wood':'Oak','paper':'Warm desk','metal':'Steel','black':'Charcoal','glass':'Window glass','leaf':'Foliage','blue':'Blue reference','rubber':'Dark rubber','red':'Tool handle'}.items():env[key]=bpy.data.materials[name]
exec(compile(definitions,str(ROOT/'scripts/build_scene.py'),'exec'),env)
env['north_furnishings'](room)
scene['northDensityRevision']='Photographed fourth stand, two stools, covered silver form and grouped tabletop objects; plan and real-size furniture retained.'
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'flc_walkthrough.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'web/assets/building.glb'),export_format='GLB',export_extras=True,export_yup=True)
(ROOT/'web/assets/layout.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2))
p=ROOT/'build_validation.json';report=json.loads(p.read_text());meshes=[o for o in scene.objects if o.type=='MESH'];report.update({'meshes':len(meshes),'shared_meshes':len({o.data.name for o in meshes}),'glb_sha256':hashlib.sha256((ROOT/'web/assets/building.glb').read_bytes()).hexdigest(),'north_density_revision':'photo_density_20261101'});p.write_text(json.dumps(report,indent=2))
print('NORTH_FURNISHINGS_REBUILT',removed,'old meshes removed;',len(meshes),'total meshes')
