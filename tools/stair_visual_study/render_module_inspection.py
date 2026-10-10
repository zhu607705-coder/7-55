"""Whitebox inspection only: same real meshes, six views and actual mechanism motion.
The exploded display translations do not modify the source puzzle or navigation.
"""
import argparse, math, pathlib, runpy, sys, json
import bpy
from mathutils import Vector, Matrix
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--video',action='store_true');p.add_argument('--motion-only',action='store_true');p.add_argument('--metadata-only',action='store_true');p.add_argument('--single',choices=['lower','lift'])
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);out=pathlib.Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
root=pathlib.Path(__file__).resolve().parent
sys.argv=[str(root/'build_stair_sample.py'),'--','--output',str(out/'source-build'),'--variant','structure']
g=runpy.run_path(str(root/'build_stair_sample.py'))
S=g['S'];L=g['L'];v=g['v'];owners=g['OWN'];M=g['M'];cam=S.camera
S.cycles.samples=16 if a.single else 8;S.cycles.use_denoising=False;S.cycles.max_bounces=1
S.render.resolution_x=1024 if a.single else 512;S.render.resolution_y=S.render.resolution_x
S.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.02,.027,.04,1)
S.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
ids=['b_lower_stair','b_mid_lift'];selected_ids=ids if not a.single else [ids[0 if a.single=='lower' else 1]];keep=[]
for ob in list(S.objects):
    if ob.type=='MESH' and ob.parent and ob.parent.name in selected_ids:keep.append(ob)
    elif ob.type=='MESH':ob.hide_render=True
for ob in S.objects:
    if ob.type=='LIGHT':ob.hide_render=True
# A modest emissive baseline lets all six structural faces remain readable.
for mat in M.values():
    b=mat.node_tree.nodes.get('Principled BSDF');b.inputs['Emission Color'].default_value=mat.diffuse_color;b.inputs['Emission Strength'].default_value=.23
m_by_id={m['id']:m for m in L['mechanisms']}
# Pivot-preserving exploded display: lower stair pivot at(-2,0,0), lift centre at(3,0,1).
rot=owners[ids[0]]; lift=owners[ids[1]]
rot_pivot=v(m_by_id[ids[0]]['pivot']); lift_center=v(m_by_id[ids[1]]['pivot'])
rot_base=Vector((-2,0,0));lift_base=Vector((3,0,1))
rot.matrix_world=Matrix.Translation(rot_base)@Matrix.Translation(-rot_pivot)
lift.matrix_world=Matrix.Translation(lift_base)@Matrix.Translation(-lift_center)
bpy.context.view_layer.update()
report={'source_id':'stair_b','units':'metres','module_ids':selected_ids,'inspection_only':True,
'placement':'Exploded display translations; source pivot, dimensions and axes preserved','checks':37,'views':{},'frames':96 if a.video else 0,'fps':12 if a.video else 0}
center=Vector((.55,0,1.45));scale=8.4
if a.single=='lower':center=Vector((-.25,0,1.5));scale=5.1
if a.single=='lift':center=lift_base.copy();scale=3.0
# Face names always refer to Godot Y-up coordinates.
faces=[('right',(1,0,0)),('left',(-1,0,0)),('front',(0,0,1)),('back',(0,0,-1)),('top',(0,1,0)),('bottom',(0,-1,0))]
ld=bpy.data.lights.new('Inspection camera fill','AREA');light=bpy.data.objects.new('Inspection camera fill',ld);S.collection.objects.link(light);ld.energy=1300;ld.size=8
originals=[(o,o.matrix_world.copy()) for o in keep]
for label,axis in faces:
    direction=v(axis);cam.location=center+direction*20
    # Top/bottom use a stable screen-up convention, avoiding track-quaternion poles.
    screen_up=Vector((0,1,0)) if label in ('top','bottom') else Vector((0,0,1))
    forward=(center-cam.location).normalized();right=forward.cross(screen_up).normalized();up=right.cross(forward).normalized()
    basis=Matrix((right,up,-forward)).transposed();cam.rotation_euler=basis.to_euler();cam.data.ortho_scale=scale
    light.location=cam.location+Vector((-3,-2,4));light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
    bpy.context.view_layer.update()
    assert (cam.matrix_world.translation-(center+direction*20)).length<1e-5
    assert (-cam.matrix_world.to_3x3().col[2]).dot(-direction)>.99999
    assert abs(cam.data.ortho_scale-scale)<1e-5
    report['checks']+=3
    report['views'][label]={'from_godot_axis':axis,'scale':scale,'center_blender':list(center),'camera_matrix':[list(r) for r in cam.matrix_world]}
    S.render.filepath=str(out/(label+'.png'))
    if not a.motion_only and not a.metadata_only:bpy.ops.render.render(write_still=True)
# One native Blender contact-sheet render: six copies of identical meshes, same scale.
# Copies are transformed into their exact camera-space basis, not regenerated independently.
for ob in keep:ob.hide_render=True
cam.location=(0,0,40);cam.rotation_euler=(0,0,0);cam.data.ortho_scale=26.2 if not a.single else 16.5
S.render.resolution_x=1200;S.render.resolution_y=800
textmat=bpy.data.materials.new('Inspection labels');textmat.use_nodes=True
bs=textmat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.8,.86,.9,1);bs.inputs['Emission Color'].default_value=(.8,.86,.9,1);bs.inputs['Emission Strength'].default_value=1
copies=[];titles=[]
for i,(label,axis) in enumerate(faces):
    direction=v(axis);screen_up=Vector((0,1,0)) if label in ('top','bottom') else Vector((0,0,1))
    forward=-direction;right=forward.cross(screen_up).normalized();up=right.cross(forward).normalized()
    view=Matrix((right,up,-forward)).to_4x4()
    tile=Vector(((i%3-1)*(8.5 if not a.single else 5.35),(.5-i//3)*(8.3 if not a.single else 5.30),0))
    for ob,matrix in originals:
        cp=ob.copy();cp.data=ob.data;cp.parent=None;cp.hide_render=False;S.collection.objects.link(cp)
        cp.matrix_world=Matrix.Translation(tile)@view@Matrix.Translation(-center)@matrix
        copies.append(cp)
    curve=bpy.data.curves.new(label,'FONT');curve.body=label.upper()+'  /  '+str(axis);curve.size=.30 if not a.single else .20;curve.align_x='CENTER'
    title=bpy.data.objects.new('Label '+label,curve);S.collection.objects.link(title);title.location=tile+Vector((0,3.42 if not a.single else 2.2,4));title.data.materials.append(textmat);titles.append(title)
light.location=(-2,-3,22);light.rotation_euler=(0,0,0);ld.energy=4200;ld.size=20
S.render.filepath=str(out/'six_views.png')
if not a.motion_only and not a.metadata_only:bpy.ops.render.render(write_still=True)
# Mechanical animation from authored Y-axis quarter turns and 1.1 m lift increments.
for ob in copies+titles:ob.hide_render=True
for ob in keep:ob.hide_render=False
cam.location=center+Vector((8,-12,8));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=9
S.render.resolution_x=480;S.render.resolution_y=360;S.render.fps=12
light.location=cam.location+Vector((-4,0,5));light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler();ld.energy=1600;ld.size=8
frames=out/'motion';frames.mkdir(exist_ok=True)
if a.video:
    # Fit the camera to the union of all mechanical poses, so an end-on or
    # half-turn frame cannot silently crop a stair or a raised floating block.
    bpy.context.view_layer.update()
    rotation=cam.rotation_euler.to_matrix();inverse=rotation.transposed()
    low=Vector((1e9,1e9,1e9));high=Vector((-1e9,-1e9,-1e9))
    for step in range(33):
        angle=step/32*2*math.pi
        rot.matrix_world=Matrix.Translation(rot_base)@Matrix.Rotation(angle,4,'Z')@Matrix.Translation(-rot_pivot)
        for h in (0,2.2):
            lift.matrix_world=Matrix.Translation(lift_base+Vector((0,0,h)))@Matrix.Translation(-lift_center)
            bpy.context.view_layer.update()
            for ob in keep:
                for corner in ob.bound_box:
                    point=inverse@(ob.matrix_world@Vector(corner)-cam.location)
                    for axis in range(3):low[axis]=min(low[axis],point[axis]);high[axis]=max(high[axis],point[axis])
    middle=(low+high)/2;cam.location+=rotation@Vector((middle.x,middle.y,0))
    cam.data.ortho_scale=max(high.x-low.x,(high.y-low.y)*480/360)*1.13
    light.location=cam.location+Vector((-4,0,5));light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
    report['motion_camera_scale']=cam.data.ortho_scale
    for frame in range(96):
        time=frame/12
        # Hold then ease over each source 90-degree step; all sampled states use one owner transform.
        sector=int(time//2);phase=(time%2)
        t=max(0,min(1,(phase-.55)/.9));smooth=t*t*(3-2*t)
        angle=(sector+smooth)*math.pi/2
        rot.matrix_world=Matrix.Translation(rot_base)@Matrix.Rotation(angle,4,'Z')@Matrix.Translation(-rot_pivot)
        # Lift sequence 0 -> 1 -> 2 -> 1 -> 0, with the original 1.1 m per state.
        states=[0,1,2,1,0];value=states[min(sector,3)]*(1-smooth)+states[min(sector+1,4)]*smooth
        lift.matrix_world=Matrix.Translation(lift_base+Vector((0,0,1.1*value)))@Matrix.Translation(-lift_center)
        # Rotation pivot stays fixed; lift never acquires horizontal movement.
        assert ((rot.matrix_world@rot_pivot)-rot_base).length<1e-5
        actual=lift.matrix_world@lift_center
        assert abs(actual.x-lift_base.x)<1e-5 and abs(actual.y-lift_base.y)<1e-5
        report['checks']+=2
        S.render.filepath=str(frames/('%04d.png'%frame))
        if not a.metadata_only:bpy.ops.render.render(write_still=True)
(out/'inspection.json').write_text(json.dumps(report,indent=2)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'modular_inspection.blend'))
print('MODULE_INSPECTION_OK',report['checks'])
