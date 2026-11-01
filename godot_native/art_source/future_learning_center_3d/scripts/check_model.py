import bpy,json,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'flc_walkthrough.blend'))
rows=[]
def check(ok,label,details=None):
 rows.append({'pass':bool(ok),'label':label,'details':details})
 if not ok:print('MODEL_CHECK_FAILED',label,details)
def check_holes(stage):
 for f in [2,3,4]:
  root=bpy.data.objects.get('Floor '+str(f));check(root is not None,f'{stage} {f}F hierarchy')
  for ob in root.children:
   if ob.type=='MESH' and ob.get('kind')=='floor':
    vs=[ob.matrix_world@v.co for v in ob.data.vertices];faces=[tuple(p.vertices) for p in ob.data.polygons];tree=BVHTree.FromPolygons(vs,faces)
    hit=tree.ray_cast(Vector((13,-20,50)),Vector((0,0,-1)))[0]
    check((hit is not None)==(f==2),f'{stage} {f}F physical atrium hole',list(hit) if hit else None)
check_holes('blend')
# Inspect actual exported geometry after glTF axis/unit conversion.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'web/assets/building.glb'))
check_holes('glb')
for asset,expected in [('office_desk',1.4),('caliper_150',.233),('screwdriver_3x100',.204)]:
 roots=[o for o in bpy.data.objects if o.get('assetId')==asset]
 check(bool(roots),asset+' reusable instances',len(roots))
 for root in roots[:1]:
  pts=[ob.matrix_world@Vector(corner) for ob in root.children_recursive if ob.type=='MESH' for corner in ob.bound_box]
  spans=[max(p[i] for p in pts)-min(p[i] for p in pts) for i in range(3)]
  check(abs(max(spans)-expected)<.01,asset+' exported meter scale',spans)
for asset,expected in [('printer_h2c',[.492,.514,.626]),('laser_p2s',[1.0,.639,.268])]:
 roots=[o for o in bpy.data.objects if o.get('assetId')==asset]
 check(bool(roots),asset+' exported instances',len(roots))
 for root in roots:
  pts=[ob.matrix_world@Vector(corner) for ob in root.children_recursive if ob.type=='MESH' for corner in ob.bound_box]
  spans=[max(p[i] for p in pts)-min(p[i] for p in pts) for i in range(3)]
  check(all(abs(a-b)<.001 for a,b in zip(spans,expected)),asset+' three-axis envelope matches manufacturer millimeters',spans)
f4=bpy.data.objects['Floor 4']
check(sum(o.name.startswith('Personal locker door') for o in f4.children_recursive)==80,'80 personal locker doors exist in exported geometry')
check(sum(o.name.startswith('Movable polygon table module') for o in f4.children_recursive)==6,'co-creation table has six independently authored modules')
report={'checks' :len(rows),'failures':sum(not r['pass'] for r in rows),'rows':rows}
(ROOT/'review/model_validation.json').write_text(json.dumps(report,indent=2));print('MODEL_VALIDATION',json.dumps(report))
if report['failures']:raise SystemExit(1)
