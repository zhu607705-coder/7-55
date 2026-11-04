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
chair=next(o for o in bpy.data.objects if o.get('assetId')=='office_chair')
pts=[ob.matrix_world@Vector(corner) for ob in chair.children_recursive if ob.type=='MESH' for corner in ob.bound_box]
spans=[max(p[i] for p in pts)-min(p[i] for p in pts) for i in range(3)]
check(spans[0]<=.72 and spans[1]<=.72 and 1.19<=spans[2]<=1.42,'ergonomic chair keeps real product-scale footprint and headrest height',spans)
back=next(o for o in chair.children_recursive if o.name.startswith('Ergonomic breathable back') and o.type=='MESH')
area=sum(p.area for p in back.data.polygons)
check(.04<area<.15,'breathable back has actual open cells rather than an opaque slab',area)
check(sum(o.name.startswith('Twin caster wheel') for o in chair.children_recursive)==10,'five-star base has ten horizontal-axis caster wheels')
for feature in ['Headrest mesh','Lumbar support wing','Adjustable arm pad','Synchro tilt mechanism']:
 check(any(o.name.startswith(feature) for o in chair.children_recursive),'exported ergonomic chair includes '+feature)
desk=next(o for o in bpy.data.objects if o.get('assetId')=='office_desk')
check(desk.get('adjustableDesk') is True,'GLB preserves shared adjustable-desk root contract')
check(any(o.get('liftFactor')==.5 for o in desk.children_recursive) and any(o.get('liftFactor')==1 for o in desk.children_recursive),'GLB preserves telescoping-stage motion factors')
check(any(o.get('deskRole')=='control' for o in desk.children_recursive),'GLB preserves physical keypad target')
hall=bpy.data.objects['Floor 3']
high=[o for o in hall.children_recursive if o.type=='MESH' and o.name.startswith('North hall ceiling')]
check(bool(high),'north discussion area has a separate high ceiling')
if high:
 z=min((high[0].matrix_world@Vector(c)).z for c in high[0].bound_box)
 check(abs(z-(4.05+6.2))<.01,'photo-based double-height ceiling exports in real meters',z)
report={'checks' :len(rows),'failures':sum(not r['pass'] for r in rows),'rows':rows}
(ROOT/'review/model_validation.json').write_text(json.dumps(report,indent=2));print('MODEL_VALIDATION',json.dumps(report))
if report['failures']:raise SystemExit(1)
