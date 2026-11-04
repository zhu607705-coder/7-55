"""Rebuild only3F exhibition/pantry furniture; retain architectural scene geometry."""
import ast,bpy,json,math,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'flc_walkthrough.blend'))
scene=bpy.context.scene;floor=bpy.data.objects['Floor 3']
meta=json.loads((ROOT/'web/assets/layout.json').read_text())
rooms=[r for r in meta['floors']['3']['rooms'] if r['id'] in ['seminar','pantry']]
def inside(x,z):return any(r['bounds'][0]<x<r['bounds'][2] and r['bounds'][1]<z<r['bounds'][3] for r in rooms)
chair=next(o for o in floor.children if o.get('assetId')=='office_chair' and not inside(o.location.x,-o.location.y))
removed=0
for ob in list(floor.children):
    if ob.get('kind') in ['wall','ceiling','floor','finish']:continue
    if ob.type=='MESH':p=sum((ob.matrix_local@Vector(c) for c in ob.bound_box),Vector())/8
    else:p=ob.location
    if inside(p.x,-p.y) or ob.name.startswith(('Public copier cabinet','Copier scanner')):
        for child in list(ob.children_recursive):bpy.data.objects.remove(child,do_unlink=True)
        bpy.data.objects.remove(ob,do_unlink=True);removed+=1
meta['floors']['3']['colliders']=[c for c in meta['floors']['3']['colliders'] if not (c.get('rect') and (inside((c['rect'][0]+c['rect'][2])/2,(c['rect'][1]+c['rect'][3])/2) or c['id']=='Public copier'))]
tree=ast.parse((ROOT/'scripts/build_scene.py').read_text())
definitions=ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef)],type_ignores=[])
env={'bpy':bpy,'math':math,'json':json,'hashlib':hashlib,'Path':Path,'Vector':Vector,'ROOT':ROOT,'WEB':ROOT/'web','scene':scene,'parent':floor,'root_floor':floor,'current_floor':3,'meta':meta,'LIB':{'office_chair':chair}}
for key,name in {'white':'Plaster','gray':'Terrazzo gray','wood':'Oak','paper':'Warm desk','metal':'Steel','black':'Charcoal','glass':'Window glass','leaf':'Foliage','blue':'Blue reference','rubber':'Dark rubber','red':'Tool handle','meshmat':'Chair mesh','smoke':'Smoked equipment glass'}.items():env[key]=bpy.data.materials[name]
exec(compile(definitions,str(ROOT/'scripts/build_scene.py'),'exec'),env)
for room in rooms:env['north_furnishings' if room['id']=='seminar' else 'pantry_areas'](room)
scene['exhibitionPantryRevision']='20261102: authored casters, ruled exhibit threads, cabinetry/stool bases, pantry sofa clearance and entry look direction. Hi3D meshes require confirmed quotes.'
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'flc_walkthrough.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'web/assets/building.glb'),export_format='GLB',export_extras=True,export_yup=True)
(ROOT/'web/assets/layout.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2))
p=ROOT/'build_validation.json';data=json.loads(p.read_text());meshes=[o for o in scene.objects if o.type=='MESH']
data.update(meshes=len(meshes),shared_meshes=len({o.data.name for o in meshes}),glb_sha256=hashlib.sha256((ROOT/'web/assets/building.glb').read_bytes()).hexdigest(),exhibition_pantry_revision='20261102')
p.write_text(json.dumps(data,indent=2))
print('EXHIBITION_PANTRY_REBUILT',removed,'direct objects replaced;',len(meshes),'total meshes')
