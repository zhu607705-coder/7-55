"""Blender 4.3: source-preserving stair_b architectural study (not gameplay).
Run: blender -b --factory-startup -t 1 --python this.py -- --output DIR
Godot coordinates -> Blender: (x, -z, y). Mechanism transform stays on owner.
No external packages, downloads, new navigation edges, or collision changes.
"""
import argparse, json, math, pathlib, sys, hashlib
import bpy
from mathutils import Vector, Matrix

P = argparse.ArgumentParser()
P.add_argument('--output', required=True)
P.add_argument('--variant', choices=['source', 'structure'], default='structure')
P.add_argument('--render', action='store_true')
A = P.parse_args(sys.argv[sys.argv.index('--') + 1:])
ROOT = pathlib.Path(__file__).resolve().parent
D = json.loads((ROOT / 'stair_b_snapshot.json').read_text())
L, C = D['level'], D['camera']
OUT = pathlib.Path(A.output).resolve(); OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
S = bpy.context.scene
S.render.engine='CYCLES'; S.cycles.device='CPU'; S.cycles.samples=32; S.cycles.use_denoising=False
S.render.threads_mode='FIXED'; S.render.threads=1
S.render.resolution_x=640; S.render.resolution_y=360; S.render.resolution_percentage=100
S.render.image_settings.file_format='PNG'; S.render.film_transparent=False
S.view_settings.view_transform='Standard'; S.view_settings.look='Medium High Contrast'
S.view_settings.exposure=0; S.view_settings.gamma=1
S.world.use_nodes=True; S.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.065,.081,.105,1)
S.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.4


def v(p): return Vector((p[0], -p[2], p[1]))
def material(name, rgb):
    m=bpy.data.materials.new(name); m.diffuse_color=(*rgb,1); m.use_nodes=True
    node=m.node_tree.nodes.get('Principled BSDF'); node.inputs['Base Color'].default_value=(*rgb,1)
    node.inputs['Roughness'].default_value=.93
    return m

M={
 'stone_lit':material('Unapproved stone placeholder',(.42,.48,.49)),
 'stone_back':material('Unapproved side stone placeholder',(.29,.35,.37)),
 'wall_lit':material('Unapproved plaster placeholder',(.49,.53,.52)),
 'structure':material('Unapproved iron placeholder',(.085,.12,.13)),
 'outline':material('Edge dark',(.055,.08,.095)),
 'door':material('School door placeholder',(.21,.16,.12)),
 'glass':material('Night window placeholder',(.055,.14,.20)),
 'nosing':material('Step nosing placeholder',(.63,.66,.63)),
}
OWN={}
for key in ['level']+[m['id'] for m in L['mechanisms']]:
    o=bpy.data.objects.new(key,None); S.collection.objects.link(o); OWN[key]=o
    o['source_owner_id']=key; o['gameplay_collision']='not_generated'

REPORT={'variant':A.variant,'source_sha256':D['source_sha256'], 'level_id':L['id'],
        'camera_source':C, 'coordinate_map':'Godot (x,y,z) -> Blender (x,-z,y)',
        'navigation_modified':False, 'collision_generated':False,
        'appearance_approved':False, 'platforms':[], 'stairs':[], 'owners':{}}


def box(name, center, size, mat, owner='level', rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=v(center))
    o=bpy.context.object; o.name=name; o.dimensions=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rotation is not None: o.rotation_euler[2]=rotation
    o.data.materials.append(M[mat]); o.parent=OWN[owner]
    o['source_owner_id']=owner; o['render_only']=True
    return o


def beam(name,a,b,thickness,depth,mat,owner):
    a,b=v(a),v(b); midpoint=(a+b)/2
    bpy.ops.mesh.primitive_cube_add(size=1,location=midpoint)
    o=bpy.context.object; o.name=name; o.dimensions=((b-a).length,thickness,depth)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.rotation_mode='QUATERNION'; o.rotation_quaternion=(b-a).to_track_quat('X','Z')
    o.data.materials.append(M[mat]); o.parent=OWN[owner]; o['render_only']=True
    return o


for p in L['geometry']['platforms']:
    box(p['id'],p['center'],p['size'],p['material'],p['ownerId'])
    REPORT['platforms'].append({k:p[k] for k in ('id','ownerId','center','size','walkable')})
    if A.variant=='structure' and p['walkable']:
        c=Vector(p['center']); sz=Vector(p['size'])
        # Render-only fascia entirely below the source top plane.
        box(p['id']+'_fascia',c-Vector((0,.105,0)),(sz.x+.025,.1,sz.z+.025),'stone_back',p['ownerId'])
        # Stone blocks form a supported slab underside, never extend a walkable edge.
        for edge in (-1,1):
            box(p['id']+'_recess_'+str(edge),c+Vector((0,-.09,edge*(sz.z/2+.006))),
                (sz.x-.08,.035,.016),'outline',p['ownerId'])

for stair in L['geometry']['stairs']:
    a,b=Vector(stair['from']),Vector(stair['to']); run=b-a
    horizontal=Vector((run.x,0,run.z)); length=horizontal.length
    n=stair['steps']; width=stair['width']; owner=stair['ownerId']
    sideways=Vector((-run.z,0,run.x)).normalized()
    rot=-math.atan2(run.z,run.x)
    heights=[]
    for i in range(n):
        t=(i+.5)/n; top=a.lerp(b,t); heights.append(top.y)
        box(stair['id']+'_tread_%02d'%i,top-Vector((0,.13,0)),
            (length/n+.07,.26,width),'stone_lit',owner,rot)
        front=top+horizontal.normalized()*(length/n/2-.03)+Vector((0,.012,0))
        box(stair['id']+'_nosing_%02d'%i,front,(.055,.025,width-.08),'nosing',owner,rot)
    for side in (-1,1):
        off=sideways*side*(width/2-.04)
        beam(stair['id']+'_stringer_'+str(side),a+off-Vector((0,.24,0)),b+off-Vector((0,.24,0)),
             .09,.14 if A.variant=='source' else .24,'structure',owner)
        fractions=[.12,.37,.62,.87] if A.variant=='source' else [i/n for i in range(0,n+1,2)]+[1.0]
        for j,t in enumerate(sorted(set(fractions))):
            # Bases touch the same actual tread height. No hovering post feet.
            index=min(n-1,max(0,int(t*n))); y=heights[index]
            ground=a.lerp(b,t)+off; ground.y=y
            height=a.lerp(b,t).y+.76-ground.y
            box(stair['id']+'_post_%d_%02d'%(side,j),ground+Vector((0,height/2,0)),(.05,height,.05),'structure',owner)
        f0,f1=(.105,.885) if A.variant=='source' else (0,1)
        beam(stair['id']+'_handrail_'+str(side),a.lerp(b,f0)+off+Vector((0,.72,0)),
             a.lerp(b,f1)+off+Vector((0,.72,0)),.065,.065,'structure',owner)
        if A.variant=='structure':
            beam(stair['id']+'_lower_guard_'+str(side),a+off+Vector((0,.30,0)),b+off+Vector((0,.30,0)),.03,.035,'structure',owner)
    REPORT['stairs'].append({'id':stair['id'],'ownerId':owner,'from':list(a),'to':list(b),
        'steps':n,'source_width':width,'tread_top_heights':heights,'continuous_rail':A.variant=='structure'})

# Source-faithful school anchors, kept deliberately simple until the web concept review.
for d in L['geometry']['decorations']:
    p=Vector(d['position']); kind=d['kind']; name=d['id']
    if kind=='window_frame':
        box(name+'_frame',p+Vector((0,.65,0)),(1.4,1.6,.12),'structure')
        box(name+'_glass',p+Vector((0,.65,.07)),(1.19,1.37,.045),'glass')
        box(name+'_cross_v',p+Vector((0,.65,.105)),(.045,1.4,.045),'structure')
        box(name+'_cross_h',p+Vector((0,.65,.105)),(1.22,.045,.045),'structure')
    elif kind=='fire_door':
        # Original door is placed with a world rotation; group allows identical transfer.
        key=name+'_rig'; rig=bpy.data.objects.new(key,None); S.collection.objects.link(rig)
        rig.parent=OWN['level']; OWN[key]=rig
        for x in (-.73,.73): box(name+'_jamb_'+str(x),(x,1.15,0),(.18,2.3,.22),'structure',key)
        box(name+'_lintel',(0,2.3,0),(1.64,.18,.22),'structure',key)
        box(name+'_leaf',(0,1.12,.02),(1.28,2.2,.12),'door',key)
        rig.location=v(p); rig.rotation_euler[2]=float(d.get('rotationY',0))
    elif kind=='potted_plant':
        box(name+'_pot',p+Vector((0,.18,0)),(.4,.36,.4),'door')
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.34,location=v(p+Vector((0,.65,0))))
        o=bpy.context.object; o.name=name+'_foliage'; o.data.materials.append(M['stone_back']);o.parent=OWN['level']

for m in L['mechanisms']:
    o=OWN[m['id']]; state=m['initialState']
    if m['kind']=='rotate':
        pivot=v(m['pivot']); angle=state*math.pi/2
        R=Matrix.Rotation(angle,4,'Z'); o.matrix_world=Matrix.Translation(pivot)@R@Matrix.Translation(-pivot)
    else:
        offset=[0,0,0]; offset[{'x':0,'y':1,'z':2}[m['axis']]]=m['stepSize']*state
        o.location=v(offset)
    REPORT['owners'][m['id']]={'initial_state':state,'transform':[list(r) for r in o.matrix_world]}

cam_data=bpy.data.cameras.new('Source south_east orthographic'); cam=bpy.data.objects.new('Source camera',cam_data)
S.collection.objects.link(cam);cam.location=v(C['views']['south_east']['position'])
cam.rotation_euler=(v(C['center'])-cam.location).to_track_quat('-Z','Y').to_euler()
cam_data.type='ORTHO'
# Blender ortho_scale spans width when width > height. Godot Camera3D size spans height.
cam_data.ortho_scale=C['halfHeight']*2*S.render.resolution_x/S.render.resolution_y
cam_data.clip_start=C['near']; cam_data.clip_end=C['far']; S.camera=cam

sun_data=bpy.data.lights.new('Geometry reading key','AREA');sun=bpy.data.objects.new('Geometry reading key',sun_data)
S.collection.objects.link(sun);sun.location=(-5,-3,15);sun_data.energy=2100;sun_data.shape='DISK';sun_data.size=8
sun.rotation_euler=(v(C['center'])-sun.location).to_track_quat('-Z','Y').to_euler()
# Geometry and camera checks run on the actual Blender object transforms.
bpy.context.view_layer.update()
checks=0
for p in L['geometry']['platforms']:
    o=bpy.data.objects[p['id']]
    assert (o.location-v(p['center'])).length<1e-6
    assert abs(o.dimensions.z-p['size'][1])<1e-5
    checks+=2
for n in L['nodes']:
    point=Vector(n['position']); owner=n['ownerId']
    expected=point.copy()
    for m in L['mechanisms']:
        if m['id']!=owner: continue
        if m['kind']=='rotate':
            q=point-Vector(m['pivot']); angle=m['initialState']*math.pi/2
            expected=Vector(m['pivot'])+Vector((q.x*math.cos(angle)+q.z*math.sin(angle),q.y,-q.x*math.sin(angle)+q.z*math.cos(angle)))
        else: expected[{'x':0,'y':1,'z':2}[m['axis']]]+=m['stepSize']*m['initialState']
    actual=OWN[owner].matrix_world@v(point)
    assert (actual-v(expected)).length<2e-6, (n['id'],actual,expected)
    checks+=1
from bpy_extras.object_utils import world_to_camera_view
origin=Vector(C['views']['south_east']['position']); center=Vector(C['center'])
forward=(center-origin).normalized(); right=forward.cross(Vector((0,1,0))).normalized(); up=right.cross(forward).normalized()
for point in [Vector(n['position']) for n in L['nodes']]+[center]:
    rel=point-center; actual=world_to_camera_view(S,cam,v(point))
    expect_x=.5+rel.dot(right)/(C['halfHeight']*2*640/360)
    expect_y=.5+rel.dot(up)/(C['halfHeight']*2)
    assert abs(actual.x-expect_x)<1e-5 and abs(actual.y-expect_y)<1e-5, ('camera',actual,expect_x,expect_y)
    checks+=1
REPORT['checks_passed']=checks
REPORT['object_count']=len(S.objects); REPORT['render_resolution']=[640,360]
REPORT['status']='Unapproved architectural geometry study; no gameplay and no final materials'
(OUT/(A.variant+'-manifest.json')).write_text(json.dumps(REPORT,indent=2)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(A.variant+'.blend')))
S.render.filepath=str(OUT/(A.variant+'.png'))
if A.render: bpy.ops.render.render(write_still=True)
print('STAIR_SAMPLE_OK',A.variant,REPORT['object_count'])
